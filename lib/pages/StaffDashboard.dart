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

  /// 🔥 Optimized fetch with parallel queries and safe Map casting
  Future<List<Map<String, dynamic>>> _fetchBookings() async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .orderBy('startTime', descending: true)
          .get();

      final futures = snapshot.docs.map((doc) async {
        final data = doc.data();
        final userId = data['userId'] as String? ?? '';
        final petId = data['petId'] as String? ?? '';
        final itemId = data['itemId'] as String? ?? '';

        final profileFuture = userId.isNotEmpty
            ? _firestore.collection('profiles').doc(userId).get()
            : Future.value(null);

        final petFuture = (userId.isNotEmpty && petId.isNotEmpty)
            ? _firestore
                .collection('users')
                .doc(userId)
                .collection('pets')
                .doc(petId)
                .get()
            : Future.value(null);

        final packageFuture = itemId.isNotEmpty
            ? _firestore.collection('packages').doc(itemId).get()
            : Future.value(null);

        final results = await Future.wait([profileFuture, petFuture, packageFuture]);

        final profileDoc = results[0] as DocumentSnapshot?;
        final petDoc = results[1] as DocumentSnapshot?;
        final packageDoc = results[2] as DocumentSnapshot?;

        // ✅ Safe Map casting
        final userProfile = profileDoc != null && profileDoc.exists
            ? Map<String, dynamic>.from(profileDoc.data() as Map)
            : <String, dynamic>{};

        final petDataMap = petDoc != null && petDoc.exists
            ? Map<String, dynamic>.from(petDoc.data() as Map)
            : <String, dynamic>{};

        final packageDataMap = packageDoc != null && packageDoc.exists
            ? Map<String, dynamic>.from(packageDoc.data() as Map)
            : <String, dynamic>{};

        return {
          'bookingId': doc.id,
          'data': Map<String, dynamic>.from(data),
          'userProfile': userProfile,
          'petData': petDataMap,
          'packageData': packageDataMap,
        };
      }).toList();

      return await Future.wait(futures);
    } catch (e) {
      debugPrint('Error fetching bookings: $e');
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
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No bookings found.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final bookings = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {}); // Reload bookings
            },
            child: ListView.builder(
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
            ),
          );
        },
      ),
    );
  }
}
