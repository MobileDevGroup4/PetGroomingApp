import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../screens/booking_screen.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';

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
    return Card(
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
    );
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
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () {
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
                MaterialPageRoute(builder: (context) => const BookingScreen()),
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
