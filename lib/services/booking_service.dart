import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/models/package.dart';
import 'package:logger/logger.dart';

import '../models/booking.dart';
import '../models/service.dart';
import '../models/package.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fetch all services from the 'services' collection.
  Future<List<Service>> getServices() async {
    try {
      logger.d('Fetching services from Firestore');
      QuerySnapshot snapshot = await _firestore.collection('services').get();

      // Map the document to a list of Service objects.
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

  // Fetch all packages from the 'packages' collection.
  Future<List<Package>> getPackages() async {
    try {
      logger.d('Fetching packages from Firestore');
      QuerySnapshot snapshot = await _firestore.collection('packages').get();

      // Map the document to a list of Package objects.
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
      // Set start o f the selected day (at 00:00:00)
      final startOfDay = DateTime(date.year, date.month, date.day);
      // Set end of the selected day (at 23:59:59)
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

  Future<void> createServiceBooking({
    required Service service,
    required DateTime startTime,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to create a booking.');
    }

    try {
      final endTime = startTime.add(
        Duration(minutes: service.duration + 10),
      ); // +10 buffer

      await _firestore.collection('bookings').add({
        'userId': user.uid,
        'itemId': service.id,
        'itemName': service.name,
        'itemType': 'service',
        'petId': 'p12345', // TODO: add pet selection
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'createdAt': FieldValue.serverTimestamp(),
      });

      logger.d('Service booking created successfully');
    } catch (e) {
      logger.e('Error creating service booking: $e');
      throw Exception('Failed to create booking.');
    }
  }

  // Create booking for a PACKAGE
  Future<void> createPackageBooking({
    required Package package,
    required DateTime startTime,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to create a booking.');
    }

    try {
      final endTime = startTime.add(
        Duration(minutes: package.durationMinutes + 10),
      ); // +10 buffer

      await _firestore.collection('bookings').add({
        'userId': user.uid,
        'itemId': package.id,
        'itemName': package.name,
        'itemType': 'package',
        'petId': 'p12345', // TODO: add pet selection
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'createdAt': FieldValue.serverTimestamp(),
      });

      logger.d('Package booking created successfully');
    } catch (e) {
      logger.e('Error creating package booking: $e');
      throw Exception('Failed to create booking.');
    }
  }

  Stream<List<Booking>> getUpcomingBookingsForCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) {
      // If no user is logged in, return an empty stream
      return Stream.value([]);
    }
    try {
      return _firestore
          .collection('bookings')
          // 1. Filter bookings by the current user's ID
          .where('userId', isEqualTo: user.uid)
          // 2. Only get bookings that start from now onwards
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.now())
          // 3. Order them by start time so the soonest is first
          .orderBy('startTime')
          .snapshots() // This returns a Stream<QuerySnapshot>
          .map((snapshot) {
            // This converts the stream of snapshots into a stream of lists of Bookings
            return snapshot.docs
                .map((doc) => Booking.fromFirestore(doc))
                .toList();
          });
    } catch (e) {
      logger.e('Error fetching user bookings: $e');
      // On error, return a stream with an empty list
      return Stream.value([]);
    }
  }
}
