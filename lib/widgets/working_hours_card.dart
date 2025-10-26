import 'package:flutter/material.dart';

class WorkingHoursCard extends StatelessWidget {
  final Map<String, Map<String, dynamic>> workingHours;
  final Function(Map<String, Map<String, dynamic>>) onWorkingHoursChanged;
  final VoidCallback onSave;

  const WorkingHoursCard({
    super.key,
    required this.workingHours,
    required this.onWorkingHoursChanged,
    required this.onSave,
  });

  static const days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  void _toggleDay(String day, bool value) {
    final updated = Map<String, Map<String, dynamic>>.from(workingHours);
    updated[day] = {
      'isWorking': value,
      'startTime': workingHours[day]?['startTime'] ?? '09:00',
      'endTime': workingHours[day]?['endTime'] ?? '17:00',
    };
    onWorkingHoursChanged(updated);
  }

  Future<void> _selectTime(BuildContext context, String day, bool isStart) async {
    final currentTime = workingHours[day]?[isStart ? 'startTime' : 'endTime'] ?? '09:00';
    final parts = currentTime.split(':');

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
    );

    if (picked != null) {
      final timeString = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      final updated = Map<String, Map<String, dynamic>>.from(workingHours);
      updated[day]![isStart ? 'startTime' : 'endTime'] = timeString;
      onWorkingHoursChanged(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ...days.map((day) => _buildDayRow(context, day)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save),
            label: const Text('Save Working Hours'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayRow(BuildContext context, String day) {
    final data = workingHours[day] ?? {
      'isWorking': false,
      'startTime': '09:00',
      'endTime': '17:00',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(day, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          Switch(
            value: data['isWorking'] ?? false,
            activeThumbColor: Colors.green,
            onChanged: (value) => _toggleDay(day, value),
          ),
          if (data['isWorking'] ?? false) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context, day, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          data['startTime'] ?? '09:00',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('-'),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context, day, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          data['endTime'] ?? '17:00',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}