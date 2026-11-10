import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../utils/utils.dart';

class TrackApplicationPage extends StatefulWidget {
  const TrackApplicationPage({super.key});

  @override
  State<TrackApplicationPage> createState() => _TrackApplicationPageState();
}

class _TrackApplicationPageState extends State<TrackApplicationPage> {
  static const _green = Color(0xFF2E7D32);
  static const _greenDark = Color(0xFF1B5E20);
  static const _gold = Color(0xFFF2C94C);
  static const _codeRe = r'^NYM-\d{4}-\d{5,}$';

  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _searchKey = GlobalKey();

  bool _loading = false;
  String? _error;
  String? _notFound;
  Map<String, dynamic>? _result;

  static const _stages = [
    'Submitted',
    'Vetting',
    'Circulation',
    'Pre-Agenda',
    'Agenda',
    'Approved',
  ];

  static const _offPath = {
    'Pending Professional Confirmation': 0,
    'Reverted': 0,
    'Deferred': 4,
    'Rejected': 5,
  };

  static const _nextStep = {
    'Pending Professional Confirmation':
        'Professionals named on the application are confirming. Once they accept, it moves to vetting.',
    'Reverted':
        'A professional declined. The applicant needs to replace them and resubmit.',
    'Vetting':
        'County officers are checking documents and fees — usually the first review step.',
    'Circulation':
        'Departments are reviewing the application and adding comments.',
    'Pre-Agenda':
        'Planning officers are preparing the application for the committee.',
    'Agenda': 'The application is listed for the next planning committee.',
    'Approved': 'The permit has been granted. Download it from your account.',
    'Deferred':
        'The committee needs more information. Respond from your account.',
    'Rejected': 'The application was closed. Reasons are in your account.',
  };

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _ensureSearchVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _searchKey.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.05,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  int _stageIndex(String status) {
    if (_offPath.containsKey(status)) return _offPath[status]!;
    final i = _stages.indexOf(status);
    return i < 0 ? 0 : i;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Approved':
        return const Color(0xFF067647);
      case 'Rejected':
        return const Color(0xFFB42318);
      case 'Deferred':
      case 'Reverted':
        return const Color(0xFFB54708);
      case 'Agenda':
      case 'Pre-Agenda':
        return const Color(0xFF2F5F2F);
      default:
        return _green;
    }
  }

  Future<void> _lookup([String? value]) async {
    final clean = (value ?? _controller.text).trim().toUpperCase();
    _controller.value = TextEditingValue(
      text: clean,
      selection: TextSelection.collapsed(offset: clean.length),
    );

    setState(() {
      _error = null;
      _notFound = null;
      _result = null;
    });

    if (!RegExp(_codeRe, caseSensitive: false).hasMatch(clean)) {
      setState(() => _error = 'Tracking codes look like NYM-2026-00042.');
      return;
    }

    setState(() => _loading = true);
    try {
      final response = await http.get(
        Uri.parse('${getUrl()}applications/track/${Uri.encodeComponent(clean)}'),
        headers: const {'Accept': 'application/json'},
      );
      final body = jsonDecode(response.body);

      if (response.statusCode == 404) {
        setState(() => _notFound = 'No application matches $clean.');
        return;
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        setState(() {
          _notFound = body['message']?.toString() ?? "Couldn't look up that code.";
        });
        return;
      }

      final data = body['data'] is Map
          ? Map<String, dynamic>.from(body['data'])
          : <String, dynamic>{};
      setState(() => _result = data);
    } catch (e) {
      setState(() => _notFound = 'Connection failed. Check your internet and try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return '—';
    try {
      final dt = DateTime.parse(value.toString()).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      resizeToAvoidBottomInset: true,
      body: CustomScrollView(
        controller: _scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(
            child: _HeroHeader(
              gold: _gold,
              greenDark: _greenDark,
              green: _green,
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                KeyedSubtree(
                  key: _searchKey,
                  child: _SearchCard(
                    controller: _controller,
                    loading: _loading,
                    error: _error,
                    green: _green,
                    onChanged: () => setState(() {}),
                    onFocus: _ensureSearchVisible,
                    onSubmit: () => _lookup(),
                    onClear: () {
                      _controller.clear();
                      setState(() {
                        _result = null;
                        _error = null;
                        _notFound = null;
                      });
                    },
                    onPaste: () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      final text = data?.text?.trim();
                      if (text != null && text.isNotEmpty) {
                        await _lookup(text);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (_notFound != null && !_loading)
                  _EmptyState(
                    title: "We couldn't find that application",
                    message: _notFound!,
                    onRetry: () => _lookup(),
                  ),
                if (_result != null && !_loading) _buildResult(_result!),
                if (_result == null && !_loading && _notFound == null)
                  _HowItWorks(green: _green),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(Map<String, dynamic> result) {
    final status = result['Status']?.toString() ?? 'Submitted';
    final color = _statusColor(status);
    final reached = _stageIndex(status);
    final history = (result['History'] is List)
        ? List<Map<String, dynamic>>.from(
            (result['History'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
          )
        : <Map<String, dynamic>>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, Color.lerp(color, Colors.black, 0.2)!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  result['TrackingCode']?.toString() ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                result['ApplicationType']?.toString() ?? 'Development application',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _nextStep[status] ?? 'Progress is updating as county officers review the file.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Progress',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              const SizedBox(height: 14),
              ...List.generate(_stages.length, (i) {
                final done = i < reached || status == 'Approved';
                final current = i == reached && status != 'Approved';
                final label = _stages[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: done || current ? color : Colors.grey.shade200,
                              border: Border.all(
                                color: done || current ? color : Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                            child: done
                                ? const Icon(Icons.check, size: 12, color: Colors.white)
                                : current
                                    ? Center(
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      )
                                    : null,
                          ),
                          if (i < _stages.length - 1)
                            Container(
                              width: 2,
                              height: 22,
                              color: done ? color.withValues(alpha: 0.45) : Colors.grey.shade200,
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontWeight: current || done ? FontWeight.w800 : FontWeight.w500,
                            color: current || done ? color : Colors.grey.shade600,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Column(
            children: [
              _MetaRow(label: 'Submitted', value: _formatDate(result['SubmissionDate'])),
              const Divider(height: 20),
              _MetaRow(label: 'Last updated', value: _formatDate(result['LastUpdated'])),
              if (result['ApprovedDate'] != null) ...[
                const Divider(height: 20),
                _MetaRow(label: 'Approved', value: _formatDate(result['ApprovedDate'])),
              ],
              if (result['BillingStatus'] != null) ...[
                const Divider(height: 20),
                _MetaRow(label: 'Billing', value: result['BillingStatus'].toString()),
              ],
            ],
          ),
        ),
        if (history.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status history',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 10),
                ...history.reversed.take(8).map((h) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Icon(Icons.history, size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${h['From'] ?? '—'} → ${h['To'] ?? '—'}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                        Text(
                          _formatDate(h['At']),
                          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final Color gold;
  final Color greenDark;
  final Color green;

  const _HeroHeader({
    required this.gold,
    required this.greenDark,
    required this.green,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, top + 12, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF0D4F14), greenDark, green],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(Icons.travel_explore_rounded, color: gold),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nyamira County · eDAMS',
                  style: TextStyle(
                    color: Color(0xFFF2C94C),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Track application',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchCard extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final String? error;
  final Color green;
  final VoidCallback onChanged;
  final VoidCallback onFocus;
  final VoidCallback onSubmit;
  final VoidCallback onClear;
  final VoidCallback onPaste;

  const _SearchCard({
    required this.controller,
    required this.loading,
    required this.error,
    required this.green,
    required this.onChanged,
    required this.onFocus,
    required this.onSubmit,
    required this.onClear,
    required this.onPaste,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(18),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Focus(
              onFocusChange: (focused) {
                if (focused) onFocus();
              },
              child: TextField(
                controller: controller,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'NYM-2026-00042',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: controller.text.isNotEmpty
                      ? IconButton(
                          onPressed: onClear,
                          icon: const Icon(Icons.close_rounded),
                        )
                      : IconButton(
                          onPressed: onPaste,
                          tooltip: 'Paste',
                          icon: const Icon(Icons.content_paste_rounded),
                        ),
                  filled: true,
                  fillColor: const Color(0xFFF4F7F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: green, width: 1.5),
                  ),
                  errorText: error,
                ),
                onChanged: (_) => onChanged(),
                onSubmitted: (_) => onSubmit(),
                textInputAction: TextInputAction.search,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: loading ? null : onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Track progress',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const _EmptyState({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 42, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, height: 1.4),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  final Color green;
  const _HowItWorks({required this.green});

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('Find your code', 'Use the NYM-… code from your submission confirmation or email.'),
      ('Enter & track', 'Paste or type it above — no sign-in needed.'),
      ('Follow stages', 'See live progress from vetting through approval.'),
    ];
    return Column(
      children: steps.asMap().entries.map((e) {
        final i = e.key;
        final step = e.value;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: green.withValues(alpha: 0.12),
                child: Text(
                  '${i + 1}',
                  style: TextStyle(color: green, fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(step.$1, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(step.$2, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.35)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
      ],
    );
  }
}
