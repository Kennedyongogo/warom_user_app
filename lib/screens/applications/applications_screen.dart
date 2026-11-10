import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../utils/utils.dart';
import '../../widgets/form_fields/custom_text_field.dart';
import '../../widgets/buttons/custom_button.dart';
import '../../widgets/cards/section_card.dart';
import '../new_application/new_application_page.dart';
import 'application_details.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  final storage = const FlutterSecureStorage();
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _applications = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _filterStatus = 'all'; // 'all', 'pending', 'approved', 'rejected'

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadApplications() async {
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
        Uri.parse('${getUrl()}applications'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          List<Map<String, dynamic>> applications = [];

          if (responseData['data'] is List) {
            applications =
                List<Map<String, dynamic>>.from(responseData['data']);
          } else if (responseData['data'] is Map &&
              responseData['data']['data'] is List) {
            applications =
                List<Map<String, dynamic>>.from(responseData['data']['data']);
          }

          if (mounted) {
            setState(() {
              _applications = applications;
            });
          }
        } else {
          if (mounted) {
            _showSnackBar(
                'Failed to load applications: ${responseData['message'] ?? 'Unknown error'}',
                false);
          }
        }
      } else {
        final errorData = jsonDecode(response.body);
        if (mounted) {
          _showSnackBar(
              'Failed to load applications: ${errorData['message'] ?? 'Server error'}',
              false);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error loading applications: $e', false);
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

  List<Map<String, dynamic>> get _filteredApplications {
    List<Map<String, dynamic>> filtered = _applications;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((app) {
        final projectTitle =
            app['ProjectTitle']?.toString().toLowerCase() ?? '';
        final parcelNumber =
            app['ParcelNumber']?.toString().toLowerCase() ?? '';
        final description =
            app['ProjectDescription']?.toString().toLowerCase() ?? '';

        return projectTitle.contains(_searchQuery.toLowerCase()) ||
            parcelNumber.contains(_searchQuery.toLowerCase()) ||
            description.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    if (_filterStatus != 'all') {
      filtered = filtered.where((app) {
        final status = app['Status']?.toString().toLowerCase() ?? '';
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
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'deferred':
        return Colors.blue;
      case 'additional info required':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'Pending Approval';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'deferred':
        return 'Under Review';
      case 'additional info required':
        return 'Info Required';
      default:
        return status ?? 'Unknown';
    }
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No applications found',
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
                : 'No applications have been submitted yet',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Refresh',
            onPressed: _loadApplications,
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
        automaticallyImplyLeading: false,
        title: const Text('My Applications'),
        backgroundColor: getColor('primary'),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApplications,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SectionCard(
                  title: "Search & Filter",
                  icon: Icons.search,
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: _searchController,
                        label: "Search Applications",
                        hint: "Search by title, parcel number, or description",
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
                            child: _buildFilterChip('Approved', 'approved'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFilterChip('Rejected', 'rejected'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildFilterChip('Under Review', 'deferred'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildFilterChip(
                                'Info Required', 'additional info required'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _filteredApplications.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadApplications,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredApplications.length,
                            itemBuilder: (context, index) {
                              final application = _filteredApplications[index];
                              return _buildApplicationCard(
                                  context, application);
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NewApplicationPage(),
            ),
          );
          if (result == true) {
            // Refresh the applications list
            _loadApplications();
          }
        },
        backgroundColor: getColor('primary'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildApplicationCard(
      BuildContext context, Map<String, dynamic> application) {
    final title = application['ProjectTitle'] ?? 'Untitled Application';
    final status = application['Status'];
    final statusText = _getStatusText(status);
    final statusColor = _getStatusColor(status);
    final submissionDate = _formatDate(application['SubmissionDate']);
    final parcelNumber = application['ParcelNumber'] ?? 'N/A';
    final invoicedAmount = application['InvoicedAmount'];
    final amountText = invoicedAmount != null
        ? 'KES ${invoicedAmount.toStringAsFixed(0)}'
        : 'TBD';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
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
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  submissionDate,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.tag, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  parcelNumber,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  amountText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _navigateToApplicationDetails(application);
                    },
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _handleApplicationAction(application);
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
        return 'Check Status';
      case 'approved':
        return 'Download Permit';
      case 'rejected':
        return 'View Reason';
      case 'deferred':
        return 'Check Progress';
      case 'additional info required':
        return 'Provide Info';
      default:
        return 'Take Action';
    }
  }

  Future<void> _navigateToApplicationDetails(
      Map<String, dynamic> application) async {
    final applicationId = application['ID']?.toString();

    if (applicationId == null || applicationId.isEmpty) {
      _showSnackBar('Application ID not found', false);
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ApplicationDetailsPage(
          applicationId: applicationId,
        ),
      ),
    );
  }

  void _handleApplicationAction(Map<String, dynamic> application) {
    final status = application['Status']?.toString().toLowerCase();

    switch (status) {
      case 'pending':
        _showSnackBar(
            'Your application is under review. Please check back later.',
            false);
        break;
      case 'approved':
        _showSnackBar('Permit download feature coming soon!', false);
        break;
      case 'rejected':
        _showSnackBar(
            'Please contact the office for rejection details.', false);
        break;
      case 'deferred':
        _showSnackBar(
            'Your application is being reviewed. Please wait for updates.',
            false);
        break;
      case 'additional info required':
        _showSnackBar(
            'Please provide the requested information through the office.',
            false);
        break;
      default:
        _showSnackBar('Action feature coming soon!', false);
        break;
    }
  }
}
