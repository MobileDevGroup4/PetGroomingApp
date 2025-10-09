import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/service.dart';

class DateTimeScreen extends StatefulWidget {
  final Service service;

  const DateTimeScreen({super.key, required this.service});

  @override
  State<DateTimeScreen> createState() => _DateTimeScreenState();
}

class _DateTimeScreenState extends State<DateTimeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _selectedTimeSlot; // To hold the selected time

  // Mock Data --> TODO: Replace with real data
  final List<String> _timeSlots = [
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay; // Pre-select today
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Date & Time for ${widget.service.name}'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Calendar Widget ---
              _buildTableCalendar(),
              const SizedBox(height: 24),

              // --- Time Slot Selection ---
              const Text(
                'Available Time Slots',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildTimeSlotGrid(),
              const SizedBox(height: 32),

              // --- Confirmation Button ---
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: (_selectedDay == null || _selectedTimeSlot == null)
                      ? null // Disable button if date or time is not selected
                      : () {
                          // TODO: Navigate to the confirmation screen or show a summary dialog.
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Booking ${widget.service.name} on ${_selectedDay!.toIso8601String().substring(0, 10)} at $_selectedTimeSlot',
                              ),
                            ),
                          );
                        },
                  child: const Text('Proceed to Confirmation'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for the calendar
  Widget _buildTableCalendar() {
    return Card(
      elevation: 2,
      child: TableCalendar(
        firstDay: DateTime.now(),
        lastDay: DateTime.now().add(
          const Duration(days: 60),
        ), // Allow booking up to 60 days in advance
        focusedDay: _focusedDay,
        calendarFormat: CalendarFormat.month,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          if (!isSameDay(_selectedDay, selectedDay)) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
              _selectedTimeSlot = null; // Reset time slot when date changes
            });
          }
        },
        headerStyle: const HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
        ),
      ),
    );
  }

  // Helper widget for the time slots
  Widget _buildTimeSlotGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 2.5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: _timeSlots.length,
      itemBuilder: (context, index) {
        final slot = _timeSlots[index];
        final isSelected = slot == _selectedTimeSlot;

        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.orange : Colors.grey[200],
            foregroundColor: isSelected ? Colors.white : Colors.black87,
            elevation: isSelected ? 4 : 1,
          ),
          onPressed: () {
            setState(() {
              _selectedTimeSlot = slot;
            });
          },
          child: Text(slot),
        );
      },
    );
  }
}
