import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/service.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
  );
  // Fetch all services from the 'services' collection.
  Future<List<Service>> getServices() async {
    try{
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
}