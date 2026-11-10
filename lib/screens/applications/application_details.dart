import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../utils/utils.dart';
import '../../widgets/form_fields/my_text_label.dart';
import '../../widgets/cards/section_card.dart';

class ApplicationDetailsPage extends StatefulWidget {
  final String applicationId;

  const ApplicationDetailsPage({
    super.key,
    required this.applicationId,
  });

  @override
  State<ApplicationDetailsPage> createState() => _ApplicationDetailsPageState();
}

class _ApplicationDetailsPageState extends State<ApplicationDetailsPage> {
  final storage = const FlutterSecureStorage();
  Map<String, dynamic>? _application;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadApplicationDetails();
  }

  Future<void> _loadApplicationDetails() async {
    setState(() => _isLoading = true);

    try {
      final token = await storage.read(key: "edams_jwt");

      if (token == null || token.isEmpty) {
        _showSnackBar("Authentication required. Please login again.", false);
        return;
      }

      final response = await http.get(
        Uri.parse('${getUrl()}applications/${widget.applicationId}'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Handle both response formats: direct data or success/data wrapper
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('success') &&
              responseData['success'] == true) {
            // Response has success wrapper
            setState(() {
              _application = responseData['data'];
              _error = null;
            });
          } else if (responseData.containsKey('ID')) {
            // Response is direct application data
            setState(() {
              _application = responseData;
              _error = null;
            });
          } else {
            setState(() {
              _error = responseData['message'] ??
                  'Failed to load application details';
            });
          }
        } else {
          setState(() {
            _error = 'Invalid response format';
          });
        }
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          _error = errorData['message'] ?? errorData['error'] ?? 'Server error';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading application details: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, bool isSuccess) {
    if (!mounted) return;

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
        return 'Additional Info Required';
      default:
        return status ?? 'Unknown';
    }
  }

  Widget _buildStatusBadge(String? status) {
    final statusText = _getStatusText(status);
    final statusColor = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(status),
            size: 16,
            color: statusColor,
          ),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'deferred':
        return Icons.pending;
      case 'additional info required':
        return Icons.info;
      default:
        return Icons.help;
    }
  }

  Widget _buildInfoRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 20,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard() {
    if (_application == null) return const SizedBox.shrink();

    final timeline = [
      {
        'title': 'Application Submitted',
        'date': _application!['SubmissionDate'],
        'icon': Icons.send,
        'completed': true,
      },
      {
        'title': 'Under Review',
        'date': _application!['Status'] == 'Pending'
            ? null
            : _application!['SubmissionDate'],
        'icon': Icons.pending,
        'completed': _application!['Status'] != 'Pending',
      },
      {
        'title': 'Department Feedback',
        'date': _application!['DepartmentFeedback']?.isNotEmpty == true
            ? 'In Progress'
            : null,
        'icon': Icons.feedback,
        'completed': _application!['IsAllDepartmentsFeedbackReceived'] == true,
      },
      {
        'title': 'Final Decision',
        'date': _application!['ApprovedDate'],
        'icon': Icons.gavel,
        'completed': _application!['Status'] == 'Approved' ||
            _application!['Status'] == 'Rejected',
      },
    ];

    return SectionCard(
      title: "Application Timeline",
      icon: Icons.timeline,
      child: Column(
        children: timeline.map((item) {
          final isCompleted = item['completed'] as bool;
          final date = item['date'] as String?;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isCompleted ? getColor('primary') : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: isCompleted ? Colors.white : Colors.grey[600],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color:
                              isCompleted ? Colors.black87 : Colors.grey[600],
                        ),
                      ),
                      if (date != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(date),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading application details...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
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
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load application details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error occurred',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadApplicationDetails,
            style: ElevatedButton.styleFrom(
              backgroundColor: getColor('primary'),
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Details'),
        backgroundColor: getColor('primary'),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _application == null
                  ? _buildErrorState()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Status Card
                          SectionCard(
                            title: "Application Status",
                            icon: Icons.info,
                            child: Center(
                              child: _buildStatusBadge(_application!['Status']),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Basic Information
                          SectionCard(
                            title: "Basic Information",
                            icon: Icons.description,
                            child: Column(
                              children: [
                                _buildInfoRow(
                                  "Application ID",
                                  _application!['ID'] ?? 'N/A',
                                  icon: Icons.fingerprint,
                                ),
                                _buildInfoRow(
                                  "Project Title",
                                  _application!['ProjectTitle'] ?? 'N/A',
                                  icon: Icons.title,
                                ),
                                _buildInfoRow(
                                  "Parcel Number",
                                  _application!['ParcelNumber'] ?? 'N/A',
                                  icon: Icons.tag,
                                ),
                                _buildInfoRow(
                                  "Project Location",
                                  _application!['ProjectLocation'] ?? 'N/A',
                                  icon: Icons.location_on,
                                ),
                                _buildInfoRow(
                                  "Project Area",
                                  _application!['ProjectArea']?.toString() ??
                                      'N/A',
                                  icon: Icons.square_foot,
                                ),
                                if (_application!['ProjectDescription']
                                        ?.isNotEmpty ==
                                    true)
                                  _buildInfoRow(
                                    "Description",
                                    _application!['ProjectDescription'] ??
                                        'N/A',
                                    icon: Icons.notes,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Dates & Timeline
                          SectionCard(
                            title: "Important Dates",
                            icon: Icons.calendar_today,
                            child: Column(
                              children: [
                                _buildInfoRow(
                                  "Submission Date",
                                  _formatDate(_application!['SubmissionDate']),
                                  icon: Icons.send,
                                ),
                                if (_application!['ApprovedDate'] != null)
                                  _buildInfoRow(
                                    "Approved Date",
                                    _formatDate(_application!['ApprovedDate']),
                                    icon: Icons.check_circle,
                                  ),
                                if (_application!['InvoicedDate'] != null)
                                  _buildInfoRow(
                                    "Invoiced Date",
                                    _formatDate(_application!['InvoicedDate']),
                                    icon: Icons.receipt,
                                  ),
                                if (_application!['PaymentDate'] != null)
                                  _buildInfoRow(
                                    "Payment Date",
                                    _formatDate(_application!['PaymentDate']),
                                    icon: Icons.payment,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Financial Information
                          if (_application!['InvoicedAmount'] != null ||
                              _application!['TotalCost'] != null)
                            SectionCard(
                              title: "Financial Information",
                              icon: Icons.attach_money,
                              child: Column(
                                children: [
                                  if (_application!['TotalCost'] != null)
                                    _buildInfoRow(
                                      "Total Cost",
                                      'KES ${_application!['TotalCost'].toStringAsFixed(0)}',
                                      icon: Icons.calculate,
                                    ),
                                  if (_application!['InvoicedAmount'] != null)
                                    _buildInfoRow(
                                      "Invoiced Amount",
                                      'KES ${_application!['InvoicedAmount'].toStringAsFixed(0)}',
                                      icon: Icons.receipt,
                                    ),
                                  _buildInfoRow(
                                    "Payment Status",
                                    _application!['PaymentStatus'] ?? 'N/A',
                                    icon: Icons.payment,
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16),

                          // Timeline
                          _buildTimelineCard(),
                          const SizedBox(height: 16),

                          // Remarks
                          if (_application!['Remarks']?.isNotEmpty == true)
                            SectionCard(
                              title: "Remarks",
                              icon: Icons.comment,
                              child: MyTextLabel(
                                text: _application!['Remarks'],
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                        ],
                      ),
                    ),
    );
  }
}
