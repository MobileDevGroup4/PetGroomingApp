import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AvailabilityService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<Map<String, Map<String, dynamic>>> getWorkingHours() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final doc = await _firestore
          .collection('staff_availability')
          .doc(user.uid)
          .collection('working_hours')
          .doc('schedule')
          .get();

      if (doc.exists) {
        return Map<String, Map<String, dynamic>>.from(
          doc.data()!.map(
            (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
          ),
        );
      }

      // Default working hours
      return {
        for (var day in ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'])
          day: {'isWorking': true, 'startTime': '09:00', 'endTime': '17:00'},
      };
    } catch (e) {
      print('Error getting working hours: $e');
      return {};
    }
  }

  Future<void> saveWorkingHours(Map<String, Map<String, dynamic>> hours) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore
          .collection('staff_availability')
          .doc(user.uid)
          .collection('working_hours')
          .doc('schedule')
          .set(hours);
    } catch (e) {
      print('Error saving working hours: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getDaysOff() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('staff_availability')
          .doc(user.uid)
          .collection('days_off')
          .orderBy('startDate', descending: false)
          .get();

      return snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (e) {
      print('Error getting days off: $e');
      return [];
    }
  }

  Future<void> addDayOff(Map<String, dynamic> data) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore
          .collection('staff_availability')
          .doc(user.uid)
          .collection('days_off')
          .add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding day off: $e');
      rethrow;
    }
  }

  Future<void> deleteDayOff(String id) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore
          .collection('staff_availability')
          .doc(user.uid)
          .collection('days_off')
          .doc(id)
          .delete();
    } catch (e) {
      print('Error deleting day off: $e');
      rethrow;
    }
  }

  /// Check if staff is available at a specific date/time
  Future<bool> isStaffAvailable(String staffId, DateTime bookingDateTime) async {
    try {
      final dayOfWeek = _getDayOfWeek(bookingDateTime);

      // Check working hours
      final workingHoursDoc = await _firestore
          .collection('staff_availability')
          .doc(staffId)
          .collection('working_hours')
          .doc('schedule')
          .get();

      if (!workingHoursDoc.exists) return true;

      final schedule = workingHoursDoc.data()!;
      final daySchedule = schedule[dayOfWeek] as Map<String, dynamic>?;

      if (daySchedule == null || !(daySchedule['isWorking'] ?? false)) {
        return false;
      }

      // Check time range
      if (!_isTimeInRange(bookingDateTime, daySchedule)) {
        return false;
      }

      // Check days off
      final daysOffSnapshot = await _firestore
          .collection('staff_availability')
          .doc(staffId)
          .collection('days_off')
          .get();

      for (var doc in daysOffSnapshot.docs) {
        if (_isDateInRange(bookingDateTime, doc.data())) {
          return false;
        }
      }

      return true;
    } catch (e) {
      print('Error checking availability: $e');
      return false;
    }
  }

  String _getDayOfWeek(DateTime date) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }

  bool _isTimeInRange(DateTime dateTime, Map<String, dynamic> daySchedule) {
    final startParts = (daySchedule['startTime'] as String).split(':');
    final endParts = (daySchedule['endTime'] as String).split(':');

    final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
    final bookingMinutes = dateTime.hour * 60 + dateTime.minute;

    return bookingMinutes >= startMinutes && bookingMinutes < endMinutes;
  }

  bool _isDateInRange(DateTime date, Map<String, dynamic> dayOff) {
    final startDate = (dayOff['startDate'] as Timestamp).toDate();
    final endDate = (dayOff['endDate'] as Timestamp).toDate();

    return date.isAfter(startDate.subtract(const Duration(days: 1))) &&
        date.isBefore(endDate.add(const Duration(days: 1)));
  }
}