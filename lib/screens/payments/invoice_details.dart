import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../utils/utils.dart';
import '../../widgets/cards/section_card.dart';
import '../../widgets/buttons/custom_button.dart';

class InvoiceDetailsPage extends StatefulWidget {
  final String invoiceId;
  final Map<String, dynamic>? initialInvoiceData;

  const InvoiceDetailsPage({
    super.key,
    required this.invoiceId,
    this.initialInvoiceData,
  });

  @override
  State<InvoiceDetailsPage> createState() => _InvoiceDetailsPageState();
}

class _InvoiceDetailsPageState extends State<InvoiceDetailsPage> {
  final storage = const FlutterSecureStorage();
  Map<String, dynamic>? _invoice;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialInvoiceData != null) {
      _invoice = widget.initialInvoiceData;
    }
    _loadInvoiceDetails();
  }

  Future<void> _loadInvoiceDetails() async {
    if (widget.initialInvoiceData != null) {
      return; // Skip if we already have data
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await storage.read(key: "edams_jwt");

      if (token == null || token.isEmpty) {
        _showSnackBar("Authentication required. Please login again.", false);
        return;
      }

      final response = await http.get(
        Uri.parse('${getUrl()}invoices/${widget.invoiceId}'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          if (mounted) {
            setState(() {
              _invoice = responseData['data'];
              _error = null;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _error =
                  responseData['message'] ?? 'Failed to load invoice details';
            });
          }
        }
      } else {
        final errorData = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _error = errorData['message'] ?? 'Server error';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading invoice details: $e';
        });
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

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatDateTime(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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

  Widget _buildDetailRow(String label, String value,
      {IconData? icon, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
          ],
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.black87,
                fontWeight:
                    valueColor != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationDetails() {
    final application = _invoice?['application'];
    if (application == null) {
      return const SectionCard(
        title: "Application Details",
        icon: Icons.description,
        child: Text('No application details available'),
      );
    }

    return SectionCard(
      title: "Application Details",
      icon: Icons.description,
      child: Column(
        children: [
          _buildDetailRow(
            'Project Title',
            application['ProjectTitle'] ?? 'N/A',
            icon: Icons.title,
          ),
          _buildDetailRow(
            'Parcel Number',
            application['ParcelNumber'] ?? 'N/A',
            icon: Icons.tag,
          ),
          _buildDetailRow(
            'Location',
            application['ProjectLocation'] ?? 'N/A',
            icon: Icons.location_on,
          ),
          _buildDetailRow(
            'Area',
            '${application['ProjectArea']?.toString() ?? 'N/A'} sq m',
            icon: Icons.straighten,
          ),
          _buildDetailRow(
            'Application Type',
            application['applicationType']?['Name'] ?? 'N/A',
            icon: Icons.category,
          ),
          _buildDetailRow(
            'Submission Date',
            _formatDate(application['SubmissionDate']),
            icon: Icons.calendar_today,
          ),
          _buildDetailRow(
            'Status',
            application['Status'] ?? 'N/A',
            icon: Icons.info,
            valueColor: _getStatusColor(application['Status']),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceDetails() {
    final invoice = _invoice;
    if (invoice == null) return const SizedBox.shrink();

    return SectionCard(
      title: "Invoice Information",
      icon: Icons.receipt,
      child: Column(
        children: [
          _buildDetailRow(
            'Invoice Number',
            invoice['InvoiceNumber'] ?? 'N/A',
            icon: Icons.confirmation_number,
          ),
          _buildDetailRow(
            'Amount',
            'KES ${_parseAmount(invoice['Amount']).toStringAsFixed(0)}',
            icon: Icons.attach_money,
            valueColor: const Color(0xFF2E7D32),
          ),
          _buildDetailRow(
            'Status',
            _getStatusText(invoice['Status']),
            icon: Icons.info,
            valueColor: _getStatusColor(invoice['Status']),
          ),
          _buildDetailRow(
            'Issue Date',
            _formatDate(invoice['IssueDate']),
            icon: Icons.calendar_today,
          ),
          _buildDetailRow(
            'Due Date',
            _formatDate(invoice['DueDate']),
            icon: Icons.event,
          ),
          _buildDetailRow(
            'Created',
            _formatDateTime(invoice['createdAt']),
            icon: Icons.access_time,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistory() {
    final payments = _invoice?['payments'] as List<dynamic>?;

    if (payments == null || payments.isEmpty) {
      return const SectionCard(
        title: "Payment History",
        icon: Icons.payment,
        child: Text('No payment history available'),
      );
    }

    return SectionCard(
      title: "Payment History",
      icon: Icons.payment,
      child: Column(
        children: payments
            .map((payment) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          'Amount Paid',
                          'KES ${_parseAmount(payment['AmountPaid']).toStringAsFixed(0)}',
                          valueColor: const Color(0xFF2E7D32),
                        ),
                        _buildDetailRow(
                          'Payment Date',
                          _formatDate(payment['PaymentDate']),
                        ),
                        _buildDetailRow(
                          'Transaction Reference',
                          payment['TransactionReference'] ?? 'N/A',
                        ),
                      ],
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildTimeline() {
    final invoice = _invoice;
    if (invoice == null) return const SizedBox.shrink();

    return SectionCard(
      title: "Invoice Timeline",
      icon: Icons.timeline,
      child: Column(
        children: [
          _buildTimelineItem(
            'Invoice Created',
            _formatDateTime(invoice['createdAt']),
            Icons.add_circle,
            Colors.blue,
          ),
          if (invoice['Status']?.toLowerCase() == 'paid') ...[
            _buildTimelineItem(
              'Payment Completed',
              _formatDateTime(invoice['updatedAt']),
              Icons.check_circle,
              Colors.green,
            ),
          ] else if (invoice['Status']?.toLowerCase() == 'overdue') ...[
            _buildTimelineItem(
              'Invoice Overdue',
              _formatDate(invoice['DueDate']),
              Icons.warning,
              Colors.red,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
      String title, String date, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final invoice = _invoice;
    if (invoice == null) return const SizedBox.shrink();

    final status = invoice['Status']?.toString().toLowerCase();

    return SectionCard(
      title: "Actions",
      icon: Icons.construction,
      child: Column(
        children: [
          if (status == 'pending' || status == 'overdue') ...[
            CustomButton(
              text: 'Make Payment',
              onPressed: () {
                _showSnackBar('Payment processing feature coming soon!', false);
              },
              icon: const Icon(Icons.payment, size: 16),
            ),
            const SizedBox(height: 12),
          ],
          if (status == 'paid') ...[
            CustomButton(
              text: 'Download Receipt',
              onPressed: () {
                _showSnackBar('Receipt download feature coming soon!', false);
              },
              icon: const Icon(Icons.download, size: 16),
            ),
            const SizedBox(height: 12),
          ],
          CustomButton(
            text: 'Print Invoice',
            onPressed: () {
              _showSnackBar('Print feature coming soon!', false);
            },
            icon: const Icon(Icons.print, size: 16),
            isOutlined: true,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to Load Invoice',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error occurred',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Retry',
            onPressed: _loadInvoiceDetails,
            icon: const Icon(Icons.refresh, size: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Details'),
        backgroundColor: getColor('primary'),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInvoiceDetails,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _invoice == null
                  ? const Center(child: Text('No invoice data available'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildInvoiceDetails(),
                          const SizedBox(height: 16),
                          _buildApplicationDetails(),
                          const SizedBox(height: 16),
                          _buildPaymentHistory(),
                          const SizedBox(height: 16),
                          _buildTimeline(),
                          const SizedBox(height: 16),
                          _buildActionButtons(),
                        ],
                      ),
                    ),
    );
  }
}
