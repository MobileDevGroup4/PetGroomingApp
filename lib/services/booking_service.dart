import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';

import '../models/booking.dart';
import '../models/service.dart';
import '../models/package.dart';
import '../services/notification_service.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger logger = Logger();

  Future<List<Service>> getServices() async {
    try {
      logger.d('Fetching services from Firestore');
      QuerySnapshot snapshot = await _firestore.collection('services').get();

      List<Service> services = snapshot.docs
          .map((doc) => Service.fromFirestore(doc))
          .toList();

      logger.d('Successfully fetched ${services.length} services');
      return services;
    } catch (e) {
      logger.e('Error fetching services', error: e);
      return [];
    }
  }

  Future<List<Package>> getPackages() async {
    try {
      logger.d('Fetching packages from Firestore');
      QuerySnapshot snapshot = await _firestore.collection('packages').get();

      List<Package> packages = snapshot.docs
          .map((doc) => Package.fromFirestore(doc))
          .toList();

      logger.d('Successfully fetched ${packages.length} packages');
      return packages;
    } catch (e) {
      logger.e('Error fetching packages', error: e);
      return [];
    }
  }

  Future<List<Booking>> getExistingBookingsForDay(DateTime date) async {
    try {
      logger.d('Fetching bookings from Firestore');
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('bookings')
          .where(
            'startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      logger.d('Successfully fetched bookings');
      return snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
    } catch (e) {
      logger.e('Error fetching bookings: $e');
      return [];
    }
  }

  Stream<List<Booking>> getUpcomingBookingsForCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }
    try {
      return _firestore
          .collection('bookings')
          .where('userId', isEqualTo: user.uid)
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.now())
          .orderBy('startTime')
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => Booking.fromFirestore(doc))
                .toList();
          });
    } catch (e) {
      logger.e('Error fetching user bookings: $e');
      return Stream.value([]);
    }
  }

  Future<void> createServiceBooking({
    required Service service,
    required DateTime startTime,
    required String petId,
    String notes = '',
    BookingStatus status = BookingStatus.initiated,
  }) async {
    try {
      final endTime = startTime.add(
        Duration(minutes: service.duration + 10),
      ); // +10 buffer

      await _createBookingRecord(
        itemId: service.id,
        itemName: service.name,
        itemType: 'service',
        petId: petId,
        startTime: startTime,
        endTime: endTime,
        notes: notes,
        status: status,
        originalPrice: service.price,
        priceLabel: '${service.price.toStringAsFixed(2)} CHF',
      );

      logger.d(
        'Service booking created successfully with status: ${status.value}',
      );
    } catch (e) {
      logger.e('Error creating service booking: $e');
      throw Exception('Failed to create booking.');
    }
  }

  Future<void> createPackageBooking({
    required Package package,
    required DateTime startTime,
    required String petId,
    String notes = '',
    BookingStatus status = BookingStatus.initiated,
  }) async {
    try {
      final endTime = startTime.add(
        Duration(minutes: package.durationMinutes + 10),
      ); // +10 buffer

      final actualPrice = package.hasDiscount && package.discountedPrice != null
          ? package.discountedPrice!
          : (package.basePrice ?? 0.0);

      await _createBookingRecord(
        itemId: package.id,
        itemName: package.name,
        itemType: 'package',
        petId: petId,
        startTime: startTime,
        endTime: endTime,
        notes: notes,
        status: status,
        originalPrice: actualPrice,
        priceLabel: package.priceLabel,
      );

      logger.d(
        'Package booking created successfully with status: ${status.value}',
      );
    } catch (e) {
      logger.e('Error creating package booking: $e');
      throw Exception('Failed to create booking.');
    }
  }

  Future<void> _createBookingRecord({
    required String itemId,
    required String itemName,
    required String itemType,
    required String petId,
    required DateTime startTime,
    required DateTime endTime,
    String notes = '',
    BookingStatus status = BookingStatus.initiated,
    required double originalPrice,
    required String priceLabel,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to create a booking.');
    }

    final booking = Booking(
      id: '',
      userId: user.uid,
      itemId: itemId,
      itemName: itemName,
      itemType: itemType,
      petId: petId,
      startTime: Timestamp.fromDate(startTime),
      endTime: Timestamp.fromDate(endTime),
      notes: notes,
      status: status,
      originalPrice: originalPrice,
      priceLabel: priceLabel,
    );

    await _firestore.collection('bookings').add(booking.toFirestore());
  }

  Future<void> _createNotificationForBooking({
    required String itemName,
    required DateTime startTime,
    BookingStatus status = BookingStatus.initiated,
  }) async {
    final NotificationService notificationService = NotificationService();
    final formattedDate = DateFormat('MMM d, y - h:mm a').format(startTime);

    // Notification based on status
    String title, message, type;
    switch (status) {
      case BookingStatus.initiated:
        title = 'Appointment Reserved';
        message =
            'You have reserved $itemName for $formattedDate. Please confirm your booking.';
        type = 'booking_reserved';
      case BookingStatus.confirmed:
        title = 'Appointment Confirmed';
        message = 'Your $itemName appointment for $formattedDate is confirmed!';
        type = 'booking_confirmed';
      case BookingStatus.completed:
        title = 'Service Completed';
        message = 'Your $itemName service has been completed. Thank you!';
        type = 'booking_completed';
    }

    await notificationService.createNotification(
      title: title,
      message: message,
      type: type,
    );
  }

  Future<void> createServiceBookingWithNotification({
    required Service service,
    required DateTime startTime,
    required String petId,
    String notes = '',
    BookingStatus status = BookingStatus.initiated,
  }) async {
    await createServiceBooking(
      service: service,
      startTime: startTime,
      petId: petId,
      notes: notes,
      status: status,
    );

    await _createNotificationForBooking(
      itemName: service.name,
      startTime: startTime,
      status: status,
    );
  }

  Future<void> createPackageBookingWithNotification({
    required Package package,
    required DateTime startTime,
    required String petId,
    String notes = '',
    BookingStatus status = BookingStatus.initiated,
  }) async {
    await createPackageBooking(
      package: package,
      startTime: startTime,
      petId: petId,
      notes: notes,
      status: status,
    );

    await _createNotificationForBooking(
      itemName: package.name,
      startTime: startTime,
      status: status,
    );
  }

  // Status management methods
  Future<void> updateBookingStatus({
    required String bookingId,
    required BookingStatus newStatus,
  }) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': newStatus.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      logger.d('Booking status updated to ${newStatus.value}');
    } catch (e) {
      logger.e('Error updating booking status: $e');
      throw Exception('Failed to update booking status.');
    }
  }

  // Confirm booking (for checkout process)
  Future<void> confirmBooking(String bookingId) async {
    await updateBookingStatus(
      bookingId: bookingId,
      newStatus: BookingStatus.confirmed,
    );

    // Create confirmation notification
    final NotificationService notificationService = NotificationService();
    await notificationService.createNotification(
      title: 'Booking Confirmed',
      message: 'Your appointment has been confirmed!',
      type: 'booking_confirmed',
    );
  }

  // Complete booking (for staff)
  Future<void> completeBooking(String bookingId) async {
    await updateBookingStatus(
      bookingId: bookingId,
      newStatus: BookingStatus.completed,
    );

    // Create completion notification
    final NotificationService notificationService = NotificationService();
    await notificationService.createNotification(
      title: 'Service Completed',
      message: 'Your pet grooming service has been completed!',
      type: 'booking_completed',
    );
  }

  // Get bookings by status
  Future<List<Booking>> getBookingsByStatus(BookingStatus status) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return [];
      }

      final snapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: status.value)
          .orderBy('startTime', descending: false)
          .get();

      return snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
    } catch (e) {
      logger.e('Error fetching bookings by status: $e');
      return [];
    }
  }

  // Get pending bookings (initiated status)
  Future<List<Booking>> getPendingBookings() async {
    return await getBookingsByStatus(BookingStatus.initiated);
  }
}
