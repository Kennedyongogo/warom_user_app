import 'dart:convert';

import 'package:edams_mobile/widgets/cards/section_card.dart';
import 'package:edams_mobile/widgets/form_fields/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../utils/utils.dart';
import '../../widgets/buttons/custom_button.dart';
import 'illegal_development_report.dart';

class IllegalReportsPage extends StatefulWidget {
  const IllegalReportsPage({super.key});

  @override
  State<IllegalReportsPage> createState() => _IllegalReportsPageState();
}

class _IllegalReportsPageState extends State<IllegalReportsPage> {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  String _searchQuery = '';
  String? _reporterId;
  List<Map<String, dynamic>> _reports = [];

  @override
  void initState() {
    super.initState();
    _initialise();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initialise() async {
    await _loadReporterId();
    await _fetchReports();
  }

  Future<void> _loadReporterId() async {
    try {
      final token = await storage.read(key: 'edams_jwt');
      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = 'Authentication token not found. Please login again.';
        });
        return;
      }

      final decoded = parseJwt(token);
      final reporterId = decoded['id']?.toString();

      if (reporterId == null || reporterId.isEmpty) {
        setState(() {
          _errorMessage = 'Unable to determine reporter ID from session.';
        });
        return;
      }

      setState(() {
        _reporterId = reporterId;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to read user information. $e';
      });
    }
  }

  Future<void> _fetchReports({bool isRefresh = false}) async {
    if (_reporterId == null || _reporterId!.isEmpty) {
      return;
    }

    if (!isRefresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isRefreshing = true;
        _errorMessage = null;
      });
    }

    try {
      final response =
          await httpGet('illegal-development/reporter/$_reporterId');

      if (response['success'] == true) {
        final dynamic payload = response['data'];
        List<dynamic> data = [];
        bool extractedList = false;

        if (payload is List) {
          data = payload;
          extractedList = true;
        } else if (payload is Map<String, dynamic>) {
          final dynamic nested = payload['data'];
          if (nested is List) {
            data = nested;
            extractedList = true;
          }
        }

        if (!extractedList) {
          setState(() {
            _errorMessage =
                payload['message']?.toString() ?? 'No reports found.';
            _reports = [];
          });
        } else {
          setState(() {
            _reports = data.map<Map<String, dynamic>>((item) {
              if (item is Map<String, dynamic>) return item;
              if (item is Map) {
                return item.map<String, dynamic>(
                    (key, value) => MapEntry(key.toString(), value));
              }
              return {};
            }).toList();
          });
        }
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load reports.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred while loading reports. $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredReports {
    if (_searchQuery.isEmpty) {
      return _reports;
    }

    final query = _searchQuery.toLowerCase();
    return _reports.where((report) {
      final title = report['Title']?.toString().toLowerCase() ?? '';
      final location = report['Location']?.toString().toLowerCase() ?? '';
      final violationType =
          report['ViolationType']?.toString().toLowerCase() ?? '';
      final status = report['Status']?.toString().toLowerCase() ?? '';
      return title.contains(query) ||
          location.contains(query) ||
          violationType.contains(query) ||
          status.contains(query);
    }).toList();
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final parsed = DateTime.parse(dateString);
      return '${parsed.day}/${parsed.month}/${parsed.year}';
    } catch (_) {
      return dateString;
    }
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'investigating':
        return Colors.blue;
      case 'escalated':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showReportDetails(Map<String, dynamic> report) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) {
        final reporterContact = report['ReporterContactInfo'];
        String contactInfo = 'Not provided';
        if (reporterContact != null) {
          try {
            if (reporterContact is Map) {
              final name = reporterContact['name'] ?? 'N/A';
              final email = reporterContact['email'] ?? 'N/A';
              final phone = reporterContact['phone'] ?? 'N/A';
              contactInfo = 'Name: $name\nEmail: $email\nPhone: $phone';
            } else if (reporterContact is String &&
                reporterContact.isNotEmpty) {
              final decoded = jsonDecode(reporterContact);
              final name = decoded['name'] ?? 'N/A';
              final email = decoded['email'] ?? 'N/A';
              final phone = decoded['phone'] ?? 'N/A';
              contactInfo = 'Name: $name\nEmail: $email\nPhone: $phone';
            }
          } catch (_) {}
        }

        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          report['Title']?.toString() ??
                              'Illegal Development Report',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color:
                              _statusColor(report['Status']).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          report['Status']?.toString() ?? 'Unknown',
                          style: TextStyle(
                            color: _statusColor(report['Status']),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _detailRow(
                      Icons.calendar_today,
                      'Reported',
                      _formatDate(report['ReportDate']?.toString() ??
                          report['createdAt']?.toString())),
                  _detailRow(Icons.location_on, 'Location',
                      report['Location']?.toString() ?? 'Not provided'),
                  _detailRow(Icons.warning, 'Violation Type',
                      report['ViolationType']?.toString() ?? 'Other'),
                  _detailRow(Icons.assessment, 'Severity',
                      report['Severity']?.toString() ?? 'Medium'),
                  _detailRow(Icons.flag, 'Priority',
                      report['Priority']?.toString() ?? 'Normal'),
                  const SizedBox(height: 16),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    report['Description']?.toString() ??
                        'No description provided.',
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Reporter Contact Info',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    contactInfo,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openNewReport() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const IllegalDevelopmentReport(),
      ),
    );
    if (!mounted) return;
    if (result == true) {
      await _fetchReports(isRefresh: true);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.report_gmailerrorred_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No reports yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Submit a new illegal development report to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], height: 1.4),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Report Illegal Development',
              onPressed: _openNewReport,
              icon: const Icon(Icons.report_problem_outlined, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Illegal Reports'),
        backgroundColor: getColor('primary'),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh),
            onPressed:
                _isRefreshing ? null : () => _fetchReports(isRefresh: true),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _reports.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: () => _fetchReports(isRefresh: true),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            SectionCard(
                              title: 'Search Reports',
                              icon: Icons.search,
                              child: CustomTextField(
                                controller: _searchController,
                                label: 'Search',
                                hint:
                                    'Search by title, location, status, or violation type',
                                prefixIcon: const Icon(Icons.search),
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            ..._filteredReports
                                .map((report) => _buildReportCard(report))
                                ,
                          ],
                        ),
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: getColor('primary'),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Report'),
        onPressed: _openNewReport,
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to Load Reports',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Something went wrong while loading reports.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Retry',
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: () => _fetchReports(isRefresh: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final status = report['Status']?.toString();
    final violationType = report['ViolationType']?.toString() ?? 'Other';
    final reportDate =
        report['ReportDate']?.toString() ?? report['createdAt']?.toString();
    final location = report['Location']?.toString() ?? 'No location provided';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IllegalDevelopmentReport(
                existingReport: report,
              ),
            ),
          );
          if (result == true) {
            await _fetchReports(isRefresh: true);
          }
        },
        onLongPress: () => _showReportDetails(report),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      report['Title']?.toString() ??
                          'Illegal Development Report',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status ?? 'Unknown',
                      style: TextStyle(
                        color: _statusColor(status),
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
                  const Icon(Icons.warning_amber_rounded,
                      size: 16, color: Colors.orange),
                  const SizedBox(width: 6),
                  Text(
                    violationType,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 16, color: Colors.redAccent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      location,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: Colors.blueGrey),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(reportDate),
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
