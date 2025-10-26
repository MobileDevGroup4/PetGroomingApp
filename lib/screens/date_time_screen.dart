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

    // 3. Filter out slots that are already booked
    final availableSlots = allPossibleSlots.where((slot) {
      final slotDateTime = _parseSlot(date, slot);
      final slotEndTime = slotDateTime.add(
        Duration(minutes: itemDuration + 10),
      );

      // Check if the potential slot overlaps with any existing booking
      for (final booking in existingBookings) {
        final bookingStart = booking.startTime.toDate();
        final bookingEnd = booking.endTime.toDate();

        // overlap check:
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

  // Helper to generate slots from 9:00 AM to 5:00 PM
  // Slots are generated based on service duration + buffer time
  List<String> _generateAllTimeSlots(DateTime date) {
    final List<String> slots = [];

    // Service duration + 10 minute buffer
    final int slotInterval = itemDuration + 10;

    // Start time: 9:00 AM
    int startHour = 9;
    int startMinute = 0;

    // End time: 5:00 PM (17:00)
    int endHour = 17;

    DateTime currentSlot = DateTime(
      date.year,
      date.month,
      date.day,
      startHour,
      startMinute,
    );

    final DateTime endTime = DateTime(
      date.year,
      date.month,
      date.day,
      endHour,
      0,
    );

    while (currentSlot.isBefore(endTime)) {
      // Format as "HH:mm" (e.g., "09:00", "14:30")
      final String timeString =
          '${currentSlot.hour.toString().padLeft(2, '0')}:${currentSlot.minute.toString().padLeft(2, '0')}';
      slots.add(timeString);

      // Move to next slot (service duration + buffer)
      currentSlot = currentSlot.add(Duration(minutes: slotInterval));
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

  Widget _buildTimeSlotGrid(List<String> slots) {
    return Container(
      height: 200,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 2.5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
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
                borderRadius: BorderRadius.circular(8),
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
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text('Service: $itemName'),
                  Text('Duration: $itemDuration minutes'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Calendar
            Text('Select Date', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 90)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                  _selectedTimeSlot = null; // Reset time selection
                  _availableTimeSlotsFuture = _getAvailableTimeSlots(
                    selectedDay,
                  );
                });
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.blue.shade300,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Time Slots
            Text(
              'Available Times',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<String>>(
              future: _availableTimeSlotsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final slots = snapshot.data ?? [];
                if (slots.isEmpty) {
                  return Container(
                    height: 100,
                    padding: const EdgeInsets.all(16),
                    child: const Center(
                      child: Text(
                        'No available slots for this date',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  );
                }
                return _buildTimeSlotGrid(slots);
              },
            ),
            const SizedBox(height: 32),

            // Notes Section
            Text(
              'Special Notes (Optional)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Any special requests or notes for the groomer...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 32),

            // Confirm Button
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: (_selectedDay == null || _selectedTimeSlot == null)
                    ? null
                    : () async {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);

                        final navigator = Navigator.of(context);

                        final notes = _notesController.text.trim();

                        try {
                          final selectedStartTime = _parseSlot(
                            _selectedDay!,
                            _selectedTimeSlot!,
                          );

                          if (isService) {
                            await _bookingService
                                .createServiceBookingWithNotification(
                                  service: widget.service!,
                                  startTime: selectedStartTime,
                                  petId: widget.selectedPet.id,
                                  notes: notes,
                                );
                          } else {
                            await _bookingService
                                .createPackageBookingWithNotification(
                                  package: widget.package!,
                                  startTime: selectedStartTime,
                                  petId: widget.selectedPet.id,
                                  notes: notes,
                                );
                          }

                          if (mounted) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  notes.isEmpty
                                      ? 'Booking confirmed successfully!'
                                      : 'Booking confirmed with notes saved!',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                            navigator.popUntil((route) => route.isFirst);
                          }
                        } catch (e) {
                          if (mounted) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                child: const Text('Confirm Booking'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
