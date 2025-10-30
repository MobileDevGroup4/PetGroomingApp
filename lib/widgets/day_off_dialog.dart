import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DayOffDialog extends StatefulWidget {
  const DayOffDialog({super.key});

  @override
  State<DayOffDialog> createState() => _DayOffDialogState();
}

class _DayOffDialogState extends State<DayOffDialog> {
  DateTime? _startDate;
  DateTime? _endDate;
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Day Off'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                _startDate == null 
                    ? 'Select Start Date' 
                    : DateFormat('MMM dd, yyyy').format(_startDate!),
              ),
              leading: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(true),
              tileColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: Text(
                _endDate == null 
                    ? 'Select End Date' 
                    : DateFormat('MMM dd, yyyy').format(_endDate!),
              ),
              leading: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(false),
              tileColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reason,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
                hintText: 'e.g., Vacation, Sick leave',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_startDate != null && _endDate != null) {
              Navigator.pop(context, {
                'startDate': Timestamp.fromDate(_startDate!),
                'endDate': Timestamp.fromDate(_endDate!),
                'reason': _reason.text.trim(),
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select both start and end dates')),
              );
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}