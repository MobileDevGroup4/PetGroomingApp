import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String userId;

  // These fields can represent either a service OR a package
  final String itemId; // serviceId OR packageId
  final String itemName; // serviceName OR packageName
  final String itemType; // 'service' OR 'package'

  final Timestamp startTime;
  final Timestamp endTime;

  Booking({
    required this.id,
    required this.userId,
    required this.itemId,
    required this.itemName,
    required this.itemType,
    required this.startTime,
    required this.endTime,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Booking(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      itemId: data['itemId'] as String? ?? '',
      itemName: data['itemName'] as String? ?? 'Unnamed Item',
      itemType: data['itemType'] as String? ?? 'service',
      startTime: data['startTime'] as Timestamp? ?? Timestamp.now(),
      endTime: data['endTime'] as Timestamp? ?? Timestamp.now(),
    );
  }

  // Helper getter for backwared compatibility
  String get serviceId => itemId;
  String get serviceName => itemName;
  bool get isService => itemType == 'service';
  bool get isPackage => itemType == 'package';
}
