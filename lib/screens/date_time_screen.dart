import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/service.dart';
import '../services/booking_service.dart';

class DateTimeScreen extends StatefulWidget {
  final Service service;
  const DateTimeScreen({super.key, required this.service});

  @override
  State<DateTimeScreen> createState() => _DateTimeScreenState();
}

class _DateTimeScreenState extends State<DateTimeScreen> {
  final BookingService _bookingService =
      BookingService(); // <-- Instantiate service
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _selectedTimeSlot;

  // This will hold the generated available slots
  late Future<List<String>> _availableTimeSlotsFuture;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // Fetch slots for the initially selected day
    _availableTimeSlotsFuture = _getAvailableTimeSlots(_selectedDay!);
  }

  // --- Start of the CORE LOGIC ---
  Future<List<String>> _getAvailableTimeSlots(DateTime date) async {
    // 1. Fetch all bookings for the selected day
    final existingBookings = await _bookingService.getExistingBookingsForDay(
      date,
    );

    // 2. Generate all potential time slots for the day
    final allPossibleSlots = _generateAllTimeSlots(date);

    // 3. Filter out slots that are already booked
    final availableSlots = allPossibleSlots.where((slot) {
      final slotDateTime = _parseSlot(date, slot);
      final slotEndTime = slotDateTime.add(
        Duration(minutes: widget.service.duration),
      );

      // Check if the potential slot overlaps with any existing booking
      for (final booking in existingBookings) {
        final bookingStart = booking.startTime.toDate();
        final bookingEnd = booking.endTime.toDate();

        // Simple overlap check:
        // (SlotStart < BookingEnd) and (SlotEnd > BookingStart)
        if (slotDateTime.isBefore(bookingEnd) &&
            slotEndTime.isAfter(bookingStart)) {
          return false; // This slot is unavailable
        }
      }
      return true; // This slot is available
    }).toList();

    return availableSlots;
  }

  // Helper to generate slots from 9:00 AM to 5:00 PM every 30 mins
  List<String> _generateAllTimeSlots(DateTime date) {
    final List<String> slots = [];
    final startTime = DateTime(
      date.year,
      date.month,
      date.day,
      9,
      0,
    ); // 9:00 AM
    final endTime = DateTime(date.year, date.month, date.day, 17, 0); // 5:00 PM

    var currentTime = startTime;
    while (currentTime.isBefore(endTime)) {
      slots.add(
        '${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}',
      );
      currentTime = currentTime.add(const Duration(minutes: 30));
    }
    return slots;
  }

  // Helper to convert a time string like "09:30" to a full DateTime object
  DateTime _parseSlot(DateTime date, String timeSlot) {
    final parts = timeSlot.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(date.year, date.month, date.day, hour, minute);
  }
  // --- End of CORE LOGIC ---

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
              _buildTableCalendar(),
              const SizedBox(height: 24),
              const Text(
                'Available Time Slots',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // vvvv Using a FutureBuilder for the time slots vvvv
              FutureBuilder<List<String>>(
                future: _availableTimeSlotsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading slots.'));
                  }
                  final slots = snapshot.data ?? [];
                  if (slots.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No available time slots for this day.'),
                      ),
                    );
                  }
                  return _buildTimeSlotGrid(
                    slots,
                  ); // Pass the real slots to the grid
                },
              ),

              // ^^^^ End of FutureBuilder ^^^^
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: (_selectedDay == null || _selectedTimeSlot == null)
                      ? null
                      : () {
                          // TODO: Implement booking creation logic
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

  Widget _buildTableCalendar() {
    return Card(
      elevation: 2,
      child: TableCalendar(
        firstDay: DateTime.now(),
        lastDay: DateTime.now().add(const Duration(days: 60)),
        focusedDay: _focusedDay,
        calendarFormat: CalendarFormat.month,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          if (!isSameDay(_selectedDay, selectedDay)) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
              _selectedTimeSlot = null;
              // When a new day is selected, re-fetch the slots for that day
              _availableTimeSlotsFuture = _getAvailableTimeSlots(selectedDay);
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

  Widget _buildTimeSlotGrid(List<String> timeSlots) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 2.5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: timeSlots.length,
      itemBuilder: (context, index) {
        final slot = timeSlots[index];
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
