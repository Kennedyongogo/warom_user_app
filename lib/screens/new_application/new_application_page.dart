import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../utils/utils.dart';
import '../../widgets/form_fields/custom_text_field.dart';
import '../../widgets/form_fields/my_select_input.dart';
import '../../widgets/form_fields/my_text_label.dart';
import '../../widgets/buttons/custom_button.dart';
import '../../widgets/cards/section_card.dart';

class NewApplicationPage extends StatefulWidget {
  const NewApplicationPage({super.key});

  @override
  State<NewApplicationPage> createState() => _NewApplicationPageState();
}

class _NewApplicationPageState extends State<NewApplicationPage> {
  final _formKey = GlobalKey<FormState>();
  
  int _currentStep = 0;
  bool _isLoading = false;
  
  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _areaController = TextEditingController();
  final _parcelNumberController = TextEditingController();
  
  // Form data
  String? _selectedApplicationType;
  String? _selectedZoningCategory;
  final List<XFile> _selectedImages = [];
  final List<String> _uploadedDocuments = [];
  final List<String> _base64Images = [];
  final List<String> _base64Documents = [];
  final Map<String, dynamic> _formData = {};

  List<Map<String, dynamic>> _applicationTypes = [];
  List<Map<String, dynamic>> _zoningCategories = [];
  bool _isLoadingApplicationTypes = false;
  bool _isLoadingZoningCategories = false;

  @override
  void initState() {
    super.initState();
    _loadApplicationTypes();
    _loadZoningCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _areaController.dispose();
    _parcelNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
    final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
        await _convertAllImagesToBase64();
      }
    } catch (e) {
      _showSnackBar('Error picking images: $e', false);
    }
  }

  Future<void> _takePicture() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
    if (image != null) {
      setState(() {
          _selectedImages.add(image);
      });
        await _convertAllImagesToBase64();
      }
    } catch (e) {
      _showSnackBar('Error taking photo: $e', false);
    }
  }

  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      setState(() {
        _uploadedDocuments.add(result.files.single.path!);
      });
      await _convertAllDocumentsToBase64();
    }
  }

  void _removeImage(int index) async {
    setState(() {
      _selectedImages.removeAt(index);
    });
    await _convertAllImagesToBase64();
  }

  void _removeDocument(int index) async {
    setState(() {
      _uploadedDocuments.removeAt(index);
    });
    await _convertAllDocumentsToBase64();
  }

  Future<String> _convertImageToBase64(XFile file) async {
    List<int> fileBytes = await file.readAsBytes();
    String base64String = base64Encode(fileBytes);
    return base64String;
  }

  Future<String> _convertDocumentToBase64(String filePath) async {
    File file = File(filePath);
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

  Future<void> _convertAllDocumentsToBase64() async {
    _base64Documents.clear();
    debugPrint('=== CONVERTING DOCUMENTS TO BASE64 ===');
    debugPrint('Selected documents count: ${_uploadedDocuments.length}');

    for (String documentPath in _uploadedDocuments) {
      try {
        String base64Document = await _convertDocumentToBase64(documentPath);
        _base64Documents.add(base64Document);
        debugPrint(
            'Converted document: ${documentPath.split('/').last} (${base64Document.length} chars)');
      } catch (e) {
        debugPrint('Error converting document: $e');
      }
    }

    debugPrint('Total base64 documents: ${_base64Documents.length}');
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

  Future<void> _loadApplicationTypes() async {
    setState(() => _isLoadingApplicationTypes = true);
    try {
      // Get JWT token from storage
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: "edams_jwt");

      if (token == null || token.isEmpty) {
        _showSnackBar("Authentication required. Please login again.", false);
        setState(() => _isLoadingApplicationTypes = false);
        return;
      }

      final response = await http.get(
        Uri.parse('${getUrl()}application-types'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint(
          'Application Types API Response Status: ${response.statusCode}');
      debugPrint('Application Types API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] is List) {
          setState(() {
            _applicationTypes = List<Map<String, dynamic>>.from(
                responseData['data'].map((item) => {
                      'ID': item['ID']?.toString(),
                      'Name': item['Name']?.toString() ?? 'Unknown',
                      'Description': item['Description']?.toString() ??
                          'No description available',
                    }));
          });
          debugPrint('Loaded ${_applicationTypes.length} application types');
        } else {
          _showSnackBar('Failed to load application types', false);
        }
      } else {
        _showSnackBar('Failed to load application types', false);
      }
    } catch (e) {
      debugPrint('Error loading application types: $e');
      _showSnackBar('Error loading application types: $e', false);
    } finally {
      setState(() => _isLoadingApplicationTypes = false);
    }
  }

  Future<void> _loadZoningCategories() async {
    setState(() => _isLoadingZoningCategories = true);
    try {
      // For now, use hardcoded zoning categories since we don't have an API endpoint
      setState(() {
        _zoningCategories = [
          {
            'ID': 'residential-uuid-1',
            'Name': 'Residential',
            'Description': 'Housing and related uses'
          },
          {
            'ID': 'commercial-uuid-2',
            'Name': 'Commercial',
            'Description': 'Business and retail uses'
          },
          {
            'ID': 'industrial-uuid-3',
            'Name': 'Industrial',
            'Description': 'Manufacturing and industrial uses'
          },
          {
            'ID': 'agricultural-uuid-4',
            'Name': 'Agricultural',
            'Description': 'Farming and agricultural uses'
          },
          {
            'ID': 'mixed-use-uuid-5',
            'Name': 'Mixed Use',
            'Description': 'Combination of different uses'
          },
        ];
      });
      debugPrint(
          'Loaded ${_zoningCategories.length} zoning categories (hardcoded)');
    } catch (e) {
      debugPrint('Error loading zoning categories: $e');
      _showSnackBar('Error loading zoning categories: $e', false);
    } finally {
      setState(() => _isLoadingZoningCategories = false);
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Get JWT token from storage
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: "edams_jwt");

      if (token == null || token.isEmpty) {
        _showSnackBar("Authentication required. Please login again.", false);
        setState(() => _isLoading = false);
        return;
      }

      // Prepare application data (matching API expectations)
      final applicationData = {
        'ApplicationTypeID': _selectedApplicationType,
        'ParcelNumber': _parcelNumberController.text, // Required field
        'ProjectTitle': _titleController.text,
        'ProjectDescription': _descriptionController.text,
        'ProjectLocation': _locationController.text,
        'ProjectArea': double.tryParse(_areaController.text) ?? 0.0,
        'ZoningCategory': _selectedZoningCategory,
        'Photos': _base64Images, // Send base64 encoded images
        'Documents': _base64Documents, // Send base64 encoded documents
        'Status': 'Pending', // Set initial status
        ..._formData,
      };

      debugPrint('=== SUBMITTING APPLICATION ===');
      debugPrint('Application Data Keys: ${applicationData.keys.toList()}');
      debugPrint('Parcel Number: ${_parcelNumberController.text}');
      debugPrint('Application Type ID: $_selectedApplicationType');
      debugPrint('Base64 Images Count: ${_base64Images.length}');
      debugPrint('Base64 Documents Count: ${_base64Documents.length}');
      debugPrint('Endpoint: applications');

      // Use direct HTTP call like site_visit.dart does
      final response = await http.post(
        Uri.parse('${getUrl()}applications'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(applicationData),
      );

      debugPrint('=== API RESPONSE ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar('Application submitted successfully!', true);
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        debugPrint('Application submission failed: ${responseData['message']}');
        _showSnackBar(
            responseData['message'] ?? 'Failed to submit application', false);
      }
    } catch (e) {
      debugPrint('Error submitting application: $e');
      _showSnackBar('An error occurred. Please try again. Error: $e', false);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _nextStep() {
          if (_currentStep < 3) {
            setState(() {
              _currentStep++;
            });
          } else {
            _submitApplication();
          }
  }

  void _previousStep() {
          if (_currentStep > 0) {
            setState(() {
              _currentStep--;
            });
          }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Application'),
        backgroundColor: getColor('primary'),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_currentStep > 0)
            TextButton(
              onPressed: _previousStep,
              child: const Text(
                'Previous',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Step Indicator
                    SectionCard(
                      title: "Application Progress",
                      icon: Icons.timeline,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildStepIndicator(0, "Type"),
                              ),
                              Expanded(
                                child: _buildStepIndicator(1, "Basic Info"),
                              ),
                              Expanded(
                                child: _buildStepIndicator(2, "Location"),
                              ),
                              Expanded(
                                child: _buildStepIndicator(3, "Documents"),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          MyTextLabel(
                            text: 'Step ${_currentStep + 1} of 4',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: getColor('primary'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Step Content
                    _buildCurrentStepContent(),

                    const SizedBox(height: 24),

                    // Navigation Buttons
                    Row(
                      children: [
                        if (_currentStep > 0)
                          Expanded(
                            child: CustomButton(
                              text: 'Previous',
                              onPressed: _previousStep,
                              isOutlined: true,
                              icon: const Icon(Icons.arrow_back, size: 16),
                            ),
                          ),
                        if (_currentStep > 0) const SizedBox(width: 16),
                        Expanded(
                          flex: _currentStep == 0 ? 1 : 1,
                          child: CustomButton(
                            text: _currentStep == 3
                                ? 'Submit Application'
                                : 'Next',
                            onPressed: _isLoading ? null : _nextStep,
                            isLoading: _isLoading,
                            icon: _currentStep == 3
                                ? const Icon(Icons.check, size: 16)
                                : const Icon(Icons.arrow_forward, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStepIndicator(int stepIndex, String label) {
    final isActive = stepIndex == _currentStep;
    final isCompleted = stepIndex < _currentStep;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted
                ? getColor('primary')
                : isActive
                    ? getColor('primary')
                    : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted ? Icons.check : Icons.circle,
            color: Colors.white,
            size: isCompleted ? 20 : 16,
          ),
        ),
        const SizedBox(height: 4),
        MyTextLabel(
          text: label,
          fontSize: 10,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          color: isActive || isCompleted
              ? getColor('primary')
              : Colors.grey.shade600,
        ),
      ],
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildApplicationTypeStep();
      case 1:
        return _buildBasicInfoStep();
      case 2:
        return _buildLocationStep();
      case 3:
        return _buildDocumentsStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildApplicationTypeStep() {
    return SectionCard(
      title: "Application Type",
      icon: Icons.app_registration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MyTextLabel(
            text: "Select the type of application you want to submit:",
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
          const SizedBox(height: 16),
          if (_isLoadingApplicationTypes)
            const Center(
              child: CircularProgressIndicator(),
            )
          else if (_applicationTypes.isEmpty)
            const Center(
              child: MyTextLabel(
                text: "No application types available",
                fontSize: 14,
                color: Colors.grey,
              ),
            )
          else
            ..._applicationTypes.map((type) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
            setState(() {
                        _selectedApplicationType = type['ID']?.toString();
            });
          },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              _selectedApplicationType == type['ID']?.toString()
                                  ? getColor('primary')
                                  : Colors.grey.shade300,
                          width:
                              _selectedApplicationType == type['ID']?.toString()
                                  ? 2
                                  : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color:
                            _selectedApplicationType == type['ID']?.toString()
                                ? getColor('primary').withValues(alpha: 0.1)
                                : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selectedApplicationType == type['ID']?.toString()
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: _selectedApplicationType ==
                                    type['ID']?.toString()
                                ? getColor('primary')
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                MyTextLabel(
                                  text: type['Name']?.toString() ?? 'Unknown',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedApplicationType ==
                                          type['ID']?.toString()
                                      ? getColor('primary')
                                      : Colors.black87,
                                ),
                                const SizedBox(height: 4),
                                MyTextLabel(
                                  text: type['Description']?.toString() ??
                                      'No description available',
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.grey.shade600,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
        )),
      ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return Column(
      children: [
        SectionCard(
          title: "Basic Information",
          icon: Icons.info,
      child: Column(
            mainAxisSize: MainAxisSize.min,
        children: [
              CustomTextField(
            controller: _titleController,
                label: "Application Title",
                hint: "Enter a descriptive title",
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a title';
              }
              return null;
            },
          ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _parcelNumberController,
                label: "Parcel Number",
                hint: "Enter the parcel/LR number",
                prefixIcon: const Icon(Icons.tag),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the parcel number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
            controller: _descriptionController,
                label: "Description",
                hint: "Describe your application in detail",
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a description';
              }
              return null;
            },
          ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: "Zoning Category",
          icon: Icons.category,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoadingZoningCategories)
                const Center(
                  child: CircularProgressIndicator(),
                )
              else
                MySelectInput(
            value: _selectedZoningCategory,
                  label: "Zoning Category",
                  hint: "Select a zoning category",
                  items: _zoningCategories,
                  valueKey: 'ID',
                  displayKey: 'Name',
                  subtitleKey: 'Description',
                  isLoading: _isLoadingZoningCategories,
                  loadingText: 'Loading zoning categories...',
                  emptyText: 'No zoning categories available',
                  onChanged: (String? newValue) {
              setState(() {
                      _selectedZoningCategory = newValue;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a zoning category';
              }
              return null;
            },
          ),
        ],
      ),
        ),
      ],
    );
  }

  Widget _buildLocationStep() {
    return SectionCard(
      title: "Location & Details",
      icon: Icons.location_on,
      child: Column(
        mainAxisSize: MainAxisSize.min,
      children: [
          CustomTextField(
          controller: _locationController,
            label: "Location/Address",
            hint: "Enter the location of your project",
            prefixIcon: const Icon(Icons.location_on),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the location';
            }
            return null;
          },
        ),
          const SizedBox(height: 16),
          CustomTextField(
          controller: _areaController,
            label: "Area (sq meters)",
            hint: "Enter the area of your project",
            prefixIcon: const Icon(Icons.area_chart),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the area';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
      ],
      ),
    );
  }

  Widget _buildDocumentsStep() {
    return Column(
      children: [
        // Photo Section (like site_visit.dart)
        SectionCard(
          title: "Application Photos",
          icon: Icons.photo_camera,
          child: Column(
            mainAxisSize: MainAxisSize.min,
      children: [
              const MyTextLabel(
                text: "Photos (Optional)",
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              const SizedBox(height: 8),
              const MyTextLabel(
                text: "Add photos to support your application",
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _takePicture(),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Take Photo'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                ),
              ),
            ),
                  const SizedBox(width: 12),
            Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImages(),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Choose from Gallery'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_selectedImages.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: getColor('primary'),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_selectedImages.length} photo(s) selected',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_selectedImages[index].path),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                ),
              ),
            ),
          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Document Section
        SectionCard(
          title: "Required Documents",
          icon: Icons.attach_file,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MyTextLabel(
                text: "Upload required documents:",
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              const SizedBox(height: 16),

              // Document upload button
              CustomButton(
                text: 'Add Documents',
                onPressed: _pickDocument,
                icon: const Icon(Icons.attach_file, size: 16),
                isOutlined: true,
                width: double.infinity,
        ),
        
        const SizedBox(height: 20),
        
              // Uploaded documents list (like site_visit.dart style)
        if (_uploadedDocuments.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: getColor('primary'),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_uploadedDocuments.length} document(s) selected',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
          const SizedBox(height: 12),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    itemCount: _uploadedDocuments.length,
                    itemBuilder: (context, index) {
                      final path = _uploadedDocuments[index];
            final fileName = path.split('/').last;
                      final extension = fileName.split('.').last.toLowerCase();

                      IconData fileIcon;
                      Color fileColor;

                      switch (extension) {
                        case 'pdf':
                          fileIcon = Icons.picture_as_pdf;
                          fileColor = Colors.red;
                          break;
                        case 'doc':
                        case 'docx':
                          fileIcon = Icons.description;
                          fileColor = Colors.blue;
                          break;
                        case 'jpg':
                        case 'jpeg':
                        case 'png':
                          fileIcon = Icons.image;
                          fileColor = Colors.green;
                          break;
                        default:
                          fileIcon = Icons.insert_drive_file;
                          fileColor = Colors.grey;
                      }

                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: fileColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: fileColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    fileIcon,
                                    color: fileColor,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    fileName.length > 12
                                        ? '${fileName.substring(0, 12)}...'
                                        : fileName,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: fileColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeDocument(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ],
        
        const SizedBox(height: 20),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
                  color: getColor('primary').withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: getColor('primary').withValues(alpha: 0.3)),
          ),
                child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                    MyTextLabel(
                      text: 'Required Documents:',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: getColor('primary'),
                    ),
                    const SizedBox(height: 8),
                    const MyTextLabel(
                      text: '• Site plan or survey',
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                    const MyTextLabel(
                      text: '• Building plans (if applicable)',
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                    const MyTextLabel(
                      text: '• Proof of ownership or authorization',
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                    const MyTextLabel(
                      text: '• Any other relevant documents',
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
