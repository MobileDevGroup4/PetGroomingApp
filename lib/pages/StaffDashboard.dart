import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/booking_widgets.dart';
import 'booking_detail_page.dart';
import 'package:intl/intl.dart';


class StaffDashboardPage extends StatefulWidget {
  const StaffDashboardPage({super.key});

  @override
  State<StaffDashboardPage> createState() => _StaffDashboardPageState();
}

class _StaffDashboardPageState extends State<StaffDashboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> _fetchBookings() async {
    try {
      final snapshot = await _firestore.collection('bookings').orderBy('startTime', descending: true).get();

      List<Map<String, dynamic>> bookings = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String? ?? '';
        final petId = data['petId'] as String? ?? '';
        final itemId = data['itemId'] as String? ?? '';

        // Fetch user profile
        Map<String, dynamic> userProfile = {};
        if (userId.isNotEmpty) {
          final profileDoc = await _firestore.collection('profiles').doc(userId).get();
          if (profileDoc.exists) userProfile = profileDoc.data()!;
        }

        // Fetch pet info
        Map<String, dynamic> petData = {};
        if (userId.isNotEmpty && petId.isNotEmpty) {
          final petDoc = await _firestore
              .collection('users')
              .doc(userId)
              .collection('pets')
              .doc(petId)
              .get();
          if (petDoc.exists) petData = petDoc.data()!;
        }

        // Fetch package info
        Map<String, dynamic> packageData = {};
        if (itemId.isNotEmpty) {
          final packageDoc = await _firestore.collection('packages').doc(itemId).get();
          if (packageDoc.exists) packageData = packageDoc.data()!;
        }

        bookings.add({
          'bookingId': doc.id,
          'data': data,
          'userProfile': userProfile,
          'petData': petData,
          'packageData': packageData,
        });
      }

      return bookings;
    } catch (e) {
      print('Error fetching bookings: $e');
      return [];
    }
  }

  String _formatDate(Timestamp? t) =>
      t == null ? 'N/A' : DateFormat('dd MMM yyyy').format(t.toDate());

  String _formatTime(Timestamp? t) =>
      t == null ? 'N/A' : DateFormat('hh:mm a').format(t.toDate());

  String _duration(Timestamp? s, Timestamp? e) {
    if (s == null || e == null) return 'N/A';
    final d = e.toDate().difference(s.toDate());
    return d.inHours > 0 ? '${d.inHours}h ${d.inMinutes % 60}m' : '${d.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Dashboard'),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No bookings found.'));
          }

          final bookings = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              final data = booking['data'] as Map<String, dynamic>;
              final userProfile = booking['userProfile'] as Map<String, dynamic>;
              final petData = booking['petData'] as Map<String, dynamic>;
              final packageData = booking['packageData'] as Map<String, dynamic>;

              final userName = userProfile['name']?.toString() ?? 'Unknown';
              final petName = petData['name']?.toString() ?? 'Unknown';
              final services = (packageData['services'] as List<dynamic>? ?? []).join(', ');

              final start = data['startTime'] as Timestamp?;
              final end = data['endTime'] as Timestamp?;

              return BookingCard(
                userName: userName,
                petName: petName,
                serviceName: packageData['name']?.toString() ?? 'Unknown',
                startTime: start ?? Timestamp.now(),
                endTime: end ?? Timestamp.now(),
                formatDate: _formatDate,
                formatTime: _formatTime,
                calculateDuration: _duration,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingDetailPage(
                      data: data,
                      bookingId: booking['bookingId'] as String,
                      userName: userName,
                      petName: petName,
                      userId: data['userId'] ?? '',
                      petId: data['petId'] ?? '',
                      petData: petData,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
