import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../utils/utils.dart';
import 'scan_permit_screen.dart';

/// Confirms a development permit against the Nyamira records, by QR scan or typed code.
/// Works signed in or out, like Track.
class VerifyPermitPage extends StatefulWidget {
  /// Shows a back button when the page is pushed instead of used as a tab.
  final bool showBack;

  const VerifyPermitPage({super.key, this.showBack = false});

  @override
  State<VerifyPermitPage> createState() => _VerifyPermitPageState();
}

enum _Outcome { verified, notIssued, notFound, sample, error }

class _VerifyPermitPageState extends State<VerifyPermitPage> {
  static const _green = Color(0xFF289C75);
  static const _greenDark = Color(0xFF1B6E54);
  static const _deep = Color(0xFF0B3D2E);
  static const _gold = Color(0xFFF2C94C);
  static const _ink = Color(0xFF10291F);

  final _controller = TextEditingController();
  bool _loading = false;
  String? _inputError;
  _Outcome? _outcome;
  String _message = '';
  Map<String, dynamic> _data = const {};
  String _checkedRef = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// QR codes on permits hold a link ending in ?ref=<tracking code>; typed codes are used as is.
  String? _referenceFrom(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text);
    if (uri != null && uri.hasScheme) {
      final ref = uri.queryParameters['ref'];
      return (ref != null && ref.trim().isNotEmpty) ? ref.trim() : null;
    }
    return text;
  }

  Future<void> _openScanner() async {
    FocusScope.of(context).unfocus();
    final raw = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ScanPermitScreen(), fullscreenDialog: true),
    );
    if (raw == null || !mounted) return;
    if (raw.toLowerCase().contains('sample template')) {
      setState(() {
        _outcome = _Outcome.sample;
        _message = 'This QR comes from a permit template, not an issued permit.';
        _data = const {};
        _checkedRef = '';
      });
      return;
    }
    final ref = _referenceFrom(raw);
    if (ref == null) {
      setState(() {
        _outcome = _Outcome.notFound;
        _message = 'This QR code does not belong to a Nyamira permit.';
        _data = const {};
        _checkedRef = '';
      });
      return;
    }
    _controller.text = ref.toUpperCase();
    await _verify(ref);
  }

  Future<void> _verify([String? value]) async {
    final ref = (value ?? _controller.text).trim();
    FocusScope.of(context).unfocus();
    if (ref.length < 4) {
      setState(() => _inputError = 'Enter the tracking code or permit number, e.g. NYM-2026-00042.');
      return;
    }
    setState(() {
      _inputError = null;
      _loading = true;
      _outcome = null;
    });

    try {
      final response = await http
          .get(
            Uri.parse('${getUrl()}applications/verify?ref=${Uri.encodeQueryComponent(ref)}'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 20));
      Map<String, dynamic> body = {};
      try {
        body = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
      } catch (_) {}

      final data = body['data'] is Map ? Map<String, dynamic>.from(body['data'] as Map) : <String, dynamic>{};
      _Outcome outcome;
      String message;
      if (response.statusCode == 200 && body['success'] == true) {
        final issued = data['isValid'] == true && (data['status'] == null || data['status'] == 'Approved');
        outcome = issued ? _Outcome.verified : _Outcome.notIssued;
        message = (data['message'] ?? body['message'] ?? '').toString();
        if (message.isEmpty) {
          message = issued
              ? 'This permit was issued by the County Government of Nyamira.'
              : 'This reference is in the Nyamira records. A permit has not been issued.';
        }
      } else if (response.statusCode == 404 || response.statusCode == 400) {
        outcome = _Outcome.notFound;
        message = (body['message'] ?? 'No permit with that reference was found in the Nyamira records.').toString();
      } else {
        outcome = _Outcome.error;
        message = 'The verification service could not check this code right now. Try again shortly.';
      }
      HapticFeedback.lightImpact();
      if (!mounted) return;
      setState(() {
        _outcome = outcome;
        _message = message;
        _data = data;
        _checkedRef = ref.toUpperCase();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _outcome = _Outcome.error;
        _message = 'Connection failed. Check your internet and try again.';
        _data = const {};
        _checkedRef = ref.toUpperCase();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _reset() {
    _controller.clear();
    setState(() {
      _outcome = null;
      _inputError = null;
      _data = const {};
      _checkedRef = '';
    });
  }

  String _formatDate(dynamic value) {
    if (value == null || value.toString().isEmpty) return '—';
    try {
      final dt = DateTime.parse(value.toString()).toLocal();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          // Header and scan card share one sliver: the viewport paints earlier slivers on top,
          // so a card overlapping the header must be painted inside the header's sliver.
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(context),
                Transform.translate(
                  offset: const Offset(0, -34),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _scanCard(),
                  ),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 28),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Transform.translate(offset: const Offset(0, -18), child: _manualCard()),
                if (_loading) _checking(),
                if (!_loading && _outcome != null) _resultCard(),
                if (!_loading && _outcome == null) _howItWorks(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, top + 10, 16, 58),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_deep, _greenDark, _green],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.showBack) ...[
                Material(
                  color: Colors.white.withValues(alpha: 0.14),
                  shape: const CircleBorder(),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    tooltip: 'Back',
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(Icons.verified_user_rounded, color: _gold),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NYAMIRA COUNTY · eDAMS',
                      style: TextStyle(color: _gold, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Verify a permit',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Scan the QR code on a development permit, or type its code, to confirm it was really issued by the County.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 13.5, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _scanCard() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: _loading ? null : _openScanner,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _green.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(color: _ink.withValues(alpha: 0.12), blurRadius: 28, offset: const Offset(0, 14)),
            ],
          ),
          child: Row(
            children: [
              const _PulsingScanIcon(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Scan permit QR code',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5, color: _ink),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fastest way. Uses your camera, or a photo from your gallery.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5, height: 1.35),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: _greenDark,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.qr_code_scanner_rounded, size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Text('Open scanner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _manualCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.keyboard_alt_outlined, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                'OR TYPE THE CODE',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: Colors.grey.shade700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _verify(),
            onChanged: (_) => setState(() => _inputError = null),
            style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.6),
            decoration: InputDecoration(
              hintText: 'NYM-2026-00042 or permit number',
              errorText: _inputError,
              filled: true,
              fillColor: const Color(0xFFF6FAF8),
              prefixIcon: const Icon(Icons.tag_rounded, color: _green),
              suffixIcon: _controller.text.isEmpty
                  ? IconButton(
                      tooltip: 'Paste',
                      icon: const Icon(Icons.content_paste_rounded),
                      onPressed: () async {
                        final data = await Clipboard.getData(Clipboard.kTextPlain);
                        final text = data?.text?.trim();
                        if (text != null && text.isNotEmpty) {
                          final ref = _referenceFrom(text) ?? text;
                          _controller.text = ref.toUpperCase();
                          setState(() {});
                        }
                      },
                    )
                  : IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: _reset,
                    ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _green, width: 1.6),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _loading ? null : () => _verify(),
              icon: _loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.shield_rounded),
              label: Text(_loading ? 'Checking…' : 'Verify permit'),
              style: FilledButton.styleFrom(
                backgroundColor: _greenDark,
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checking() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(color: _green, strokeWidth: 3)),
          const SizedBox(height: 14),
          Text('Checking the Nyamira records…', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _resultCard() {
    switch (_outcome!) {
      case _Outcome.verified:
        return _verifiedCard();
      case _Outcome.notIssued:
        return _statusCard(
          color: const Color(0xFF9A5B13),
          soft: const Color(0xFFFFF4E0),
          icon: Icons.hourglass_top_rounded,
          title: 'Permit not issued yet',
          extra: [
            if (_checkedRef.isNotEmpty) _detail('Reference', _checkedRef),
            if (_data['status'] != null) _detail('Current stage', _data['status'].toString()),
          ],
        );
      case _Outcome.sample:
        return _statusCard(
          color: const Color(0xFF8A5A00),
          soft: const Color(0xFFFFF8E1),
          icon: Icons.description_outlined,
          title: 'Sample QR code',
        );
      case _Outcome.notFound:
        return _statusCard(
          color: const Color(0xFFB42318),
          soft: const Color(0xFFFEE4E2),
          icon: Icons.gpp_bad_rounded,
          title: 'No matching permit',
          extra: [
            if (_checkedRef.isNotEmpty) _detail('Checked', _checkedRef),
            const SizedBox(height: 4),
            Text(
              'Treat this document with caution. Contact the County planning office if you were given it as a permit.',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12.5, height: 1.4),
            ),
          ],
        );
      case _Outcome.error:
        return _statusCard(
          color: const Color(0xFF475467),
          soft: const Color(0xFFF2F4F7),
          icon: Icons.cloud_off_rounded,
          title: 'Could not check',
          action: TextButton.icon(
            onPressed: _checkedRef.isEmpty ? null : () => _verify(_checkedRef),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        );
    }
  }

  Widget _verifiedCard() {
    final location = [_data['projectLocation'], _data['ward'], _data['subCounty']]
        .where((v) => v != null && v.toString().trim().isNotEmpty)
        .join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(colors: [_greenDark, _green], begin: Alignment.topLeft, end: Alignment.bottomRight),
            boxShadow: [BoxShadow(color: _green.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 12))],
          ),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: _gold.withValues(alpha: 0.6), blurRadius: 0, spreadRadius: 4)],
                ),
                child: const Icon(Icons.verified_rounded, color: _greenDark, size: 38),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AUTHENTIC PERMIT',
                      style: TextStyle(color: _gold, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      (_data['permitNumber'] ?? _checkedRef).toString(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _message,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12.5, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Permit details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _ink)),
              const SizedBox(height: 8),
              _row(Icons.tag_rounded, 'Tracking code', _data['trackingCode'] ?? _data['referenceNumber']),
              _row(Icons.person_outline_rounded, 'Applicant', _data['applicantName']),
              _row(Icons.category_outlined, 'Application', _data['applicationType']),
              _row(Icons.apartment_rounded, 'Project', _data['projectTitle']),
              _row(Icons.grid_on_rounded, 'Parcel', _data['parcelNumber']),
              _row(Icons.place_outlined, 'Location', location),
              _row(Icons.event_available_rounded, 'Issued', _formatDate(_data['issueDate'] ?? _data['finalizedDate'])),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Compare these details with the paper permit. They must match.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _reset,
          icon: const Icon(Icons.qr_code_scanner_rounded),
          label: const Text('Check another permit'),
          style: TextButton.styleFrom(foregroundColor: _greenDark, textStyle: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _row(IconData icon, String label, dynamic value) {
    final text = value == null || value.toString().trim().isEmpty || value.toString() == 'N/A' ? '—' : value.toString();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: const Color(0xFFE9F5EF), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 17, color: _greenDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: Colors.grey.shade600)),
                const SizedBox(height: 2),
                Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: _ink))),
        ],
      ),
    );
  }

  Widget _statusCard({
    required Color color,
    required Color soft,
    required IconData icon,
    required String title,
    List<Widget> extra = const [],
    Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5, color: color)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(_message, style: const TextStyle(fontSize: 13.5, height: 1.4, color: _ink)),
          ...extra,
          if (action != null) ...[const SizedBox(height: 6), action],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _reset,
              style: TextButton.styleFrom(foregroundColor: _greenDark),
              child: const Text('Start over'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _howItWorks() {
    const steps = [
      (Icons.qr_code_2_rounded, 'Find the QR code', 'It is at the bottom of page 2 of every Nyamira permit.'),
      (Icons.center_focus_strong_rounded, 'Scan or type', 'Scan it, or type the tracking code printed on the permit.'),
      (Icons.verified_rounded, 'See the result', 'We check the County records and show the permit details.'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How it works', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _ink)),
          const SizedBox(height: 12),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == steps.length - 1 ? 0 : 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: i == 2 ? const Color(0xFFFFF4D6) : const Color(0xFFE9F5EF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(steps[i].$1, color: i == 2 ? const Color(0xFF8A5A00) : _greenDark, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(steps[i].$2, style: const TextStyle(fontWeight: FontWeight.w800, color: _ink)),
                        const SizedBox(height: 2),
                        Text(steps[i].$3, style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5, height: 1.35)),
                      ],
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

class _PulsingScanIcon extends StatefulWidget {
  const _PulsingScanIcon();

  @override
  State<_PulsingScanIcon> createState() => _PulsingScanIconState();
}

class _PulsingScanIconState extends State<_PulsingScanIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      height: 78,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 56 + 22 * _c.value,
                height: 56 + 22 * _c.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF289C75).withValues(alpha: 0.18 * (1 - _c.value)),
                ),
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B6E54), Color(0xFF289C75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 32),
              ),
            ],
          );
        },
      ),
    );
  }
}
