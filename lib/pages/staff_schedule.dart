import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../widgets/staff_schedule_widgets.dart';


class StaffSchedulePage extends StatefulWidget {
  const StaffSchedulePage({super.key});

  @override
  State<StaffSchedulePage> createState() => _StaffSchedulePageState();
}

class _StaffSchedulePageState extends State<StaffSchedulePage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  Map<String, dynamic> _weeklySchedule = {};
  String _currentDay = '';
  Timer? _timer;
  DateTime _currentTime = DateTime.now();

  bool _isClockedIn = false;
  DateTime? _clockInTime;
  String? _activeShiftId;

  @override
  void initState() {
    super.initState();
    _currentDay = DateFormat('EEEE').format(DateTime.now());
    _loadSchedule();
    _checkActiveShift();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _currentTime = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Load weekly schedule from Firestore
  Future<void> _loadSchedule() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final doc = await _firestore
          .collection('staff_availability')
          .doc(user.uid)
          .collection('working_hours')
          .doc('schedule')
          .get();

      if (doc.exists) {
        setState(() {
          _weeklySchedule = doc.data() ?? {};
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // Check if the staff is currently clocked in
  Future<void> _checkActiveShift() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _firestore
          .collection('staff_shifts')
          .where('userId', isEqualTo: user.uid)
          .where('clockOutTime', isNull: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final shift = snapshot.docs.first;
        final data = shift.data();
        setState(() {
          _isClockedIn = true;
          _clockInTime = (data['clockInTime'] as Timestamp).toDate();
          _activeShiftId = shift.id;
        });
      }
    } catch (e) {
      print('Error checking shift: $e');
    }
  }

  Future<void> _clockIn() async => clockInHandler(
        auth: _auth,
        firestore: _firestore,
        weeklySchedule: _weeklySchedule,
        currentDay: _currentDay,
        onSuccess: (clockInTime, shiftId) {
          setState(() {
            _isClockedIn = true;
            _clockInTime = clockInTime;
            _activeShiftId = shiftId;
          });
        },
      );

  Future<void> _clockOut() async => clockOutHandler(
        firestore: _firestore,
        activeShiftId: _activeShiftId,
        clockInTime: _clockInTime,
        onSuccess: () {
          setState(() {
            _isClockedIn = false;
            _clockInTime = null;
            _activeShiftId = null;
          });
        },
      );

  String _getWorkingHours() {
    if (_clockInTime == null) return '0h 0m';
    final duration = _currentTime.difference(_clockInTime!);
    return '${duration.inHours}h ${duration.inMinutes % 60}m';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final todaySchedule = _weeklySchedule[_currentDay] as Map<String, dynamic>?;
    final isWorkingToday = todaySchedule?['isWorking'] ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadSchedule();
              _checkActiveShift();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          currentTimeCard(_currentTime),
          const SizedBox(height: 16),
          clockCard(
            isClockedIn: _isClockedIn,
            clockInTime: _clockInTime,
            getWorkingHours: _getWorkingHours,
            isWorkingToday: isWorkingToday,
            onClockIn: _clockIn,
            onClockOut: _clockOut,
          ),
          const SizedBox(height: 16),
          if (isWorkingToday) todayScheduleCard(todaySchedule!),
          const SizedBox(height: 16),
          const Text('Weekly Schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...weeklyScheduleList(_weeklySchedule, _currentDay),
        ],
      ),
    );
  }
}
