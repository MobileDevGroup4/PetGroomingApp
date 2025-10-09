import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String userId;
  final String serviceId;
  final String serviceName;
  final Timestamp startTime;
  final Timestamp endTime;

  Booking({
    required this.id,
    required this.userId,
    required this.serviceId,
    required this.serviceName,
    required this.startTime,
    required this.endTime,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Booking(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      serviceId: data['serviceId'] as String? ?? '',
      serviceName: data['serviceName'] as String? ?? 'Unnamed Service',
      startTime: data['startTime'] as Timestamp? ?? Timestamp.now(),
      endTime: data['endTime'] as Timestamp? ?? Timestamp.now(),
    );
  }
}
