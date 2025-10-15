import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/booking.dart';
import '../services/booking_service.dart';

class RescheduleScreen extends StatefulWidget {
  final Booking booking;

  const RescheduleScreen({super.key, required this.booking});

  @override
  State<RescheduleScreen> createState() => _RescheduleScreenState();
}

class _RescheduleScreenState extends State<RescheduleScreen> {
  final BookingService _bookingService = BookingService();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _selectedTimeSlot;
  late Future<List<String>> _availableTimeSlotsFuture;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _availableTimeSlotsFuture = _getAvailableTimeSlots(_selectedDay!);
  }

  Future<List<String>> _getAvailableTimeSlots(DateTime date) async {
    // Get existing bookings for the day (excluding current booking)
    final existingBookings = await _bookingService.getExistingBookingsForDay(
      date,
    );
    final filteredBookings = existingBookings
        .where((b) => b.id != widget.booking.id)
        .toList();

    // Generate time slots (simplified version)
    final slots = <String>[];
    for (int hour = 9; hour <= 16; hour++) {
      slots.add('${hour.toString().padLeft(2, '0')}:00');
      slots.add('${hour.toString().padLeft(2, '0')}:30');
    }

    // Filter out occupied slots
    final availableSlots = slots.where((slot) {
      final slotTime = _parseSlot(date, slot);
      final slotEnd = slotTime.add(
        const Duration(minutes: 60),
      ); // Assume 60 min duration

      for (final booking in filteredBookings) {
        final bookingStart = booking.startTime.toDate();
        final bookingEnd = booking.endTime.toDate();

        if (slotTime.isBefore(bookingEnd) && slotEnd.isAfter(bookingStart)) {
          return false;
        }
      }
      return true;
    }).toList();

    return availableSlots;
  }

  DateTime _parseSlot(DateTime date, String slot) {
    final parts = slot.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reschedule Appointment'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Current appointment info
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Appointment:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(widget.booking.itemName),
                Text(
                  widget.booking.startTime.toDate().toString().substring(0, 16),
                ),
              ],
            ),
          ),

          // Calendar
          TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 90)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _selectedTimeSlot = null;
                _availableTimeSlotsFuture = _getAvailableTimeSlots(selectedDay);
              });
            },
          ),

          // Time slots
          Expanded(
            child: FutureBuilder<List<String>>(
              future: _availableTimeSlotsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final slots = snapshot.data ?? [];
                if (slots.isEmpty) {
                  return const Center(
                    child: Text('No available slots for this day'),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 2,
                  ),
                  itemCount: slots.length,
                  itemBuilder: (context, index) {
                    final slot = slots[index];
                    final isSelected = _selectedTimeSlot == slot;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTimeSlot = slot;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            slot,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Reschedule button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedTimeSlot != null
                    ? _confirmReschedule
                    : null,
                child: const Text('Confirm Reschedule'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReschedule() async {
    if (_selectedDay == null || _selectedTimeSlot == null) return;

    try {
      final newStartTime = _parseSlot(_selectedDay!, _selectedTimeSlot!);
      final originalDuration = widget.booking.endTime.toDate().difference(
        widget.booking.startTime.toDate(),
      );
      final newEndTime = newStartTime.add(originalDuration);

      // Update the booking in Firestore
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.booking.id)
          .update({
            'startTime': Timestamp.fromDate(newStartTime),
            'endTime': Timestamp.fromDate(newEndTime),
          });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment rescheduled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rescheduling: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
