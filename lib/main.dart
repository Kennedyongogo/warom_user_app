import 'package:edams_mobile/screens/Illegal%20Development%20Report/illegal_development_report.dart';
import 'package:edams_mobile/screens/landing/landing_page.dart';
import 'package:edams_mobile/utils/illegal_report_draft.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'utils/utils.dart';

final GlobalKey<NavigatorState> edamsNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Hold the first frame so Android's launch screen stays up while the saved login is checked.
  WidgetsFlutterBinding.ensureInitialized().deferFirstFrame();
  runApp(const EDAMSMobileApp());
}

class EDAMSMobileApp extends StatelessWidget {
  const EDAMSMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nyamira EDAMS',
      navigatorKey: edamsNavigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: const Color(0xFF2E7D32),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _resumeChecked = false;
  bool _firstFrameAllowed = false;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkAuthState().whenComplete(_showFirstFrame);
  }

  void _showFirstFrame() {
    if (_firstFrameAllowed) return;
    _firstFrameAllowed = true;
    WidgetsBinding.instance.allowFirstFrame();
  }

  Future<void> _checkAuthState() async {
    String? token;
    try {
      token = await _secureStorage
          .read(key: 'edams_jwt')
          .timeout(const Duration(seconds: 4));
    } catch (_) {
      token = null;
    }

    if (token != null && token.isNotEmpty) {
      try {
        // Parse JWT to check if it's valid
        final tokenData = parseJwt(token);
        if (tokenData['error'] == null) {
          // Check if token is expired
          final exp = tokenData['exp'];
          if (exp != null) {
            final expiryTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
            if (DateTime.now().isBefore(expiryTime)) {
              if (mounted) {
                setState(() => _isLoading = false);
                _scheduleResumeCheck();
              }
              return;
            }
          }
        }
      } catch (e) {
        // Token is invalid, clear it
        await _secureStorage.delete(key: 'edams_jwt');
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
      _scheduleResumeCheck();
    }
  }

  void _scheduleResumeCheck() {
    if (_resumeChecked) return;
    _resumeChecked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeResumeIllegalReport();
    });
  }

  Future<void> _maybeResumeIllegalReport() async {
    final shouldResume = await IllegalReportDraft.consumeResumePending();
    if (!shouldResume) return;
    // Give the first frame time so the root navigator is ready.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    edamsNavigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => const IllegalDevelopmentReport(restoreDraft: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Never painted: the first frame is held until the check finishes. Matches the launch screen colour.
      return const ColoredBox(color: Color(0xFF2E7D32));
    }
    return const LandingPage();
  }
}
