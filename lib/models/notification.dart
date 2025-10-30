import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String type; // 'booking', 'cancellation', 'reschedule'

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
    required this.type,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      type: data['type'] ?? 'booking',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'type': type,
    };
  }
}
