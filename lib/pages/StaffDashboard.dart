import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'booking_detail_page.dart';

class StaffDashboardPage extends StatelessWidget {
  const StaffDashboardPage({super.key});

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown Date';
    return DateFormat('dd MMM yyyy').format(timestamp.toDate());
  }

  String formatTime(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown Time';
    return DateFormat('hh:mm a').format(timestamp.toDate());
  }

  String calculateDuration(Timestamp? start, Timestamp? end) {
    if (start == null || end == null) return 'Unknown Duration';
    final duration = end.toDate().difference(start.toDate());
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Staff Dashboard',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No bookings yet', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                ],
              ),
            );
          }

          final bookings = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final data = bookings[index].data() as Map<String, dynamic>;
              final bookingId = bookings[index].id;

              // Extract booking data
              final userId = data['userId']?.toString() ?? '';
              final petId = data['petId']?.toString() ?? '';
              final serviceName = data['itemName']?.toString() ?? 'Unknown Service';
              final startTime = data['startTime'] as Timestamp?;
              final endTime = data['endTime'] as Timestamp?;

              return FutureBuilder<Map<String, String>>(
                future: _fetchUserAndPetData(userId, petId),
                builder: (context, userPetSnapshot) {
                  if (userPetSnapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }

                  final userPetData = userPetSnapshot.data ?? {'userName': 'Unknown User', 'petName': 'Unknown Pet'};
                  final userName = userPetData['userName'] ?? 'Unknown User';
                  final petName = userPetData['petName'] ?? 'Unknown Pet';

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingDetailPage(
                            data: data,
                            bookingId: bookingId,
                            userName: userName,
                            petName: petName,
                            userId: userId,
                            petId: petId,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with user name and date
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: const Color(0xFFE8F5E9),
                                child: Text(userName[0].toUpperCase(), style: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold, fontSize: 18)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(userName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                                    Text(formatDate(startTime), style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Service name
                          Text(serviceName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black54)),
                          const SizedBox(height: 12),
                          // Time cards
                          Row(
                            children: [
                              Expanded(
                                child: _buildTimeCard('Check In', formatTime(startTime), const Color(0xFF4CAF50), Icons.login),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTimeCard('Check Out', formatTime(endTime), const Color(0xFFFF6B9D), Icons.logout),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Duration and pet name
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(calculateDuration(startTime, endTime), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              Text('Pet: $petName', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<Map<String, String>> _fetchUserAndPetData(String userId, String petId) async {
    try {
      String userName = 'Unknown User';
      String petName = 'Unknown Pet';

      // Fetch user name
      if (userId.isNotEmpty) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        
        if (userDoc.exists) {
          userName = userDoc.data()?['name']?.toString() ?? 
                     userDoc.data()?['displayName']?.toString() ?? 
                     userDoc.data()?['email']?.toString() ?? 
                     'Unknown User';
        }
      }

      // Fetch pet name
      if (userId.isNotEmpty && petId.isNotEmpty) {
        final petDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('pets')
            .doc(petId)
            .get();
        
        if (petDoc.exists) {
          petName = petDoc.data()?['name']?.toString() ?? 'Unknown Pet';
        }
      }

      return {'userName': userName, 'petName': petName};
    } catch (e) {
      print('Error fetching user/pet data: $e');
      return {'userName': 'Unknown User', 'petName': 'Unknown Pet'};
    }
  }

  Widget _buildTimeCard(String label, String time, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ]),
          const SizedBox(height: 8),
          Text(time, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }
}