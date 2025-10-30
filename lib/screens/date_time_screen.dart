import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/service.dart';
import '../models/package.dart';
import '../models/pet.dart';
import '../services/booking_service.dart';

class DateTimeScreen extends StatefulWidget {
  final Service? service;
  final Package? package;
  final Pet selectedPet;

  const DateTimeScreen({
    super.key,
    this.service,
    this.package,
    required this.selectedPet,
  }) : assert(
         service != null || package != null,
         'Either service or package must be provided',
       );

  @override
  State<DateTimeScreen> createState() => _DateTimeScreenState();
}

class _DateTimeScreenState extends State<DateTimeScreen> {
  final BookingService _bookingService = BookingService();

  // Controller for the notes text field
  final TextEditingController _notesController = TextEditingController();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _selectedTimeSlot;

  // This will hold the generated available slots
  late Future<List<String>> _availableTimeSlotsFuture;

  // Date range limits - 3 months from today
  late DateTime _firstDay;
  late DateTime _lastDay;

  // Helper getters to know what we are booking
  bool get isService => widget.service != null;
  bool get isPackage => widget.package != null;

  String get itemName =>
      isService ? widget.service!.name : widget.package!.name;
  int get itemDuration =>
      isService ? widget.service!.duration : widget.package!.durationMinutes;

  @override
  void initState() {
    super.initState();

    // Set date range limits
    _firstDay = DateTime.now();
    _lastDay = DateTime.now().add(const Duration(days: 90)); // 3 months

    _selectedDay = _focusedDay;
    // Fetch slots for the initially selected day
    _availableTimeSlotsFuture = _getAvailableTimeSlots(_selectedDay!);
  }

  // Dispose the notes controller
  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // --- Start of the CORE LOGIC ---
  Future<List<String>> _getAvailableTimeSlots(DateTime date) async {
    // 1. Fetch all bookings for the selected day
    final existingBookings = await _bookingService.getExistingBookingsForDay(
      date,
    );

    // 2. Generate all potential time slots for the day
    final allPossibleSlots = _generateAllTimeSlots(date);

    // 3. Filter out slots that conflict with existing bookings
    final availableSlots = <String>[];

    for (final slot in allPossibleSlots) {
      final slotStartTime = _parseTimeSlot(date, slot);
      final slotEndTime = slotStartTime.add(Duration(minutes: itemDuration));

      bool isConflict = false;
      for (final booking in existingBookings) {
        final bookingStart = booking.startTime.toDate();
        final bookingEnd = booking.endTime.toDate();

        // Check if there's any overlap
        if (slotStartTime.isBefore(bookingEnd) &&
            slotEndTime.isAfter(bookingStart)) {
          isConflict = true;
          break;
        }
      }

      if (!isConflict) {
        availableSlots.add(slot);
      }
    }

    return availableSlots;
  }

  List<String> _generateAllTimeSlots(DateTime date) {
    final slots = <String>[];
    const startHour = 9; // 9:00 AM
    const endHour = 17; // 5:00 PM
    const slotInterval = 40; // 40 minutes between each slot

    for (int hour = startHour; hour < endHour; hour++) {
      for (int minute = 0; minute < 60; minute += slotInterval) {
        final timeString =
            '${hour.toString().padLeft(2, '0')}:'
            '${minute.toString().padLeft(2, '0')}';

        // Make sure the slot + duration doesn't exceed end hour
        final slotTime = DateTime(
          date.year,
          date.month,
          date.day,
          hour,
          minute,
        );
        final slotEndTime = slotTime.add(Duration(minutes: itemDuration));

        if (slotEndTime.hour < endHour ||
            (slotEndTime.hour == endHour && slotEndTime.minute == 0)) {
          slots.add(timeString);
        }
      }
    }

    return slots;
  }

  DateTime _parseTimeSlot(DateTime date, String timeSlot) {
    final parts = timeSlot.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  Widget _buildTimeSlotGrid(List<String> slots) {
    return Container(
      height: 160, // Reduced height to make it more compact
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 2.2, // Reduced aspect ratio for more compact tiles
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
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
                color: isSelected ? Colors.blue : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected
                      ? Colors.blue.shade800
                      : Colors.grey.shade400,
                ),
              ),
              child: Center(
                child: Text(
                  slot,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12, // Slightly smaller font
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Date & Time'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service/Package Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking for: ${widget.selectedPet.name}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Service: $itemName',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Duration: $itemDuration minutes',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Calendar section
            const Text(
              'Select Date',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TableCalendar<dynamic>(
                firstDay: _firstDay,
                lastDay: _lastDay,
                focusedDay: _focusedDay,
                calendarFormat: CalendarFormat.month,
                startingDayOfWeek: StartingDayOfWeek.monday,

                // Removed the header style that was showing "2 weeks"
                headerStyle: const HeaderStyle(
                  formatButtonVisible:
                      false, // This removes the "2 weeks" button
                  titleCentered: true,
                  leftChevronIcon: Icon(Icons.chevron_left),
                  rightChevronIcon: Icon(Icons.chevron_right),
                ),

                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  weekendTextStyle: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                  holidayTextStyle: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                  defaultTextStyle: const TextStyle(
                    fontSize: 14,
                  ), // Compact text
                  selectedDecoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.blue.shade300,
                    shape: BoxShape.circle,
                  ),
                  markersMaxCount: 1,
                  markerDecoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),

                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },

                onDaySelected: (selectedDay, focusedDay) {
                  if (!isSameDay(_selectedDay, selectedDay)) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                      _selectedTimeSlot = null; // Reset time selection
                      _availableTimeSlotsFuture = _getAvailableTimeSlots(
                        selectedDay,
                      );
                    });
                  }
                },

                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },

                // Make calendar more compact
                daysOfWeekHeight: 35,
                rowHeight: 35,
              ),
            ),

            const SizedBox(height: 16),

            // Available times section
            const Text(
              'Available Times',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            FutureBuilder<List<String>>(
              future: _availableTimeSlotsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 160,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return SizedBox(
                    height: 160,
                    child: Center(
                      child: Text(
                        'Error loading time slots: ${snapshot.error}',
                      ),
                    ),
                  );
                }

                final slots = snapshot.data ?? [];
                if (slots.isEmpty) {
                  return const SizedBox(
                    height: 160,
                    child: Center(
                      child: Text('No available time slots for this date'),
                    ),
                  );
                }

                return _buildTimeSlotGrid(slots);
              },
            ),

            const SizedBox(height: 16),

            // Special Notes section - now visible with compact layout above
            const Text(
              'Special Notes (Optional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Any special requests or notes for the groomer...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Book appointment button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedDay != null && _selectedTimeSlot != null
                    ? _bookAppointment
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Book Appointment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _bookAppointment() async {
    if (_selectedDay == null || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    try {
      final startTime = _parseTimeSlot(_selectedDay!, _selectedTimeSlot!);

      if (isService && widget.service != null) {
        await _bookingService.createServiceBookingWithNotification(
          service: widget.service!,
          startTime: startTime,
          petId: widget.selectedPet.id,
          notes: _notesController.text.trim(),
        );
      } else if (isPackage && widget.package != null) {
        await _bookingService.createPackageBookingWithNotification(
          package: widget.package!,
          startTime: startTime,
          petId: widget.selectedPet.id,
          notes: _notesController.text.trim(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment booked successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to appointments or home
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to book appointment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
