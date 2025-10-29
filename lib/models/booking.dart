import 'package:cloud_firestore/cloud_firestore.dart';

// Define the booking status enum
enum BookingStatus {
  initiated, // Time slot reserved but not confirmed
  confirmed, // Payment completed or booking confirmed
  completed, // Service provided and marked as done by staff
}

// Extension to convert enum to/from string for Firestore
extension BookingStatusExtension on BookingStatus {
  String get value {
    switch (this) {
      case BookingStatus.initiated:
        return 'initiated';
      case BookingStatus.confirmed:
        return 'confirmed';
      case BookingStatus.completed:
        return 'completed';
    }
  }

  static BookingStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'initiated':
        return BookingStatus.initiated;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'completed':
        return BookingStatus.completed;
      default:
        return BookingStatus.initiated; // Default fallback
    }
  }
}

class Booking {
  final String id;
  final String userId;
  final String itemId; // serviceId OR packageId
  final String itemName; // serviceName OR packageName
  final String itemType; // 'service' OR 'package'
  final String petId;
  final Timestamp startTime;
  final Timestamp endTime;
  final String notes;
  final BookingStatus status;
  final double originalPrice;
  final String priceLabel;

  Booking({
    required this.id,
    required this.userId,
    required this.itemId,
    required this.itemName,
    required this.itemType,
    required this.petId,
    required this.startTime,
    required this.endTime,
    this.notes = '',
    this.status = BookingStatus.initiated,
    required this.originalPrice,
    required this.priceLabel,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Booking(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      itemId: data['itemId'] as String? ?? '',
      itemName: data['itemName'] as String? ?? 'Unnamed Item',
      itemType: data['itemType'] as String? ?? 'service',
      petId: data['petId'] as String? ?? '',
      startTime: data['startTime'] as Timestamp? ?? Timestamp.now(),
      endTime: data['endTime'] as Timestamp? ?? Timestamp.now(),
      notes: data['notes'] as String? ?? '',
      status: BookingStatusExtension.fromString(
        data['status'] as String? ?? 'initiated',
      ),
      originalPrice: (data['originalPrice'] as num?)?.toDouble() ?? 0.0,
      priceLabel: data['priceLabel'] as String? ?? '',
    );
  }

  // Convert booking to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'itemId': itemId,
      'itemName': itemName,
      'itemType': itemType,
      'petId': petId,
      'startTime': startTime,
      'endTime': endTime,
      'notes': notes,
      'status': status.value,
      'createdAt': FieldValue.serverTimestamp(),
      'originalPrice': originalPrice,
      'priceLabel': priceLabel,
    };
  }

  // Helper method to create a copy with updated status
  Booking copyWith({
    String? id,
    String? userId,
    String? itemId,
    String? itemName,
    String? itemType,
    String? petId,
    Timestamp? startTime,
    Timestamp? endTime,
    String? notes,
    BookingStatus? status,
    double? originalPrice,
    String? priceLabel,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      itemType: itemType ?? this.itemType,
      petId: petId ?? this.petId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      originalPrice: originalPrice ?? this.originalPrice,
      priceLabel: priceLabel ?? this.priceLabel,
    );
  }

  // Helper getters for backward compatibility
  String get serviceId => itemId;
  String get serviceName => itemName;
  bool get isService => itemType == 'service';
  bool get isPackage => itemType == 'package';

  // Helper getters for status checking
  bool get isInitiated => status == BookingStatus.initiated;
  bool get isConfirmed => status == BookingStatus.confirmed;
  bool get isCompleted => status == BookingStatus.completed;

  // Helper method to get status display text
  String get statusDisplayText {
    switch (status) {
      case BookingStatus.initiated:
        return 'Pending Confirmation';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.completed:
        return 'Completed';
    }
  }
}
