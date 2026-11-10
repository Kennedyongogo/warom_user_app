import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/utils.dart';

class PhotoPicker extends StatelessWidget {
  final List<XFile> selectedImages;
  final Function(List<XFile>) onImagesSelected;
  final String title;
  final String subtitle;
  final bool allowMultiple;
  final int? maxImages;

  const PhotoPicker({
    super.key,
    required this.selectedImages,
    required this.onImagesSelected,
    this.title = "Photos",
    this.subtitle = "Add photos to support your report",
    this.allowMultiple = true,
    this.maxImages,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImages(context),
                  icon: const Icon(Icons.camera_alt),
                  label: Text(allowMultiple ? 'Add Photos' : 'Take Photo'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              if (selectedImages.isNotEmpty) ...[
                const SizedBox(width: 12),
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
                    '${selectedImages.length} photo(s)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (selectedImages.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: selectedImages.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            selectedImages[index].path,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.image),
                              );
                            },
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
    );
  }

  Future<void> _pickImages(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      List<XFile> images = [];

      if (allowMultiple) {
        images = await picker.pickMultiImage();
      } else {
        final XFile? image =
            await picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          images = [image];
        }
      }

      if (images.isNotEmpty) {
        if (maxImages != null &&
            selectedImages.length + images.length > maxImages!) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Maximum $maxImages photos allowed'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        onImagesSelected([...selectedImages, ...images]);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage(int index) {
    final newImages = List<XFile>.from(selectedImages);
    newImages.removeAt(index);
    onImagesSelected(newImages);
  }
}
