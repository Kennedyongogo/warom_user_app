import 'package:flutter/material.dart';
import '../../utils/utils.dart';

class MySelectInput extends StatelessWidget {
  final String? value;
  final String label;
  final String hint;
  final List<Map<String, dynamic>> items;
  final String valueKey;
  final String displayKey;
  final String? subtitleKey;
  final Function(String?) onChanged;
  final String? Function(String?)? validator;
  final bool enabled;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onRefresh;
  final bool isLoading;
  final String? loadingText;
  final String? emptyText;
  final Widget? emptyAction;

  const MySelectInput({
    super.key,
    this.value,
    required this.label,
    required this.hint,
    required this.items,
    this.valueKey = 'ID',
    this.displayKey = 'title',
    this.subtitleKey,
    required this.onChanged,
    this.validator,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.onRefresh,
    this.isLoading = false,
    this.loadingText = 'Loading...',
    this.emptyText = 'No items found',
    this.emptyAction,
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.hourglass_empty,
                  color: getColor('primary'),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(loadingText!),
                ),
              ],
            ),
          )
        else if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  emptyText!,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                if (emptyAction != null) ...[
                  const SizedBox(height: 12),
                  emptyAction!,
                ],
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
              value: value,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                prefixIcon: prefixIcon,
                suffixIcon: suffixIcon ??
                    (onRefresh != null
                        ? IconButton(
                            onPressed: onRefresh,
                            icon: Icon(
                              isLoading ? Icons.hourglass_empty : Icons.refresh,
                              color: getColor('primary'),
                              size: 18,
                            ),
                            tooltip: 'Refresh',
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            padding: EdgeInsets.zero,
                          )
                        : null),
                isDense: true,
              ),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item[valueKey]?.toString(),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 250),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item[displayKey]?.toString() ?? 'Untitled',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        if (subtitleKey != null &&
                            item[subtitleKey] != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            _buildSubtitle(item),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: enabled ? onChanged : null,
              validator: validator,
              selectedItemBuilder: (BuildContext context) {
                return items.map<Widget>((item) {
                  return Container(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: Text(
                      item[displayKey]?.toString() ?? 'Untitled',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }).toList();
              },
            ),
          ),
      ],
    );
  }

  String _buildSubtitle(Map<String, dynamic> item) {
    if (subtitleKey == 'ProjectLocation') {
      // Special case for applications - show location and type
      final location = item['ProjectLocation'] ?? 'No location';
      final type = item['ProjectType'] ?? 'No type';
      return '$location • $type';
    }
    return item[subtitleKey]?.toString() ?? '';
  }
}
