import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../utils/utils.dart';
import '../../widgets/form_fields/custom_text_field.dart';
import '../../widgets/buttons/custom_button.dart';
import '../../widgets/cards/section_card.dart';
import 'invoice_details.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final storage = const FlutterSecureStorage();
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _invoices = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _filterStatus = 'all'; // 'all', 'pending', 'paid', 'overdue'

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInvoices() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final token = await storage.read(key: "edams_jwt");

      if (token == null || token.isEmpty) {
        if (mounted) {
          _showSnackBar("Authentication required. Please login again.", false);
        }
        return;
      }

      final response = await http.get(
        Uri.parse('${getUrl()}invoices'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          List<Map<String, dynamic>> invoices = [];

          if (responseData['data'] is List) {
            invoices = List<Map<String, dynamic>>.from(responseData['data']);
          } else if (responseData['data'] is Map &&
              responseData['data']['data'] is List) {
            invoices =
                List<Map<String, dynamic>>.from(responseData['data']['data']);
          }

          if (mounted) {
            setState(() {
              _invoices = invoices;
            });
          }
        } else {
          if (mounted) {
            _showSnackBar(
                'Failed to load invoices: ${responseData['message'] ?? 'Unknown error'}',
                false);
          }
        }
      } else {
        final errorData = jsonDecode(response.body);
        if (mounted) {
          _showSnackBar(
              'Failed to load invoices: ${errorData['message'] ?? 'Server error'}',
              false);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error loading invoices: $e', false);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, bool isSuccess) {
    if (!mounted) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: isSuccess ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      // Widget is no longer in the tree, ignore the error
    }
  }

  List<Map<String, dynamic>> get _filteredInvoices {
    List<Map<String, dynamic>> filtered = _invoices;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((invoice) {
        final invoiceNumber =
            invoice['InvoiceNumber']?.toString().toLowerCase() ?? '';
        final applicationTitle =
            invoice['application']?['ProjectTitle']?.toString().toLowerCase() ??
                '';

        return invoiceNumber.contains(_searchQuery.toLowerCase()) ||
            applicationTitle.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    if (_filterStatus != 'all') {
      filtered = filtered.where((invoice) {
        final status = invoice['Status']?.toString().toLowerCase() ?? '';
        return status == _filterStatus.toLowerCase();
      }).toList();
    }

    return filtered;
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'paid':
        return Colors.green;
      case 'overdue':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'paid':
        return 'Paid';
      case 'overdue':
        return 'Overdue';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status ?? 'Unknown';
    }
  }

  double _parseAmount(dynamic amount) {
    if (amount == null) return 0.0;

    if (amount is num) {
      return amount.toDouble();
    }

    if (amount is String) {
      return double.tryParse(amount) ?? 0.0;
    }

    return 0.0;
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return GestureDetector(
      onTap: () {
        if (mounted) {
          setState(() {
            _filterStatus = value;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? getColor('primary') : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? getColor('primary') : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildPaymentSummary() {
    final pendingAmount = _invoices
        .where((invoice) =>
            invoice['Status']?.toString().toLowerCase() == 'pending')
        .fold<double>(
            0, (sum, invoice) => sum + _parseAmount(invoice['Amount']));

    final paidAmount = _invoices
        .where(
            (invoice) => invoice['Status']?.toString().toLowerCase() == 'paid')
        .fold<double>(
            0, (sum, invoice) => sum + _parseAmount(invoice['Amount']));

    final overdueAmount = _invoices
        .where((invoice) =>
            invoice['Status']?.toString().toLowerCase() == 'overdue')
        .fold<double>(
            0, (sum, invoice) => sum + _parseAmount(invoice['Amount']));

    return SectionCard(
      title: "Payment Summary",
      icon: Icons.account_balance_wallet,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildPaymentStat('Pending',
              'KES ${pendingAmount.toStringAsFixed(0)}', Colors.orange),
          _buildPaymentStat(
              'Paid', 'KES ${paidAmount.toStringAsFixed(0)}', Colors.green),
          _buildPaymentStat(
              'Overdue', 'KES ${overdueAmount.toStringAsFixed(0)}', Colors.red),
        ],
      ),
    );
  }

  Widget _buildPaymentStat(String label, String amount, Color color) {
    return Column(
      children: [
        Text(
          amount,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No invoices found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _filterStatus != 'all'
                ? 'Try adjusting your search or filters'
                : 'No invoices have been generated yet',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Refresh',
            onPressed: _loadInvoices,
            icon: const Icon(Icons.refresh, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(Map<String, dynamic> invoice) {
    final invoiceNumber = invoice['InvoiceNumber'] ?? 'N/A';
    final status = invoice['Status'];
    final statusText = _getStatusText(status);
    final statusColor = _getStatusColor(status);
    final amount = _parseAmount(invoice['Amount']);
    final dueDate = _formatDate(invoice['DueDate']);
    final applicationTitle =
        invoice['application']?['ProjectTitle'] ?? 'Unknown Application';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                        applicationTitle,
              style: const TextStyle(
                fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Invoice: $invoiceNumber',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
            Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                    statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'KES ${amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Due: $dueDate',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _navigateToInvoiceDetails(invoice);
                    },
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _handleInvoiceAction(invoice);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: getColor('primary'),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(_getActionButtonText(status)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getActionButtonText(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'Make Payment';
      case 'paid':
        return 'View Receipt';
      case 'overdue':
        return 'Pay Now';
      case 'cancelled':
        return 'View Details';
      default:
        return 'Take Action';
    }
  }

  void _handleInvoiceAction(Map<String, dynamic> invoice) {
    final status = invoice['Status']?.toString().toLowerCase();

    switch (status) {
      case 'pending':
      case 'overdue':
        _showSnackBar('Payment processing feature coming soon!', false);
        break;
      case 'paid':
        _showSnackBar('Receipt download feature coming soon!', false);
        break;
      case 'cancelled':
        _showSnackBar('This invoice has been cancelled.', false);
        break;
      default:
        _showSnackBar('Action feature coming soon!', false);
        break;
    }
  }

  Future<void> _navigateToInvoiceDetails(Map<String, dynamic> invoice) async {
    final invoiceId = invoice['ID']?.toString();

    if (invoiceId == null || invoiceId.isEmpty) {
      _showSnackBar('Invoice ID not found', false);
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceDetailsPage(
          invoiceId: invoiceId,
          initialInvoiceData: invoice,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Payments'),
        backgroundColor: getColor('primary'),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInvoices,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search & Filter Section
                SectionCard(
                  title: "Search & Filter",
                  icon: Icons.search,
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: _searchController,
                        label: "Search Invoices",
                        hint: "Search by invoice number or application title",
                        prefixIcon: const Icon(Icons.search),
                        onChanged: (value) {
                          if (mounted) {
                            setState(() {
                              _searchQuery = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      // Filter Buttons
                      Row(
                        children: [
                          Expanded(
                            child: _buildFilterChip('All', 'all'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildFilterChip('Pending', 'pending'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildFilterChip('Paid', 'paid'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildFilterChip('Overdue', 'overdue'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _filteredInvoices.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadInvoices,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Payment Summary
                                _buildPaymentSummary(),
                                const SizedBox(height: 24),

                                // Invoices List
                                const Text(
                                  'Your Invoices',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ..._filteredInvoices.map(
                                  (invoice) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildInvoiceCard(invoice),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showSnackBar('Payment processing feature coming soon!', false);
        },
        backgroundColor: getColor('primary'),
        child: const Icon(Icons.payment, color: Colors.white),
      ),
    );
  }
}
