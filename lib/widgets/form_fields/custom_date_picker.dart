import 'package:flutter/material.dart';
import '../../utils/utils.dart';

class CustomDatePicker extends StatelessWidget {
  final DateTime? selectedDate;
  final String label;
  final String hint;
  final Function(DateTime?) onDateSelected;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final DateTime? initialDate;
  final bool enabled;
  final Widget? prefixIcon;

  const CustomDatePicker({
    super.key,
    this.selectedDate,
    required this.label,
    required this.hint,
    required this.onDateSelected,
    this.firstDate,
    this.lastDate,
    this.initialDate,
    this.enabled = true,
    this.prefixIcon,
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
        InkWell(
          onTap: enabled ? () => _selectDate(context) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
            ),
            child: Row(
              children: [
                if (prefixIcon != null) ...[
                  prefixIcon!,
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    selectedDate != null ? formatDate(selectedDate!) : hint,
                    style: TextStyle(
                      color: selectedDate != null
                          ? Colors.black87
                          : Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  color: enabled ? getColor('primary') : Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? initialDate ?? DateTime.now(),
      firstDate:
          firstDate ?? DateTime.now().subtract(const Duration(days: 365)),
      lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != selectedDate) {
      onDateSelected(picked);
    }
  }
}
