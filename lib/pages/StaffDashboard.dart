import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../widgets/booking_widgets.dart';
import 'booking_detail_page.dart';

enum BookingFilter { today, thisWeek, nextWeek, all }

class StaffDashboardPage extends StatefulWidget {
  const StaffDashboardPage({super.key});

  @override
  State<StaffDashboardPage> createState() => _StaffDashboardPageState();
}

class _StaffDashboardPageState extends State<StaffDashboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  BookingFilter _selectedFilter = BookingFilter.all;

  static const Color primaryPurple = Color(0xFF6C63FF);
  static const Color lightPurpleBackground = Color(0xFFFAF4FA);

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

        return {
          'bookingId': doc.id,
          'data': Map<String, dynamic>.from(data),
          'userProfile': profileDoc != null && profileDoc.exists
              ? Map<String, dynamic>.from(profileDoc.data() as Map)
              : <String, dynamic>{},
          'petData': petDoc != null && petDoc.exists
              ? Map<String, dynamic>.from(petDoc.data() as Map)
              : <String, dynamic>{},
          'packageData': packageDoc != null && packageDoc.exists
              ? Map<String, dynamic>.from(packageDoc.data() as Map)
              : <String, dynamic>{},
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

  bool _matchesFilter(Timestamp? startTime) {
    if (startTime == null) return false;
    final date = startTime.toDate();
    final now = DateTime.now();

    switch (_selectedFilter) {
      case BookingFilter.today:
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      case BookingFilter.thisWeek:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
            date.isBefore(endOfWeek.add(const Duration(days: 1)));
      case BookingFilter.nextWeek:
        final startOfNextWeek = now.add(Duration(days: 8 - now.weekday));
        final endOfNextWeek = startOfNextWeek.add(const Duration(days: 6));
        return date.isAfter(startOfNextWeek.subtract(const Duration(seconds: 1))) &&
            date.isBefore(endOfNextWeek.add(const Duration(days: 1)));
      case BookingFilter.all:
        return true;
    }
  }

  String _getFilterLabel(BookingFilter filter) {
    switch (filter) {
      case BookingFilter.today:
        return 'Today';
      case BookingFilter.thisWeek:
        return 'This Week';
      case BookingFilter.nextWeek:
        return 'Next Week';
      case BookingFilter.all:
        return 'All';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightPurpleBackground,
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: BookingFilter.values.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(_getFilterLabel(filter)),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    selectedColor: primaryPurple,
                    backgroundColor: Colors.grey[200],
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Booking List
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchBookings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No bookings found.'));
                }

                final allBookings = snapshot.data!;
                final filteredBookings = allBookings
                    .where((b) => _matchesFilter(b['data']['startTime'] as Timestamp?))
                    .toList();

                if (filteredBookings.isEmpty) {
                  return Center(
                    child: Text(
                      'No appointments for ${_getFilterLabel(_selectedFilter).toLowerCase()}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: primaryPurple,
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredBookings.length,
                    itemBuilder: (context, index) {
                      final booking = filteredBookings[index];
                      final data = booking['data'] as Map<String, dynamic>;
                      final userProfile = booking['userProfile'] as Map<String, dynamic>;
                      final petData = booking['petData'] as Map<String, dynamic>;
                      final packageData = booking['packageData'] as Map<String, dynamic>;

                      return BookingCard(
                        userName: userProfile['name'] ?? 'Unknown',
                        petName: petData['name'] ?? 'Unknown',
                        serviceName: packageData['name'] ?? 'Unknown',
                        startTime: data['startTime'] ?? Timestamp.now(),
                        endTime: data['endTime'] ?? Timestamp.now(),
                        status: data['status'] as String?, 
                        formatDate: _formatDate,
                        formatTime: _formatTime,
                        calculateDuration: _duration,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookingDetailPage(
                                data: data,
                                bookingId: booking['bookingId'],
                                userName: userProfile['name'] ?? 'Unknown',
                                petName: petData['name'] ?? 'Unknown',
                                userId: data['userId'] ?? '',
                                petId: data['petId'] ?? '',
                                petData: petData,
                              ),
                            ),
                          ).then((_) => setState(() {}));
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
