import 'dart:convert';
import 'dart:io';
import 'package:edams_mobile/utils/illegal_report_draft.dart';
import 'package:edams_mobile/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import '../../widgets/form_fields/custom_text_field.dart';
import 'illegal_reports_page.dart';

class IllegalDevelopmentReport extends StatefulWidget {
  final Map<String, dynamic>? existingReport;
  final bool restoreDraft;

  const IllegalDevelopmentReport({
    super.key,
    this.existingReport,
    this.restoreDraft = false,
  });

  @override
  State<IllegalDevelopmentReport> createState() =>
      _IllegalDevelopmentReportState();
}

class _IllegalDevelopmentReportState extends State<IllegalDevelopmentReport> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _reporterNameController = TextEditingController();
  final _reporterEmailController = TextEditingController();
  final _reporterPhoneController = TextEditingController();

  final storage = const FlutterSecureStorage();

  double? _capturedLatitude;
  double? _capturedLongitude;

  String userId = '';
  bool _isLoggedIn = false;
  bool _isLoading = false;
  bool _locationPermissionGranted = false;
  bool _isCapturingLocation = false;
  final List<XFile> _selectedImages = [];
  final List<String> _base64Images = [];

  bool get _isEditing => widget.existingReport != null;
  bool get _hasCoordinates =>
      _capturedLatitude != null && _capturedLongitude != null;
  bool get _useAccountContact => _isLoggedIn && !_isEditing;

  String get _autoLocationLabel {
    if (!_hasCoordinates) return 'GPS location pending';
    return '${_capturedLatitude!.toStringAsFixed(5)}, ${_capturedLongitude!.toStringAsFixed(5)}';
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await getUserinfo();
    _initializeLocation();
    _prefillIfEditing();
    if (widget.restoreDraft) {
      await _restoreDraft();
    }
  }

  Future<void> _restoreDraft() async {
    final draft = await IllegalReportDraft.load();
    if (draft == null || !mounted) return;
    setState(() {
      _titleController.text = draft['title']?.toString() ?? '';
      _descriptionController.text = draft['description']?.toString() ?? '';
      // Keep account contact when reporting as a signed-in admin.
      if (!_useAccountContact) {
        _reporterNameController.text = draft['name']?.toString() ?? '';
        _reporterEmailController.text = draft['email']?.toString() ?? '';
        _reporterPhoneController.text = draft['phone']?.toString() ?? '';
      }
      final lat = draft['latitude'];
      final lng = draft['longitude'];
      if (lat != null) _capturedLatitude = double.tryParse(lat.toString());
      if (lng != null) _capturedLongitude = double.tryParse(lng.toString());
    });

    // Photos chosen before Android closed the app, plus the one the camera returned to the dead app.
    final saved = ((draft['images'] as List?) ?? const [])
        .map((p) => p.toString())
        .where((p) => p.isNotEmpty && File(p).existsSync())
        .map((p) => XFile(p))
        .toList();
    final recovered = await _recoverLostPhotos();
    final known = saved.map((f) => f.path).toSet();
    final photos = [...saved, ...recovered.where((f) => known.add(f.path))];
    if (photos.isEmpty || !mounted) return;

    setState(() {
      _selectedImages
        ..clear()
        ..addAll(photos);
    });
    await _convertAllImagesToBase64();
    await _saveDraft();
    if (recovered.isNotEmpty) {
      _showSnackBar('Your photo was kept. Continue your report.', true);
    }
  }

  /// Android may close the app while the camera is open; the picker keeps the photo until asked.
  Future<List<XFile>> _recoverLostPhotos() async {
    if (!Platform.isAndroid) return const [];
    try {
      final response = await ImagePicker().retrieveLostData();
      if (response.isEmpty) return const [];
      return response.files ?? (response.file != null ? [response.file!] : const []);
    } catch (_) {
      return const [];
    }
  }

  Future<void> _saveDraft() => IllegalReportDraft.save(
        title: _titleController.text,
        description: _descriptionController.text,
        name: _reporterNameController.text,
        email: _reporterEmailController.text,
        phone: _reporterPhoneController.text,
        latitude: _capturedLatitude,
        longitude: _capturedLongitude,
        imagePaths: _selectedImages.map((f) => f.path).toList(),
      );

  Future<void> _persistDraftBeforeMedia() async {
    await _saveDraft();
    await IllegalReportDraft.markResumePending();
  }

  /// The picker returned normally: keep the draft (with the new photos) but don't reopen on next launch.
  Future<void> _afterMedia() async {
    await IllegalReportDraft.clearResumePending();
    await _saveDraft();
  }

  Future<bool> _ensureCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isGranted) return true;
    status = await Permission.camera.request();
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied && mounted) {
      _showSnackBar('Enable camera permission in settings to take photos.', false);
      await openAppSettings();
    } else if (mounted) {
      _showSnackBar('Camera permission is required to take photos.', false);
    }
    return false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _reporterNameController.dispose();
    _reporterEmailController.dispose();
    _reporterPhoneController.dispose();
    super.dispose();
  }

  Future<void> getUserinfo() async {
    var token = await storage.read(key: "edams_jwt");
    if (token == null || token.isEmpty) return;

    var decoded = parseJwt(token);
    final id = decoded['id']?.toString() ?? '';
    if (!mounted) return;

    setState(() {
      userId = id;
      _isLoggedIn = id.isNotEmpty;
      if (_useAccountContact) {
        _reporterNameController.text = decoded['name']?.toString() ?? '';
        _reporterEmailController.text = decoded['email']?.toString() ?? '';
      }
    });

    if (_isEditing && widget.existingReport?['ReporterID'] != null) {
      setState(() {
        userId = widget.existingReport!['ReporterID'].toString();
      });
    }

    if (!_useAccountContact) return;

    try {
      final response = await http.get(
        Uri.parse('${getUrl()}admin-users/me/profile'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode != 200 || !mounted) return;
      final body = jsonDecode(response.body);
      final profile = body is Map<String, dynamic>
          ? (body['data'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(body['data'])
              : Map<String, dynamic>.from(body))
          : <String, dynamic>{};
      setState(() {
        final name = profile['Name']?.toString();
        final email = profile['Email']?.toString();
        final phone = profile['PhoneNumber']?.toString();
        if (name != null && name.isNotEmpty) {
          _reporterNameController.text = name;
        }
        if (email != null && email.isNotEmpty) {
          _reporterEmailController.text = email;
        }
        if (phone != null && phone.isNotEmpty) {
          _reporterPhoneController.text = phone;
        }
      });
    } catch (_) {
      // JWT name/email already applied; phone may stay empty.
    }
  }

  void _prefillIfEditing() {
    final report = widget.existingReport;
    if (report == null) return;

    _titleController.text = report['Title']?.toString() ?? '';
    _descriptionController.text = report['Description']?.toString() ?? '';

    final lat = report['Latitude'];
    final lng = report['Longitude'];
    if (lat != null && lng != null) {
      _capturedLatitude = double.tryParse(lat.toString());
      _capturedLongitude = double.tryParse(lng.toString());
    }

    final contactInfo = report['ReporterContactInfo'];
    if (contactInfo == null) return;

    try {
      Map<String, dynamic> infoMap;
      if (contactInfo is Map) {
        infoMap = contactInfo.map<String, dynamic>(
            (key, value) => MapEntry(key.toString(), value));
      } else if (contactInfo is String && contactInfo.isNotEmpty) {
        infoMap = jsonDecode(contactInfo);
      } else {
        infoMap = {};
      }
      _reporterNameController.text = infoMap['name']?.toString() ?? '';
      _reporterEmailController.text = infoMap['email']?.toString() ?? '';
      _reporterPhoneController.text = infoMap['phone']?.toString() ?? '';
    } catch (_) {}
  }

  Future<void> _initializeLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await _requestLocationPermission();
    } else if (permission == LocationPermission.deniedForever) {
      _showLocationSettingsDialog();
    } else if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      if (mounted) setState(() => _locationPermissionGranted = true);
      await _getCurrentLocation();
    }
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      if (mounted) setState(() => _locationPermissionGranted = true);
      await _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    if (mounted) setState(() => _isCapturingLocation = true);
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _capturedLatitude = position.latitude;
          _capturedLongitude = position.longitude;
          _isCapturingLocation = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isCapturingLocation = false);
    }
  }

  void _showLocationSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Location needed'),
        content: const Text(
          'Turn on location permission so we can pin this report on the map automatically.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Geolocator.openAppSettings();
            },
            child: const Text('Open settings'),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    if (mounted) {
      setState(() {
        _selectedImages.clear();
        _base64Images.clear();
      });
    }
  }

  void _showSnackBar(String message, bool isSuccess) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isSuccess ? getColor('primary') : getColor('error'),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<String> _convertImageToBase64(XFile file) async {
    return base64Encode(await file.readAsBytes());
  }

  Future<void> _convertAllImagesToBase64() async {
    _base64Images.clear();
    for (final image in _selectedImages) {
      try {
        _base64Images.add(await _convertImageToBase64(image));
      } catch (_) {}
    }
  }

  Future<void> _pickImageFromCamera() async {
    if (!await _ensureCameraPermission()) return;
    try {
      // Persist form so Android process death (common when camera opens) does not lose work.
      await _persistDraftBeforeMedia();
      final image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1280,
        maxHeight: 1280,
        requestFullMetadata: false,
      );
      if (image != null && mounted) {
        setState(() => _selectedImages.add(image));
        await _convertAllImagesToBase64();
      }
      await _afterMedia();
    } catch (e) {
      if (mounted) _showSnackBar('Error taking photo: $e', false);
    }
  }

  Future<void> _pickImageFromGallery() async {
    // The system photo picker grants access to the chosen photos only; no permission prompt.
    try {
      await _persistDraftBeforeMedia();
      final images = await ImagePicker().pickMultiImage(
        imageQuality: 70,
        maxWidth: 1280,
        maxHeight: 1280,
        requestFullMetadata: false,
      );
      if (images.isNotEmpty && mounted) {
        setState(() => _selectedImages.addAll(images));
        await _convertAllImagesToBase64();
      }
      await _afterMedia();
    } catch (e) {
      if (mounted) _showSnackBar('Error picking images: $e', false);
    }
  }

  void _removeImage(int index) async {
    setState(() => _selectedImages.removeAt(index));
    await _convertAllImagesToBase64();
    await _saveDraft();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_hasCoordinates) {
      _showSnackBar(
        'Please enable GPS so we can capture the report location.',
        false,
      );
      if (!_locationPermissionGranted) {
        await _requestLocationPermission();
      } else {
        await _getCurrentLocation();
      }
      return;
    }

    setState(() => _isLoading = true);

    final locationLabel =
        'GPS ${_capturedLatitude!.toStringAsFixed(6)}, ${_capturedLongitude!.toStringAsFixed(6)}';

    final Message res;
    if (_isEditing) {
      res = await updateReportData(
        widget.existingReport?['ID']?.toString() ?? '',
        userId,
        _titleController.text,
        _descriptionController.text,
        locationLabel,
        _capturedLatitude,
        _capturedLongitude,
        _base64Images,
        _reporterNameController.text,
        _reporterEmailController.text,
        _reporterPhoneController.text,
      );
    } else {
      res = await submitReportData(
        userId,
        _titleController.text,
        _descriptionController.text,
        locationLabel,
        _capturedLatitude,
        _capturedLongitude,
        _base64Images,
        _reporterNameController.text,
        _reporterEmailController.text,
        _reporterPhoneController.text,
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
    _showSnackBar(res.message, res.success);
    if (res.success) {
      await IllegalReportDraft.clear();
      if (!mounted) return;
      if (!_isEditing) _resetForm();
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = getColor('primary');
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit report' : 'Report illegal development'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_rounded),
            tooltip: 'My reports',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const IllegalReportsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeroBanner(primary: primary),
                    const SizedBox(height: 16),
                    _GpsCard(
                      primary: primary,
                      hasCoordinates: _hasCoordinates,
                      isCapturing: _isCapturingLocation,
                      permissionGranted: _locationPermissionGranted,
                      label: _autoLocationLabel,
                      onEnable: _requestLocationPermission,
                      onRetry: _getCurrentLocation,
                    ),
                    const SizedBox(height: 16),
                    _SectionShell(
                      title: 'What happened?',
                      subtitle: 'A clear title and short description help officers respond.',
                      icon: Icons.edit_note_rounded,
                      child: Column(
                        children: [
                          CustomTextField(
                            controller: _titleController,
                            label: 'Title',
                            hint: 'e.g. Building without permit near junction',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a title';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          CustomTextField(
                            controller: _descriptionController,
                            label: 'Description',
                            hint: 'Describe what you observed',
                            maxLines: 4,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a description';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionShell(
                      title: 'Photos',
                      subtitle: 'Optional — add clear photos of the site.',
                      icon: Icons.photo_camera_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _PhotoAction(
                                  icon: Icons.photo_camera_rounded,
                                  label: 'Camera',
                                  onTap: _pickImageFromCamera,
                                  primary: primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _PhotoAction(
                                  icon: Icons.photo_library_rounded,
                                  label: 'Gallery',
                                  onTap: _pickImageFromGallery,
                                  primary: primary,
                                ),
                              ),
                            ],
                          ),
                          if (_selectedImages.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Text(
                              '${_selectedImages.length} photo${_selectedImages.length == 1 ? '' : 's'} attached',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: primary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 92,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _selectedImages.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 10),
                                itemBuilder: (context, index) {
                                  return Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Image.file(
                                          File(_selectedImages[index].path),
                                          width: 92,
                                          height: 92,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 6,
                                        right: 6,
                                        child: GestureDetector(
                                          onTap: () => _removeImage(index),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(
                                                alpha: 0.65,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (_useAccountContact) ...[
                      const SizedBox(height: 16),
                      _SectionShell(
                        title: 'Contact',
                        subtitle: 'Taken from your admin account.',
                        icon: Icons.verified_user_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _AccountContactRow(
                              icon: Icons.person_outline,
                              label: 'Name',
                              value: _reporterNameController.text.isEmpty
                                  ? '—'
                                  : _reporterNameController.text,
                            ),
                            const SizedBox(height: 10),
                            _AccountContactRow(
                              icon: Icons.email_outlined,
                              label: 'Email',
                              value: _reporterEmailController.text.isEmpty
                                  ? '—'
                                  : _reporterEmailController.text,
                            ),
                            const SizedBox(height: 10),
                            _AccountContactRow(
                              icon: Icons.phone_outlined,
                              label: 'Phone',
                              value: _reporterPhoneController.text.isEmpty
                                  ? '—'
                                  : _reporterPhoneController.text,
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 16),
                      _SectionShell(
                        title: 'Contact (optional)',
                        subtitle: 'So officers can follow up if needed.',
                        icon: Icons.person_outline_rounded,
                        child: Column(
                          children: [
                            CustomTextField(
                              controller: _reporterNameController,
                              label: 'Name',
                              hint: 'Your full name',
                            ),
                            const SizedBox(height: 14),
                            CustomTextField(
                              controller: _reporterEmailController,
                              label: 'Email',
                              hint: 'you@example.com',
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  if (!RegExp(
                                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                  ).hasMatch(value)) {
                                    return 'Enter a valid email';
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            CustomTextField(
                              controller: _reporterPhoneController,
                              label: 'Phone',
                              hint: '07XXXXXXXX',
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  if (!RegExp(r'^[0-9+\-\s()]+$')
                                      .hasMatch(value)) {
                                    return 'Enter a valid phone number';
                                  }
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Sticky submit bar — clears system navigation / gesture bar
            Material(
              elevation: 12,
              shadowColor: Colors.black26,
              color: Colors.white,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + (bottomInset > 0 ? 0 : 8)),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: FilledButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: primary.withValues(alpha: 0.55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isEditing ? 'Update report' : 'Submit report',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AccountContactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final Color primary;
  const _HeroBanner({required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary,
            Color.lerp(primary, const Color(0xFF064E3B), 0.35)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.report_gmailerrorred_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Help keep Nyamira orderly',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Your GPS pins the site. Just tell us what you saw.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.35,
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

class _GpsCard extends StatelessWidget {
  final Color primary;
  final bool hasCoordinates;
  final bool isCapturing;
  final bool permissionGranted;
  final String label;
  final VoidCallback onEnable;
  final VoidCallback onRetry;

  const _GpsCard({
    required this.primary,
    required this.hasCoordinates,
    required this.isCapturing,
    required this.permissionGranted,
    required this.label,
    required this.onEnable,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final Color tone = hasCoordinates
        ? primary
        : isCapturing
            ? const Color(0xFF1565C0)
            : const Color(0xFFE65100);
    final Color soft = tone.withValues(alpha: 0.1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tone.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: soft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: isCapturing
                ? Padding(
                    padding: const EdgeInsets.all(11),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: tone,
                    ),
                  )
                : Icon(
                    hasCoordinates
                        ? Icons.my_location_rounded
                        : Icons.location_searching_rounded,
                    color: tone,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCapturing
                      ? 'Capturing GPS…'
                      : hasCoordinates
                          ? 'Location captured'
                          : 'Location not ready',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: tone,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasCoordinates
                      ? label
                      : 'We use your phone GPS — nothing to type.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          if (!permissionGranted)
            TextButton(
              onPressed: onEnable,
              child: const Text('Enable'),
            )
          else if (!hasCoordinates && !isCapturing)
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}

class _SectionShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _SectionShell({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final primary = getColor('primary');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _PhotoAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color primary;

  const _PhotoAction({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: primary.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: primary.withValues(alpha: 0.18)),
          ),
          child: Column(
            children: [
              Icon(icon, color: primary, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<Message> submitReportData(
  String reporterId,
  String title,
  String description,
  String location,
  double? latitude,
  double? longitude,
  List<String> base64Images,
  String reporterName,
  String reporterEmail,
  String reporterPhone,
) async {
  try {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: "edams_jwt");

    final requestBody = jsonEncode(<String, dynamic>{
      'ReporterID': reporterId,
      'Title': title,
      'Description': description,
      'Location': location.trim(),
      'ViolationType': 'Other',
      'Severity': 'Medium',
      'Priority': 'Normal',
      'Photos': base64Images,
      'ReporterContactInfo': {
        'name': reporterName.trim().isEmpty ? null : reporterName.trim(),
        'email': reporterEmail.trim().isEmpty ? null : reporterEmail.trim(),
        'phone': reporterPhone.trim().isEmpty ? null : reporterPhone.trim(),
      },
      'Latitude': latitude,
      'Longitude': longitude,
    });

    final response = await http.post(
      Uri.parse('${getUrl()}illegal-development'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: requestBody,
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Message.fromJson(responseData);
    }
    return Message(
      data: null,
      message:
          responseData['message'] ?? "Server error! Contact administrator.",
      success: false,
    );
  } catch (e) {
    return Message(
      data: null,
      message: "Connection failed! Check your internet connection. Error: $e",
      success: false,
    );
  }
}

Future<Message> updateReportData(
  String reportId,
  String reporterId,
  String title,
  String description,
  String location,
  double? latitude,
  double? longitude,
  List<String> base64Images,
  String reporterName,
  String reporterEmail,
  String reporterPhone,
) async {
  if (reportId.isEmpty) {
    return Message(
      data: null,
      message: 'Missing report identifier.',
      success: false,
    );
  }

  try {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: "edams_jwt");

    final Map<String, dynamic> payload = {
      'ReporterID': reporterId.isEmpty ? null : reporterId,
      'Title': title,
      'Description': description,
      'Location': location.trim(),
      'ViolationType': 'Other',
      'Severity': 'Medium',
      'Priority': 'Normal',
      'ReporterContactInfo': {
        'name': reporterName.trim().isEmpty ? null : reporterName.trim(),
        'email': reporterEmail.trim().isEmpty ? null : reporterEmail.trim(),
        'phone': reporterPhone.trim().isEmpty ? null : reporterPhone.trim(),
      },
      'Latitude': latitude,
      'Longitude': longitude,
    };

    if (base64Images.isNotEmpty) {
      payload['Photos'] = base64Images;
    }

    final response = await http.put(
      Uri.parse('${getUrl()}illegal-development/$reportId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Message.fromJson(responseData);
    }
    return Message(
      data: null,
      message:
          responseData['message'] ?? 'Failed to update illegal development.',
      success: false,
    );
  } catch (e) {
    return Message(
      data: null,
      message: 'Connection failed! Check your internet connection. Error: $e',
      success: false,
    );
  }
}

class Message {
  final dynamic data;
  final String message;
  final bool success;

  Message({
    required this.data,
    required this.message,
    required this.success,
  });

  bool get isSuccess => success;

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      data: json['data'],
      message: json['message'] ??
          (json['success']
              ? "Operation completed successfully"
              : "An error occurred"),
      success: json['success'] ?? false,
    );
  }
}
