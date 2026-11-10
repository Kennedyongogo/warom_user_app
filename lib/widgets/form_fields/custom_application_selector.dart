import 'package:flutter/material.dart';
import '../../utils/utils.dart';
import '../../widgets/buttons/custom_button.dart';

class CustomApplicationSelector extends StatelessWidget {
  final String? selectedApplicationId;
  final List<Map<String, dynamic>> applications;
  final Function(String?) onApplicationSelected;
  final Function() onRefresh;
  final bool isLoading;
  final String? Function(String?)? validator;
  final String label;
  final String hint;
  final String emptyMessage;
  final String refreshButtonText;

  const CustomApplicationSelector({
    super.key,
    this.selectedApplicationId,
    required this.applications,
    required this.onApplicationSelected,
    required this.onRefresh,
    this.isLoading = false,
    this.validator,
    this.label = "Select Application",
    this.hint = "Select an application",
    this.emptyMessage = "No applications found",
    this.refreshButtonText = "Refresh",
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        if (isLoading)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(getColor('primary')),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Loading applications...'),
              ],
            ),
          )
        else if (applications.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: Column(
              children: [
                Text(
                  emptyMessage,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: refreshButtonText,
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh, size: 16),
                  isOutlined: true,
                  height: 36,
                  fontSize: 14,
                ),
              ],
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: DropdownButtonFormField<String>(
              value: selectedApplicationId,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                suffixIcon: IconButton(
                  onPressed: onRefresh,
                  icon: Icon(
                    Icons.refresh,
                    color: getColor('primary'),
                    size: 20,
                  ),
                  tooltip: 'Refresh applications',
                ),
              ),
              items: applications.map((app) {
                return DropdownMenuItem<String>(
                  value: app['ID'],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        app['ProjectTitle'] ?? 'Untitled Project',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${app['ProjectLocation'] ?? 'No location'} • ${app['ProjectType'] ?? 'No type'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onApplicationSelected,
              validator: validator,
            ),
          ),
        const SizedBox(height: 8),
        Text(
          selectedApplicationId != null && applications.isNotEmpty
              ? 'Application selected. You can change it using the dropdown above.'
              : 'Select the application you want to create a site visit for',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
