import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

/// Full-screen camera that returns the text of the first QR code it reads.
class ScanPermitScreen extends StatefulWidget {
  const ScanPermitScreen({super.key});

  @override
  State<ScanPermitScreen> createState() => _ScanPermitScreenState();
}

class _ScanPermitScreenState extends State<ScanPermitScreen>
    with SingleTickerProviderStateMixin {
  static const _gold = Color(0xFFF2C94C);
  static const _green = Color(0xFF289C75);

  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
    autoStart: false,
  );
  late final AnimationController _line = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  bool _handled = false;
  bool _pickingImage = false;
  bool _cameraUnavailable = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startCamera());
  }

  /// Started here so a build without the camera plugin shows a message instead of a black screen.
  Future<void> _startCamera() async {
    try {
      await _controller.start();
    } on MissingPluginException {
      if (mounted) setState(() => _cameraUnavailable = true);
    } on MobileScannerException {
      // Permission and hardware errors are shown by the scanner's errorBuilder.
    }
  }

  @override
  void dispose() {
    _line.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _finish(String? value) {
    if (_handled || value == null || value.trim().isEmpty) return;
    _handled = true;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(value.trim());
  }

  void _onDetect(BarcodeCapture capture) {
    for (final code in capture.barcodes) {
      final raw = code.rawValue;
      if (raw != null && raw.trim().isNotEmpty) {
        _finish(raw);
        return;
      }
    }
  }

  Future<void> _scanFromGallery() async {
    if (_pickingImage) return;
    setState(() => _pickingImage = true);
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      final capture = await _controller.analyzeImage(picked.path);
      final raw = capture?.barcodes
          .map((b) => b.rawValue)
          .firstWhere((v) => v != null && v.trim().isNotEmpty, orElse: () => null);
      if (raw == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No QR code found in that picture. Try a clearer photo.')),
        );
        return;
      }
      _finish(raw);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That picture could not be read.')),
      );
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final box = (size.width * 0.72).clamp(220.0, 320.0);
    final window = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.44),
      width: box,
      height: box,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_cameraUnavailable)
            const _CameraUnavailable()
          else
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error) => _CameraError(error: error),
            ),
          IgnorePointer(
            child: CustomPaint(painter: _ScanOverlayPainter(window: window, accent: _gold)),
          ),
          Positioned.fromRect(
            rect: window,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _line,
                builder: (context, _) {
                  return Align(
                    alignment: Alignment(0, -0.9 + 1.8 * _line.value),
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        gradient: LinearGradient(colors: [
                          _gold.withValues(alpha: 0),
                          _gold,
                          _gold.withValues(alpha: 0),
                        ]),
                        boxShadow: [BoxShadow(color: _gold.withValues(alpha: 0.6), blurRadius: 12)],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  _GlassButton(
                    icon: Icons.close_rounded,
                    tooltip: 'Close',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Scan permit QR code',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                  ValueListenableBuilder<MobileScannerState>(
                    valueListenable: _controller,
                    builder: (context, state, _) {
                      final on = state.torchState == TorchState.on;
                      return _GlassButton(
                        icon: on ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                        tooltip: on ? 'Turn torch off' : 'Turn torch on',
                        active: on,
                        onTap: state.torchState == TorchState.unavailable ? null : _controller.toggleTorch,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            top: window.bottom + 28,
            child: Column(
              children: [
                const Text(
                  'Point the camera at the QR code on page 2 of the permit',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600, height: 1.35),
                ),
                const SizedBox(height: 6),
                Text(
                  'It is read automatically. Hold steady about 15 cm away.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12.5),
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.paddingOf(context).bottom + 20,
            child: Row(
              children: [
                Expanded(
                  child: _BottomAction(
                    icon: Icons.photo_library_rounded,
                    label: _pickingImage ? 'Opening…' : 'From gallery',
                    onTap: _pickingImage ? null : _scanFromGallery,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _BottomAction(
                    icon: Icons.cameraswitch_rounded,
                    label: 'Switch camera',
                    onTap: () => _controller.switchCamera(),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: window.top - 46,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_user_rounded, color: Colors.white, size: 15),
                    SizedBox(width: 6),
                    Text(
                      'County Government of Nyamira',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  final Rect window;
  final Color accent;

  _ScanOverlayPainter({required this.window, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final hole = RRect.fromRectAndRadius(window, const Radius.circular(26));
    final shade = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(hole)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(shade, Paint()..color = Colors.black.withValues(alpha: 0.62));

    final corner = Paint()
      ..color = accent
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const len = 34.0;
    const r = 26.0;
    final l = window.left, t = window.top, rt = window.right, b = window.bottom;

    canvas.drawPath(
      Path()
        ..moveTo(l, t + len)
        ..lineTo(l, t + r)
        ..arcToPoint(Offset(l + r, t), radius: const Radius.circular(r))
        ..lineTo(l + len, t),
      corner,
    );
    canvas.drawPath(
      Path()
        ..moveTo(rt - len, t)
        ..lineTo(rt - r, t)
        ..arcToPoint(Offset(rt, t + r), radius: const Radius.circular(r))
        ..lineTo(rt, t + len),
      corner,
    );
    canvas.drawPath(
      Path()
        ..moveTo(rt, b - len)
        ..lineTo(rt, b - r)
        ..arcToPoint(Offset(rt - r, b), radius: const Radius.circular(r))
        ..lineTo(rt - len, b),
      corner,
    );
    canvas.drawPath(
      Path()
        ..moveTo(l + len, b)
        ..lineTo(l + r, b)
        ..arcToPoint(Offset(l, b - r), radius: const Radius.circular(r))
        ..lineTo(l, b - len),
      corner,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanOverlayPainter old) => old.window != window || old.accent != accent;
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool active;

  const _GlassButton({required this.icon, required this.tooltip, this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: active ? const Color(0xFFF2C94C) : Colors.white.withValues(alpha: 0.16),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: active ? const Color(0xFF10291F) : Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _BottomAction({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraUnavailable extends StatelessWidget {
  const _CameraUnavailable();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0B2A20),
      padding: const EdgeInsets.all(28),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam_off_rounded, color: Color(0xFFF2C94C), size: 54),
          const SizedBox(height: 16),
          const Text(
            'Scanner not available in this build',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Update or reinstall the app to use the camera. You can still go back and type the permit code.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.78), height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  final MobileScannerException error;

  const _CameraError({required this.error});

  @override
  Widget build(BuildContext context) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return Container(
      color: const Color(0xFF0B2A20),
      padding: const EdgeInsets.all(28),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(denied ? Icons.no_photography_rounded : Icons.videocam_off_rounded, color: const Color(0xFFF2C94C), size: 54),
          const SizedBox(height: 16),
          Text(
            denied ? 'Camera access is off' : 'The camera could not start',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            denied
                ? 'Allow camera access to scan permit QR codes. You can also pick a photo from your gallery or type the code.'
                : 'Close this screen and try again, or pick a photo of the QR code from your gallery.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.78), height: 1.4),
          ),
          if (denied) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: openAppSettings,
              icon: const Icon(Icons.settings_rounded),
              label: const Text('Open settings'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF2C94C),
                foregroundColor: const Color(0xFF10291F),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
