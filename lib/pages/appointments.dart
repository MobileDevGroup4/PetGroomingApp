import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../screens/booking_selection_screen.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import '../screens/reschedule_screen.dart';

class Appointments extends StatefulWidget {
  const Appointments({super.key, required this.theme});

  final ThemeData theme;

  @override
  State<Appointments> createState() => _AppointmentsState();
}

class _AppointmentsState extends State<Appointments> {
  final BookingService _bookingService = BookingService();
  late Stream<List<Booking>> _bookingsStream;

  @override
  void initState() {
    super.initState();
    _bookingsStream = _bookingService.getUpcomingBookingsForCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Card(
        shadowColor: Colors.transparent,
        margin: const EdgeInsets.all(8.0),
        child: StreamBuilder<List<Booking>>(
          stream: _bookingsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final bookings = snapshot.data ?? [];

            // If there are no bookings, show the placeholder text
            if (bookings.isEmpty) {
              return _buildNoAppointmentsView();
            }

            // If there are bookings, show them in a list
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return _buildBookingCard(booking);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BookingSelectionScreen(),
            ),
          );
        },
        tooltip: 'Book Appointment',
        child: const Icon(Icons.add),
      ),
    );
  }

  // Check if booking can be modified (12+ hours away)
  bool _canModifyBooking(Booking booking) {
    final appointmentTime = booking.startTime.toDate();
    final now = DateTime.now();
    final difference = appointmentTime.difference(now);
    return difference.inHours >= 12;
  }

  void _rescheduleAppointment(Booking booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RescheduleScreen(booking: booking),
      ),
    );
  }

  void _cancelAppointment(Booking booking) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Appointment'),
          content: Text(
            'Are you sure you want to cancel your ${booking.itemName} appointment?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Keep Appointment'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _performCancelBooking(booking);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Cancel Appointment'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performCancelBooking(Booking booking) async {
    try {
      // Delete the booking from Firestore
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(booking.id)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling appointment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper Widget for displaying a single booking
  Widget _buildBookingCard(Booking booking) {
    // Using intl package for nice date formatting.
    final formattedDate = DateFormat(
      'EEEE, MMMM d, yyyy',
    ).format(booking.startTime.toDate());
    final formattedTime = DateFormat(
      'h:mm a',
    ).format(booking.startTime.toDate());

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: ListTile(
        leading: const Icon(Icons.cut, color: Colors.orange, size: 40),
        title: Text(
          booking.serviceName, // Using the stored serviceName
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('$formattedDate at $formattedTime'),

        trailing: _canModifyBooking(booking)
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _rescheduleAppointment(booking),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => _cancelAppointment(booking),
                  ),
                ],
              )
            : const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: _canModifyBooking(booking)
            ? null
            : () {
                // TODO: Navigate to a booking detail screen (future enhancement)
              },
      ),
    );
  }

  // Helper Widget for the "No Appointments" view
  Widget _buildNoAppointmentsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'You have no upcoming appointments',
            style: widget.theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BookingSelectionScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Book a New Appointment'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
