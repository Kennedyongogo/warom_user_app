import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../utils/utils.dart';
import '../../widgets/form_fields/custom_text_field.dart';
import '../../widgets/form_fields/custom_date_picker.dart';
import '../../widgets/form_fields/custom_time_picker.dart';
import '../../widgets/form_fields/my_select_input.dart';
import '../../widgets/buttons/custom_button.dart';
import '../../widgets/cards/section_card.dart';

class SiteVisit extends StatefulWidget {
  final String? applicationId;
  final String? siteVisitId;
  /// When true, open as a read-only details screen (with photos).
  final bool viewOnly;

  const SiteVisit({
    super.key,
    this.applicationId,
    this.siteVisitId,
    this.viewOnly = false,
  });

  @override
  State<SiteVisit> createState() => _SiteVisitState();
}

class _SiteVisitState extends State<SiteVisit> {
  final _formKey = GlobalKey<FormState>();
  final _remarksController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  bool _initialLatLngSet = false;

  final storage = const FlutterSecureStorage();
  final ImagePicker _picker = ImagePicker();

  String? _selectedApplicationId;
  List<Map<String, dynamic>> _applications = [];
  bool _isLoadingApplications = false;
  bool _isCompleted = false;
  bool _isLoading = false;
  bool _locationPermissionGranted = false;
  final List<XFile> _selectedImages = [];
  final List<String> _base64Images = [];
  List<String> _existingPhotoPaths = [];
  String userId = '';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    getUserinfo();
    _initializeLocation();
    // Always load applications for dropdown
    _loadApplications();

    if (widget.siteVisitId != null) {
      _loadSiteVisitData();
    } else {
      // Set default date and time if not editing
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
    }
  }

  Future<void> getUserinfo() async {
    try {
      var token = await storage.read(key: "edams_jwt");
      debugPrint('Token from storage: $token');
      debugPrint('Token length: ${token?.length ?? 0}');

      if (token == null || token.isEmpty) {
        debugPrint('No token found in storage');
        if (mounted) {
          setState(() {
            userId = '';
          });
        }
        return;
      }

      // Check if token looks like a JWT (should have 3 parts separated by dots)
      if (!token.contains('.') || token.split('.').length != 3) {
        debugPrint('Token does not appear to be a valid JWT format');
        if (mounted) {
          setState(() {
            userId = '';
          });
        }
        return;
      }

      var decoded = parseJwt(token);
      debugPrint('Decoded token: $decoded');
      debugPrint('Token keys: ${decoded.keys.toList()}');

      // Extract user ID from token (backend uses lowercase 'id')
      final extractedUserId = decoded['id']?.toString() ?? '';

      debugPrint('Extracted user ID: $extractedUserId');

      if (extractedUserId.isEmpty) {
        debugPrint(
            'Could not extract user ID from token. Available fields: ${decoded.keys.toList()}');
      }

      if (mounted) {
        setState(() {
          userId = extractedUserId;
        });
      }
      debugPrint('Final user ID set: $userId');
    } catch (e) {
      debugPrint('Error getting user info: $e');
      debugPrint('Error stack trace: ${StackTrace.current}');
      if (mounted) {
        setState(() {
          userId = '';
        });
      }
    }
  }

  @override
  void dispose() {
    _remarksController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    // Check location permission status first
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Show permission request dialog
      await _requestLocationPermission();
    } else if (permission == LocationPermission.deniedForever) {
      // Show settings dialog
      _showLocationSettingsDialog();
    } else if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      // Permission granted, get location
      if (mounted) {
        setState(() => _locationPermissionGranted = true);
      }
      await _getCurrentLocation();
    }
  }

  Future<void> _requestLocationPermission() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
            'This app needs location access to automatically record site visit coordinates. '
            'Please grant location permission to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Deny'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Grant Permission'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        setState(() => _locationPermissionGranted = true);
        await _getCurrentLocation();
      } else {
        _showSnackBar(
            'Location permission denied. You can still manually enter location.',
            false);
      }
    }
  }

  void _showLocationSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
            'Location permission is permanently denied. Please enable it in your device settings to use automatic location features.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadApplications() async {
    if (!mounted) return;
    setState(() => _isLoadingApplications = true);
    try {
      final response = await httpGet('applications');
      debugPrint('Applications API Response: $response'); // Debug log

      if (response['success'] == true) {
        // Handle different possible response structuresL
        List<Map<String, dynamic>> applications = [];

        if (response['data'] is List) {
          // If data is already a list
          applications = List<Map<String, dynamic>>.from(response['data']);
        } else if (response['data'] is Map &&
            response['data']['data'] is List) {
          // If data is nested like { data: [...], total: number }
          applications =
              List<Map<String, dynamic>>.from(response['data']['data']);
        } else if (response['applications'] is List) {
          // Alternative response structure
          applications =
              List<Map<String, dynamic>>.from(response['applications']);
        } else {
          debugPrint('Unexpected response structure: ${response.runtimeType}');
          debugPrint('Response keys: ${response.keys.toList()}');
          if (mounted) {
            _showSnackBar('Unexpected API response format', false);
          }
          return;
        }

        if (mounted) {
          setState(() {
            _applications = applications;
          });
        }

        debugPrint('Loaded ${applications.length} applications'); // Debug log
      } else if (response['error'] != null) {
        // Handle authentication or other errors
        if (response['error'].toString().contains('Unauthorized') ||
            response['error'].toString().contains('authentication')) {
          if (mounted) {
            _showSnackBar('Please log in to view applications', false);
          }
        } else {
          if (mounted) {
            _showSnackBar(
                'Failed to load applications: ${response['error']}', false);
          }
        }
      } else {
        if (mounted) {
          _showSnackBar('Failed to load applications: Unknown error', false);
        }
      }
    } catch (e) {
      debugPrint('Error in _loadApplications: $e'); // Debug log
      if (mounted) {
        _showSnackBar('Error loading applications: $e', false);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingApplications = false);
      }
    }
  }

  Future<void> _loadSiteVisitData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // Get JWT token from storage
      final token = await storage.read(key: "edams_jwt");

      if (token == null || token.isEmpty) {
        if (mounted) {
          _showSnackBar("Authentication required. Please login again.", false);
        }
        return;
      }

      debugPrint('=== LOADING SITE VISIT DATA ===');
      debugPrint('Site Visit ID: ${widget.siteVisitId}');
      debugPrint('URL: ${getUrl()}site-visits/${widget.siteVisitId}');

      final response = await http.get(
        Uri.parse('${getUrl()}site-visits/${widget.siteVisitId}'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Site Visit Data Response Status: ${response.statusCode}');
      debugPrint('Site Visit Data Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          final data = responseData['data'];

          // Parse date
          DateTime? visitDate;
          if (data['SiteVisitDate'] != null) {
            try {
              visitDate = DateTime.parse(data['SiteVisitDate']);
            } catch (e) {
              debugPrint('Error parsing date: $e');
            }
          }

          // Parse time
          TimeOfDay? visitTime;
          if (data['SiteVisitTime'] != null) {
            try {
              final timeString = data['SiteVisitTime'].toString();
              final timeParts = timeString.split(':');
              if (timeParts.length >= 2) {
                visitTime = TimeOfDay(
                  hour: int.parse(timeParts[0]),
                  minute: int.parse(timeParts[1]),
                );
              }
            } catch (e) {
              debugPrint('Error parsing time: $e');
            }
          }

          if (mounted) {
            setState(() {
              _selectedApplicationId = data['ApplicationID']?.toString();
              _selectedDate = visitDate ?? DateTime.now();
              _selectedTime = visitTime ?? TimeOfDay.now();
              _remarksController.text = data['SiteVisitReport'] ?? '';
              _isCompleted = data['IsSiteVisitCompleted'] ?? false;
              // A pending visit holds the application's location; the report records where the
              // officer actually is, so only a completed visit's saved position is shown here.
              if (!_initialLatLngSet && _isCompleted) {
                _latitudeController.text = data['Latitude']?.toString() ?? '';
                _longitudeController.text = data['Longitude']?.toString() ?? '';
                _initialLatLngSet = true;
              }
              _existingPhotoPaths = _normalizePhotoList(data['SiteVisitPhotos']);
            });
          }
        } else {
          if (mounted) {
            _showSnackBar(
                'Failed to load site visit data: ${responseData['message'] ?? 'Unknown error'}',
                false);
          }
        }
      } else {
        final errorData = jsonDecode(response.body);
        if (mounted) {
          _showSnackBar(
              'Failed to load site visit data: ${errorData['message'] ?? 'Server error'}',
              false);
        }
      }
    } catch (e) {
      debugPrint('Error loading site visit data: $e');
      if (mounted) {
        _showSnackBar('Error loading site visit data: $e', false);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    if (_isCompleted) {
      _showSnackBar('Completed site visits cannot update location.', false);
      return;
    }

    if (!_locationPermissionGranted) {
      await _requestLocationPermission();
      return;
    }

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          _showSnackBar(
              'Location services are disabled. Please enable them.', false);
        }
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted && !_isCompleted) {
        setState(() {
          _latitudeController.text = position.latitude.toString();
          _longitudeController.text = position.longitude.toString();
        });

        _showSnackBar('Location updated successfully', true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error getting location: $e', false);
      }
    }
  }


  Future<void> _takePicture() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      if (image != null && mounted) {
        setState(() {
          _selectedImages.add(image);
        });
        await _convertAllImagesToBase64();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error taking photo: $e', false);
      }
    }
  }

  void _removeImage(int index) async {
    setState(() {
      _selectedImages.removeAt(index);
    });
    await _convertAllImagesToBase64();
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      debugPrint("✅ Form validation passed");
      setState(() {
        _isLoading = true;
      });
      debugPrint("Loading state set to true");

      var res = await submitSiteVisitData(
        _selectedApplicationId ?? '',
        userId.isNotEmpty ? userId : '',
        _selectedDate!,
        _selectedTime!,
        _remarksController.text,
        _base64Images,
        _latitudeController.text,
        _longitudeController.text,
        widget.siteVisitId,
        _existingPhotoPaths,
      );

      setState(() {
        _isLoading = false;
        _showSnackBar(res.message, res.success);
        if (res.success) {
          Navigator.pop(context, true);
        }
      });
    } else {
      debugPrint("❌ Form validation failed");
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

  Future<String> _convertImageToBase64(XFile file) async {
    List<int> fileBytes = await file.readAsBytes();
    String base64String = base64Encode(fileBytes);
    return base64String;
  }

  Future<void> _convertAllImagesToBase64() async {
    _base64Images.clear();
    debugPrint('=== CONVERTING IMAGES TO BASE64 ===');
    debugPrint('Selected images count: ${_selectedImages.length}');

    for (XFile image in _selectedImages) {
      try {
        String base64Image = await _convertImageToBase64(image);
        _base64Images.add(base64Image);
        debugPrint(
            'Converted image: ${image.name} (${base64Image.length} chars)');
      } catch (e) {
        debugPrint('Error converting image: $e');
      }
    }

    debugPrint('Total base64 images: ${_base64Images.length}');
  }

  bool get _isReadOnly =>
      widget.viewOnly || (widget.siteVisitId != null && _isCompleted);

  List<String> _normalizePhotoList(dynamic raw) {
    if (raw == null) return [];
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return [];
      try {
        return _normalizePhotoList(jsonDecode(trimmed));
      } catch (_) {
        return [trimmed];
      }
    }
    if (raw is! List) return [];
    return raw
        .map((item) {
          if (item == null) return '';
          if (item is String) return item.trim();
          if (item is Map) {
            return (item['url'] ?? item['path'] ?? item['Photo'] ?? '')
                .toString()
                .trim();
          }
          return item.toString().trim();
        })
        .where((p) => p.isNotEmpty)
        .toList();
  }

  String _photoUrl(String path) {
    final p = path.trim();
    if (p.isEmpty) return '';
    if (p.startsWith('http://') ||
        p.startsWith('https://') ||
        p.startsWith('data:image/')) {
      return p;
    }
    final base = getUrl().replaceFirst(RegExp(r'/api/?$'), '/');
    if (p.startsWith('/uploads/')) return '${base.replaceAll(RegExp(r'/$'), '')}$p';
    if (p.startsWith('uploads/')) return '$base$p';
    return '${base}uploads/site-visits/${p.replaceFirst(RegExp(r'^/+'), '')}';
  }

  void _previewNetworkPhoto(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Image unavailable',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF2E7D32);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final showCompleteBar = widget.viewOnly && !_isCompleted;
    final showSubmitBar = !_isReadOnly;
    // Submit: tight gap above sticky bar. View: clear system nav so report isn't clipped.
    final scrollBottomPad = (showCompleteBar || showSubmitBar)
        ? (bottomInset + 28 + 72) / 4
        : bottomInset + 24;
    final title = _isReadOnly
        ? 'Site visit details'
        : widget.siteVisitId != null
            ? 'Complete site visit'
            : 'New site visit';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_isReadOnly)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _isCompleted
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFFFF4E5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: (_isCompleted ? green : const Color(0xFFB54708))
                            .withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isCompleted
                              ? Icons.verified_rounded
                              : Icons.visibility_rounded,
                          color: _isCompleted
                              ? green
                              : const Color(0xFFB54708),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _isCompleted
                                ? 'Completed visit — photos and report below.'
                                : 'Viewing visit details. Tap Complete to submit the report.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _isCompleted
                                  ? const Color(0xFF1B5E20)
                                  : const Color(0xFF9A3412),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(16, 14, 16, scrollBottomPad),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (widget.applicationId == null) ...[
                            SectionCard(
                              title: "Select Application",
                              icon: Icons.app_registration,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  MySelectInput(
                                    value: _selectedApplicationId,
                                    label: "Application",
                                    hint: "Select an application",
                                    items: _applications,
                                    valueKey: 'ID',
                                    displayKey: 'ProjectTitle',
                                    subtitleKey: 'ProjectLocation',
                                    isLoading: _isLoadingApplications,
                                    loadingText: 'Loading applications...',
                                    emptyText: 'No applications found',
                                    enabled: !_isReadOnly,
                                    emptyAction: CustomButton(
                                      text: 'Refresh',
                                      onPressed: _loadApplications,
                                      icon: const Icon(Icons.refresh, size: 16),
                                      isOutlined: true,
                                    ),
                                    onChanged: (String? newValue) {
                                      if (_isReadOnly) return;
                                      setState(() {
                                        _selectedApplicationId = newValue;
                                      });
                                    },
                                    onRefresh: _loadApplications,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please select an application';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                          SectionCard(
                            title: "Visit schedule",
                            icon: Icons.schedule,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CustomDatePicker(
                                  selectedDate: _selectedDate,
                                  label: "Visit Date",
                                  hint: "Select visit date",
                                  enabled: !_isReadOnly,
                                  onDateSelected: (date) {
                                    setState(() => _selectedDate = date);
                                  },
                                ),
                                const SizedBox(height: 16),
                                CustomTimePicker(
                                  selectedTime: _selectedTime,
                                  label: "Visit Time",
                                  hint: "Select visit time",
                                  enabled: !_isReadOnly,
                                  onTimeSelected: (time) {
                                    setState(() => _selectedTime = time);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          SectionCard(
                            title: "Location",
                            icon: Icons.location_on,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomTextField(
                                        controller: _latitudeController,
                                        label: "Latitude",
                                        hint: "0.0000",
                                        keyboardType: TextInputType.number,
                                        enabled: !_isReadOnly,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: CustomTextField(
                                        controller: _longitudeController,
                                        label: "Longitude",
                                        hint: "0.0000",
                                        keyboardType: TextInputType.number,
                                        enabled: !_isReadOnly,
                                      ),
                                    ),
                                  ],
                                ),
                                if (!_isReadOnly) ...[
                                  if (!_locationPermissionGranted) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.blue.shade200,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.location_on,
                                              color: Colors.blue.shade600,
                                              size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Enable location to capture coordinates',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.blue.shade700,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed:
                                                _requestLocationPermission,
                                            child: const Text('Enable'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: _getCurrentLocation,
                                      icon: const Icon(Icons.my_location),
                                      label:
                                          const Text('Get current location'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: green,
                                        side: BorderSide(
                                          color: green.withValues(alpha: 0.4),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          SectionCard(
                            title: "Photos",
                            icon: Icons.photo_camera,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isReadOnly
                                      ? 'Submitted photos from this visit'
                                      : 'Add photos to support your report',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                if (_existingPhotoPaths.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _existingPhotoPaths.length,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                      childAspectRatio: 1,
                                    ),
                                    itemBuilder: (context, index) {
                                      final url = _photoUrl(
                                        _existingPhotoPaths[index],
                                      );
                                      return GestureDetector(
                                        onTap: () =>
                                            _previewNetworkPhoto(url),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              Image.network(
                                                url,
                                                fit: BoxFit.cover,
                                                loadingBuilder: (context,
                                                    child, progress) {
                                                  if (progress == null) {
                                                    return child;
                                                  }
                                                  return Container(
                                                    color: Colors.grey.shade200,
                                                    alignment: Alignment.center,
                                                    child: const SizedBox(
                                                      width: 22,
                                                      height: 22,
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2.2,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                errorBuilder: (_, __, ___) =>
                                                    Container(
                                                  color: Colors.grey.shade200,
                                                  alignment: Alignment.center,
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .broken_image_outlined,
                                                        color: Colors
                                                            .grey.shade500,
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        'Unavailable',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: Colors
                                                              .grey.shade600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                right: 8,
                                                bottom: 8,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.55),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            99),
                                                  ),
                                                  child: const Icon(
                                                    Icons.zoom_in_rounded,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ] else if (_isReadOnly) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF4F7F5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'No photos were submitted with this visit.',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                                if (!_isReadOnly) ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: _takePicture,
                                      icon: const Icon(Icons.camera_alt),
                                      label: const Text('Take photo'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: green,
                                        side: BorderSide(
                                          color: green.withValues(alpha: 0.4),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_selectedImages.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      '${_selectedImages.length} new photo(s)',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                        color: green,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: 88,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: _selectedImages.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(width: 8),
                                        itemBuilder: (context, index) {
                                          return Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Image.file(
                                                  File(_selectedImages[index]
                                                      .path),
                                                  width: 88,
                                                  height: 88,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              Positioned(
                                                top: 4,
                                                right: 4,
                                                child: GestureDetector(
                                                  onTap: () =>
                                                      _removeImage(index),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(4),
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: Colors.black87,
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
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          SectionCard(
                            title: "Report",
                            icon: Icons.note_alt_outlined,
                            child: CustomTextField(
                              controller: _remarksController,
                              label: "Report details",
                              hint: "Enter site visit findings",
                              maxLines: 4,
                              enabled: !_isReadOnly,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (showCompleteBar)
                  Material(
                    elevation: 12,
                    shadowColor: Colors.black26,
                    color: Colors.white,
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          12,
                          16,
                          12 + (bottomInset > 0 ? 0 : 10),
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SiteVisit(
                                    siteVisitId: widget.siteVisitId,
                                    applicationId: widget.applicationId,
                                    viewOnly: false,
                                  ),
                                ),
                              );
                              if (!mounted) return;
                              if (result == true) {
                                if (!context.mounted) return;
                                Navigator.pop(context, true);
                              } else {
                                await _loadSiteVisitData();
                              }
                            },
                            icon: const Icon(Icons.edit_note_rounded),
                            label: const Text(
                              'Complete visit',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                else if (showSubmitBar)
                  Material(
                    elevation: 12,
                    shadowColor: Colors.black26,
                    color: Colors.white,
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          12,
                          16,
                          12 + (bottomInset > 0 ? 0 : 10),
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            onPressed: _isLoading ? null : _handleSubmit,
                            style: FilledButton.styleFrom(
                              backgroundColor: green,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  green.withValues(alpha: 0.55),
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
                                : const Text(
                                    'Submit site visit',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

Future<Message> submitSiteVisitData(
  String applicationId,
  String adminUserId,
  DateTime visitDate,
  TimeOfDay visitTime,
  String report,
  List<String> base64Images,
  String latitude,
  String longitude,
  String? siteVisitId,
  List<String> existingPhotoPaths,
) async {
  try {
    // Get JWT token from storage
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: "edams_jwt");

    if (token == null || token.isEmpty) {
      debugPrint("No JWT token found");
      return Message(
        data: null,
        message: "Authentication required. Please login again.",
        success: false,
      );
    }

    debugPrint('=== PREPARING REQUEST BODY ===');
    debugPrint('Base64 images count: ${base64Images.length}');
    debugPrint(
        'Base64 images preview: ${base64Images.isNotEmpty ? "${base64Images[0].substring(0, 50)}..." : "No images"}');

    // For updates, include existing photos + new photos
    // For creates, only include new photos
    List<String> allPhotos = siteVisitId != null
        ? [...existingPhotoPaths, ...base64Images]
        : base64Images;

    final requestBody = jsonEncode(<String, dynamic>{
      'ApplicationID': applicationId,
      'AdminUserID': adminUserId.isNotEmpty ? adminUserId : null,
      'SiteVisitDate': visitDate.toIso8601String().split('T')[0],
      'SiteVisitTime':
          '${visitTime.hour.toString().padLeft(2, '0')}:${visitTime.minute.toString().padLeft(2, '0')}',
      'SiteVisitPhotos': allPhotos,
      'SiteVisitReport': report.trim(),
      'IsSiteVisitCompleted': true,
      'Latitude':
          latitude.trim().isEmpty ? null : double.tryParse(latitude.trim()),
      'Longitude':
          longitude.trim().isEmpty ? null : double.tryParse(longitude.trim()),
    });

    debugPrint("=== API REQUEST ===");
    debugPrint(
        "URL: ${getUrl()}site-visits${siteVisitId != null ? '/$siteVisitId' : ''}");
    debugPrint(
        "Headers: Content-Type: application/json, Authorization: Bearer [TOKEN]");
    debugPrint("Request Body: $requestBody");

    final response = siteVisitId != null
        ? await http.put(
            Uri.parse('${getUrl()}site-visits/$siteVisitId'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token',
            },
            body: requestBody,
          )
        : await http.post(
            Uri.parse('${getUrl()}site-visits'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token',
            },
            body: requestBody,
          );

    debugPrint("=== API RESPONSE ===");
    debugPrint("Status Code: ${response.statusCode}");
    debugPrint("Response Body: ${response.body}");
    debugPrint("Response Headers: ${response.headers}");

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      debugPrint("✅ Success response received");
      return Message.fromJson(responseData);
    } else {
      debugPrint("❌ Error response received");
      debugPrint("Error data: $responseData");
      return Message(
        data: null,
        message:
            responseData['message'] ?? "Server error! Contact administrator.",
        success: false,
      );
    }
  } catch (e) {
    debugPrint("Error submitting site visit data: $e");
    return Message(
      data: null,
      message: "Connection failed! Check your internet connection. Error: $e",
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

  // Helper getter to check if operation was successful
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
