import 'package:flutter/material.dart';
import '../../utils/utils.dart';

class CustomTimePicker extends StatelessWidget {
  final TimeOfDay? selectedTime;
  final String label;
  final String hint;
  final Function(TimeOfDay?) onTimeSelected;
  final bool enabled;
  final Widget? prefixIcon;

  const CustomTimePicker({
    super.key,
    this.selectedTime,
    required this.label,
    required this.hint,
    required this.onTimeSelected,
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
          onTap: enabled ? () => _selectTime(context) : null,
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
                    selectedTime != null ? selectedTime!.format(context) : hint,
                    style: TextStyle(
                      color: selectedTime != null
                          ? Colors.black87
                          : Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(
                  Icons.access_time,
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

  Future<void> _selectTime(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        TimeOfDay tempTime = selectedTime ?? TimeOfDay.now();
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Initialize scroll controllers with a slight delay
            final hourController = ScrollController(
              initialScrollOffset: tempTime.hour * 48.0, // Reduced item height
            );
            final minuteController = ScrollController(
              initialScrollOffset:
                  tempTime.minute * 48.0, // Reduced item height
            );

            return Container(
              height: MediaQuery.of(context).size.height *
                  0.7, // Use 70% of screen height
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Select Time',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: getColor('primary'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                    decoration: BoxDecoration(
                      color: getColor('primary').withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      '${tempTime.hour.toString().padLeft(2, '0')}:${tempTime.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: getColor('primary'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Row(
                      children: [
                        // Hour picker
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Hour',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: getColor('primary'),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: ListView.builder(
                                  controller: hourController,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: 24,
                                  itemBuilder: (context, index) {
                                    final hour = index;
                                    final isSelected = tempTime.hour == hour;
                                    return GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          tempTime = TimeOfDay(
                                            hour: hour,
                                            minute: tempTime.minute,
                                          );
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 1, horizontal: 6),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? getColor('primary')
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: isSelected
                                                ? getColor('primary')
                                                : Colors.grey.shade300,
                                          ),
                                        ),
                                        child: Text(
                                          hour.toString().padLeft(2, '0'),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.black87,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Minute picker
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Minute',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: getColor('primary'),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: ListView.builder(
                                  controller: minuteController,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: 60, // 0, 1, 2, 3, ..., 59
                                  itemBuilder: (context, index) {
                                    final minute = index;
                                    final isSelected =
                                        tempTime.minute == minute;
                                    return GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          tempTime = TimeOfDay(
                                            hour: tempTime.hour,
                                            minute: minute,
                                          );
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 1, horizontal: 6),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? getColor('primary')
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: isSelected
                                                ? getColor('primary')
                                                : Colors.grey.shade300,
                                          ),
                                        ),
                                        child: Text(
                                          minute.toString().padLeft(2, '0'),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.black87,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            onTimeSelected(tempTime);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: getColor('primary'),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Select'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
