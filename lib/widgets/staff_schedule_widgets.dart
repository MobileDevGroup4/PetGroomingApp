import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Card showing current date & time
Widget currentTimeCard(DateTime currentTime) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(DateFormat('EEEE, MMM d').format(currentTime), style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            DateFormat('hh:mm:ss a').format(currentTime),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    )
  );
}

// Clock in/out card
Widget clockCard({
  required bool isClockedIn,
  DateTime? clockInTime,
  required String Function() getWorkingHours,
  required bool isWorkingToday,
  required VoidCallback onClockIn,
  required VoidCallback onClockOut,
}) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            isClockedIn ? 'Working: ${getWorkingHours()}' : 'Not Clocked In',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (isClockedIn && clockInTime != null) ...[
            const SizedBox(height: 8),
            Text('Since ${DateFormat('hh:mm a').format(clockInTime)}'),
          ],
          const SizedBox(height: 16),
          if (!isWorkingToday)
            const Text('You are not scheduled to work today', style: TextStyle(color: Colors.orange))
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isClockedIn ? onClockOut : onClockIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isClockedIn ? const Color.fromARGB(255, 17, 17, 17) : const Color(0xFF6C63FF),
                    foregroundColor: isClockedIn ? Colors.white : Colors.black,
                    padding: const EdgeInsets.all(16),
                ),
                child: Text(isClockedIn ? 'Clock Out' : 'Clock In', style: const TextStyle(fontSize: 18)),
              ),
            ),
        ],
      ),
    ),
  );
}

// Today's schedule card
Widget todayScheduleCard(Map<String, dynamic> todaySchedule) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Today\'s Schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text('Start', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(todaySchedule['startTime'] ?? 'N/A', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                children: [
                  const Text('End', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(todaySchedule['endTime'] ?? 'N/A', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

// Weekly schedule list
List<Widget> weeklyScheduleList(Map<String, dynamic> weeklySchedule, String currentDay) {
  return ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
      .map((day) {
        final schedule = weeklySchedule[day] as Map<String, dynamic>?;
        final isWorking = schedule?['isWorking'] ?? false;
        if (!isWorking) return const SizedBox.shrink();
        final isToday = day == currentDay;

        return Card(
          color: isToday ? Colors.blue.shade50 : null,
          child: ListTile(
            leading: Icon(Icons.check_circle, color: isToday ? Colors.blue : Colors.green),
            title: Text(day, style: TextStyle(fontWeight: isToday ? FontWeight.bold : FontWeight.normal)),
            trailing: Text('${schedule!['startTime']} - ${schedule['endTime']}', style: const TextStyle(fontSize: 16)),
          ),
        );
      }).toList();
}

// Clock In handler (logic separated)
Future<void> clockInHandler({
  required FirebaseAuth auth,
  required FirebaseFirestore firestore,
  required Map<String, dynamic> weeklySchedule,
  required String currentDay,
  required void Function(DateTime clockInTime, String shiftId) onSuccess,
}) async {
  final user = auth.currentUser;
  if (user == null) return;

  final daySchedule = weeklySchedule[currentDay] as Map<String, dynamic>?;
  if (daySchedule == null || !(daySchedule['isWorking'] ?? false)) return;

  try {
    final now = DateTime.now();
    final shiftRef = await firestore.collection('staff_shifts').add({
      'userId': user.uid,
      'clockInTime': Timestamp.fromDate(now),
      'clockOutTime': null,
      'date': DateFormat('yyyy-MM-dd').format(now),
      'dayOfWeek': currentDay,
    });
    onSuccess(now, shiftRef.id);
  } catch (e) {
    print('Error clocking in: $e');
  }
}

// Clock Out handler (logic separated)
Future<void> clockOutHandler({
  required FirebaseFirestore firestore,
  required String? activeShiftId,
  required DateTime? clockInTime,
  required VoidCallback onSuccess,
}) async {
  if (activeShiftId == null || clockInTime == null) return;

  try {
    final now = DateTime.now();
    await firestore.collection('staff_shifts').doc(activeShiftId).update({'clockOutTime': Timestamp.fromDate(now)});
    onSuccess();
  } catch (e) {
    print('Error clocking out: $e');
  }
}
