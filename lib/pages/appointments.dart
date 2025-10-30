import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/booking_selection_screen.dart';
import '../models/booking.dart';
import '../models/pet.dart';
import '../screens/reschedule_screen.dart';
import '../services/notification_service.dart';
import '../pages/booking_checkout_page.dart';

class BookingWithPet {
  final Booking booking;
  final Pet? pet;

  BookingWithPet({required this.booking, this.pet});
}

class Appointments extends StatefulWidget {
  const Appointments({super.key, required this.theme});

  final ThemeData theme;

  @override
  State<Appointments> createState() => _AppointmentsState();
}

class _AppointmentsState extends State<Appointments> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<List<BookingWithPet>> _bookingsStream;

  @override
  void initState() {
    super.initState();
    _bookingsStream = _getUpcomingBookingsWithPetInfoStream();
  }

  /// Fetches upcoming bookings with associated pet information
  /// Pets are stored in users/{userId}/pets subcollection
  Stream<List<BookingWithPet>> _getUpcomingBookingsWithPetInfoStream() {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .where('startTime', isGreaterThan: Timestamp.now())
        .orderBy('startTime')
        .snapshots()
        .asyncMap((snapshot) async {
          final bookings = snapshot.docs
              .map((doc) => Booking.fromFirestore(doc))
              .toList();

          List<BookingWithPet> bookingsWithPets = [];

          for (final booking in bookings) {
            Pet? pet;
            try {
              // Fetch pet from user's pets subcollection
              final petDoc = await _firestore
                  .collection('users')
                  .doc(userId)
                  .collection('pets')
                  .doc(booking.petId)
                  .get();

              if (petDoc.exists) {
                pet = Pet.fromFirestore(petDoc);
              }
            } catch (e) {
              print('Error fetching pet ${booking.petId}: $e');
            }

            bookingsWithPets.add(BookingWithPet(booking: booking, pet: pet));
          }

          return bookingsWithPets;
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<List<BookingWithPet>>(
        stream: _bookingsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading appointments: ${snapshot.error}'),
            );
          }

          final bookingsWithPets = snapshot.data ?? [];

          if (bookingsWithPets.isEmpty) {
            return _buildNoAppointmentsView();
          }

          return ListView.builder(
            itemCount: bookingsWithPets.length,
            itemBuilder: (context, index) {
              final bookingWithPet = bookingsWithPets[index];
              return _buildAppointmentCard(bookingWithPet);
            },
          );
        },
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
        backgroundColor: Colors.deepPurple.shade400,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  /// Builds individual appointment card
  Widget _buildAppointmentCard(BookingWithPet bookingWithPet) {
    final booking = bookingWithPet.booking;
    final pet = bookingWithPet.pet;
    final startTime = booking.startTime.toDate();
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      elevation: 2,
      child: InkWell(
        onTap: () => _showAppointmentDetails(bookingWithPet),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Header row with pet avatar, details, and status
              Row(
                children: [
                  // Pet avatar with image loading from petAvatars collection
                  if (pet != null && userId != null)
                    StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('petAvatars')
                          .doc('${userId}_${pet.id}')
                          .snapshots(),
                      builder: (context, snap) {
                        Uint8List? bytes;
                        final data = snap.data?.data();
                        final raw = data?['data'];
                        if (raw is Uint8List) bytes = raw;
                        if (raw is List) {
                          bytes = Uint8List.fromList(raw.cast<int>());
                        }

                        final img = (bytes != null && bytes.isNotEmpty)
                            ? MemoryImage(bytes)
                            : null;

                        return CircleAvatar(
                          radius: 20,
                          backgroundImage: img,
                          backgroundColor: Colors.blue.shade100,
                          child: img == null
                              ? Icon(
                                  Icons.pets,
                                  color: Colors.blue.shade700,
                                  size: 20,
                                )
                              : null,
                        );
                      },
                    )
                  else
                    // Default pet avatar when no pet data or image available
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(Icons.pets, color: Colors.blue.shade700),
                    ),
                  const SizedBox(width: 16),

                  // Main booking information
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Service or package name
                        Text(
                          booking.itemName,
                          style: widget.theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Pet name display
                        Row(
                          children: [
                            Icon(
                              Icons.pets,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              pet?.name ?? 'Pet not found',
                              style: widget.theme.textTheme.bodyMedium
                                  ?.copyWith(
                                    color: pet != null
                                        ? Colors.grey.shade700
                                        : Colors.red.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Booking price (preserved price)
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.attach_money,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              booking.priceLabel.isNotEmpty
                                  ? booking.priceLabel
                                  : '${booking.originalPrice.toStringAsFixed(2)} CHF',
                              style: widget.theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(Price)',
                              style: widget.theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade500,
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),

                        // Appointment date and time
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat(
                                'EEE, MMM d, y - h:mm a',
                              ).format(startTime),
                              style: widget.theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Booking status indicator
                  _buildStatusChip(booking.status),
                ],
              ),

              // Action buttons for modifiable bookings
              if (_canModifyBooking(booking)) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Confirm button for initiated bookings
                    if (booking.isInitiated)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _confirmBooking(booking),
                          icon: const Icon(
                            Icons.check_circle_outline,
                            size: 18,
                          ),
                          label: const Text('Confirm'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),

                    if (booking.isInitiated) const SizedBox(width: 8),

                    // Reschedule appointment button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _rescheduleAppointment(booking),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Reschedule'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Cancel appointment button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _cancelAppointment(booking),
                        icon: const Icon(Icons.cancel, size: 18),
                        label: const Text('Cancel'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Creates a status indicator chip based on booking status
  Widget _buildStatusChip(BookingStatus status) {
    Color color;
    IconData icon;
    String label;

    switch (status) {
      case BookingStatus.initiated:
        color = Colors.orange;
        icon = Icons.schedule;
        label = 'PENDING';
      case BookingStatus.confirmed:
        color = Colors.green;
        icon = Icons.check_circle;
        label = 'CONFIRMED';
      case BookingStatus.completed:
        color = Colors.blue;
        icon = Icons.done_all;
        label = 'COMPLETED';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Navigates to booking confirmation page
  void _confirmBooking(Booking booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            BookingCheckoutPage(bookingId: booking.id, booking: booking),
      ),
    );
  }

  /// Shows detailed appointment information in a dialog
  void _showAppointmentDetails(BookingWithPet bookingWithPet) {
    final booking = bookingWithPet.booking;
    final pet = bookingWithPet.pet;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appointment Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Service/Package:', booking.itemName),
              const SizedBox(height: 12),

              _buildDetailRow('Pet:', pet?.name ?? 'Pet not found'),
              if (pet != null) ...[
                const SizedBox(height: 8),
                _buildDetailRow('Breed:', pet.breed),
                _buildDetailRow('Age:', '${pet.age} years'),
                _buildDetailRow('Size:', pet.size),
                _buildDetailRow('Weight:', '${pet.weight} kg'),
                if (pet.colour.isNotEmpty)
                  _buildDetailRow('Color:', pet.colour),
                if (pet.preferences.isNotEmpty)
                  _buildDetailRow('Pet Preferences:', pet.preferences),
              ],
              const SizedBox(height: 12),

              _buildDetailRow(
                'Date:',
                DateFormat(
                  'EEEE, MMMM d, y',
                ).format(booking.startTime.toDate()),
              ),
              _buildDetailRow(
                'Time:',
                '${DateFormat('h:mm a').format(booking.startTime.toDate())} - ${DateFormat('h:mm a').format(booking.endTime.toDate())}',
              ),

              const SizedBox(height: 12),
              _buildDetailRow('Status:', booking.statusDisplayText),

              if (booking.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildDetailRow('Notes:', booking.notes),
              ],
            ],
          ),
        ),
        actions: [
          if (_canModifyBooking(booking)) ...[
            if (booking.isInitiated)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _confirmBooking(booking);
                },
                child: const Text('Confirm'),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _rescheduleAppointment(booking);
              },
              child: const Text('Reschedule'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _cancelAppointment(booking);
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Creates a detail row for the appointment details dialog
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  /// Determines if a booking can be modified based on timing and status
  bool _canModifyBooking(Booking booking) {
    final now = DateTime.now();
    final appointmentTime = booking.startTime.toDate();
    final timeDifference = appointmentTime.difference(now);

    // Can modify if more than 12 hours away and not completed
    return timeDifference.inHours >= 12 && !booking.isCompleted;
  }

  /// Navigates to appointment rescheduling screen
  void _rescheduleAppointment(Booking booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RescheduleScreen(booking: booking),
      ),
    );
  }

  /// Handles appointment cancellation with confirmation dialog
  Future<void> _cancelAppointment(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Text(
          'Are you sure you want to cancel your ${booking.itemName} appointment?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Appointment'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Appointment'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Delete the booking from Firestore
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(booking.id)
            .delete();

        // Create cancellation notification
        final NotificationService notificationService = NotificationService();
        final formattedDate = DateFormat(
          'MMM d, y - h:mm a',
        ).format(booking.startTime.toDate());

        await notificationService.createNotification(
          title: 'Appointment Cancelled',
          message:
              'You have cancelled your ${booking.itemName} appointment for $formattedDate',
          type: 'cancellation',
        );

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
  }

  /// Builds the view displayed when user has no appointments
  Widget _buildNoAppointmentsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'You have no upcoming appointments',
            style: widget.theme.textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
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
