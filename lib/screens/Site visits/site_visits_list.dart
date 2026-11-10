import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../utils/utils.dart';
import 'site_visit.dart';

class SiteVisitsListPage extends StatefulWidget {
  final String? initialFilter;

  const SiteVisitsListPage({super.key, this.initialFilter});

  @override
  State<SiteVisitsListPage> createState() => _SiteVisitsListPageState();
}

class _SiteVisitsListPageState extends State<SiteVisitsListPage> {
  static const _green = Color(0xFF2E7D32);
  static const _bg = Color(0xFFF4F7F5);

  final storage = const FlutterSecureStorage();
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _siteVisits = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _filterStatus = 'all';
  String userId = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != null) {
      _filterStatus = widget.initialFilter!;
    }
    _loadSiteVisits();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSiteVisits() async {
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

      final decoded = parseJwt(token);
      if (mounted) {
        setState(() => userId = decoded['id']?.toString() ?? '');
      }

      final response = await http.get(
        Uri.parse('${getUrl()}site-visits'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          List<Map<String, dynamic>> siteVisits = [];
          if (responseData['data'] is List) {
            siteVisits = List<Map<String, dynamic>>.from(responseData['data']);
          } else if (responseData['data'] is Map &&
              responseData['data']['data'] is List) {
            siteVisits =
                List<Map<String, dynamic>>.from(responseData['data']['data']);
          }
          if (mounted) setState(() => _siteVisits = siteVisits);
        } else if (mounted) {
          _showSnackBar(
            'Failed to load site visits: ${responseData['message'] ?? 'Unknown error'}',
            false,
          );
        }
      } else if (mounted) {
        final errorData = jsonDecode(response.body);
        _showSnackBar(
          'Failed to load site visits: ${errorData['message'] ?? 'Server error'}',
          false,
        );
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error loading site visits: $e', false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, bool isSuccess) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isSuccess ? _green : Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredSiteVisits {
    var filtered = _siteVisits;

    if (userId.isNotEmpty) {
      filtered = filtered.where((visit) {
        return visit['AdminUserID']?.toString() == userId;
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((visit) {
        final projectTitle =
            visit['application']?['ProjectTitle']?.toString().toLowerCase() ??
                '';
        final report = visit['SiteVisitReport']?.toString().toLowerCase() ?? '';
        final date = visit['SiteVisitDate']?.toString().toLowerCase() ?? '';
        return projectTitle.contains(q) ||
            report.contains(q) ||
            date.contains(q);
      }).toList();
    }

    if (_filterStatus != 'all') {
      filtered = filtered.where((visit) {
        final isCompleted = visit['IsSiteVisitCompleted'] ?? false;
        return _filterStatus == 'completed' ? isCompleted : !isCompleted;
      }).toList();
    }

    return filtered;
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '—';
    try {
      final date = DateTime.parse(dateString);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return dateString;
    }
  }

  Future<void> _navigateToSiteVisit(Map<String, dynamic> siteVisit) async {
    final isCompleted = siteVisit['IsSiteVisitCompleted'] == true;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SiteVisit(
          siteVisitId: siteVisit['ID']?.toString(),
          applicationId: siteVisit['ApplicationID']?.toString(),
          // View-only only for finished visits; pending stays editable for submit.
          viewOnly: isCompleted,
        ),
      ),
    );
    if (result == true && mounted) _loadSiteVisits();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final canPop = Navigator.of(context).canPop();
    final pending = _siteVisits
        .where((v) =>
            v['AdminUserID']?.toString() == userId &&
            !(v['IsSiteVisitCompleted'] ?? false))
        .length;
    final completed = _siteVisits
        .where((v) =>
            v['AdminUserID']?.toString() == userId &&
            (v['IsSiteVisitCompleted'] ?? false))
        .length;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'Site Visits',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: canPop,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isLoading ? null : _loadSiteVisits,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading && _siteVisits.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _MiniStat(
                              label: 'Pending',
                              value: '$pending',
                              color: const Color(0xFFB54708),
                              soft: const Color(0xFFFFF4E5),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MiniStat(
                              label: 'Completed',
                              value: '$completed',
                              color: _green,
                              soft: const Color(0xFFE8F5E9),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: InputDecoration(
                          hintText: 'Search by project, report, or date',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: _bg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _FilterChip(
                            label: 'All',
                            selected: _filterStatus == 'all',
                            onTap: () => setState(() => _filterStatus = 'all'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Pending',
                            selected: _filterStatus == 'pending',
                            onTap: () =>
                                setState(() => _filterStatus = 'pending'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Completed',
                            selected: _filterStatus == 'completed',
                            onTap: () =>
                                setState(() => _filterStatus = 'completed'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _filteredSiteVisits.isEmpty
                      ? _EmptyState(
                          filtered: _searchQuery.isNotEmpty ||
                              _filterStatus != 'all',
                          onRefresh: _loadSiteVisits,
                        )
                      : RefreshIndicator(
                          color: _green,
                          onRefresh: _loadSiteVisits,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                              16,
                              14,
                              16,
                              bottomInset + 20,
                            ),
                            itemCount: _filteredSiteVisits.length,
                            itemBuilder: (context, index) {
                              return _VisitCard(
                                visit: _filteredSiteVisits[index],
                                dateLabel: _formatDate(
                                  _filteredSiteVisits[index]['SiteVisitDate']
                                      ?.toString(),
                                ),
                                timeLabel: _filteredSiteVisits[index]
                                            ['SiteVisitTime']
                                        ?.toString() ??
                                    '—',
                                onTap: () => _navigateToSiteVisit(
                                  _filteredSiteVisits[index],
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color soft;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.soft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? const Color(0xFF2E7D32) : const Color(0xFFF4F7F5),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: selected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  final Map<String, dynamic> visit;
  final String dateLabel;
  final String timeLabel;
  final VoidCallback onTap;

  const _VisitCard({
    required this.visit,
    required this.dateLabel,
    required this.timeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = visit['IsSiteVisitCompleted'] ?? false;
    final projectTitle =
        visit['application']?['ProjectTitle']?.toString() ?? 'Unknown project';
    final report = visit['SiteVisitReport']?.toString() ?? '';
    final photoCount = (visit['SiteVisitPhotos'] is List)
        ? (visit['SiteVisitPhotos'] as List).length
        : 0;
    final statusColor =
        isCompleted ? const Color(0xFF2E7D32) : const Color(0xFFB54708);
    final statusSoft =
        isCompleted ? const Color(0xFFE8F5E9) : const Color(0xFFFFF4E5);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: statusSoft,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        isCompleted
                            ? Icons.check_circle_rounded
                            : Icons.pending_actions_rounded,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            projectTitle,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1B3A2A),
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusSoft,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              isCompleted ? 'Completed' : 'Pending',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      dateLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Icon(Icons.access_time_rounded,
                        size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      timeLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (photoCount > 0) ...[
                      const SizedBox(width: 14),
                      Icon(Icons.photo_library_rounded,
                          size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(
                        '$photoCount',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                if (report.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    report,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool filtered;
  final VoidCallback onRefresh;

  const _EmptyState({required this.filtered, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 14),
            Text(
              filtered ? 'No matching visits' : 'No site visits yet',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1B3A2A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              filtered
                  ? 'Try adjusting your search or filters.'
                  : 'Assigned site visits will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, height: 1.4),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}
