import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BookingDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;
  final String bookingId;
  final String userName;
  final String petName;
  final String userId;
  final String petId;

  const BookingDetailPage({
    super.key,
    required this.data,
    required this.bookingId,
    required this.userName,
    required this.petName,
    required this.userId,
    required this.petId,
  });

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown Date';
    return DateFormat('EEEE, dd MMM yyyy').format(timestamp.toDate());
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
    // Null-safe values
    final safeUserName = (userName.isNotEmpty) ? userName : 'Unknown User';
    final safePetName = (petName.isNotEmpty) ? petName : 'Unknown Pet';
    final safeServiceName = (data['itemName']?.toString() ?? 'Unknown Service');
    final startTime = data['startTime'] as Timestamp?;
    final endTime = data['endTime'] as Timestamp?;
    final createdAt = data['createdAt'] as Timestamp?;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('pets')
            .doc(petId)
            .get(),
        builder: (context, petSnapshot) {
          Map<String, dynamic>? petData;
          
          if (petSnapshot.hasData && petSnapshot.data != null) {
            petData = petSnapshot.data!.data() as Map<String, dynamic>?;
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _BookingInfoHeader(userName: safeUserName, date: formatDate(startTime)),
                  const SizedBox(height: 16),
                  
                  // Booking Information
                  _InfoCard(children: [
                    _InfoRow(label: 'Service', value: safeServiceName),
                    const Divider(height: 24),
                    _InfoRow(label: 'Pet Name', value: safePetName),
                    const Divider(height: 24),
                    _InfoRow(label: 'Booking ID', value: bookingId.isNotEmpty ? bookingId : 'Unknown ID'),
                    const Divider(height: 24),
                    _InfoRow(label: 'Booking Created', value: '${formatDate(createdAt)} ${formatTime(createdAt)}'),
                  ]),
                  
                  const SizedBox(height: 16),
                  
                  // Check In/Out Times
                  Row(
                    children: [
                      Expanded(
                        child: _TimeCard(
                          label: 'Check In',
                          time: formatTime(startTime),
                          status: 'On time',
                          color: const Color(0xFF4CAF50),
                          icon: Icons.login,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TimeCard(
                          label: 'Check Out',
                          time: formatTime(endTime),
                          status: 'On time',
                          color: const Color(0xFFFF6B9D),
                          icon: Icons.logout,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Duration
                  _InfoCard(children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.timer_outlined, color: Color(0xFFFF9800), size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            calculateDuration(startTime, endTime),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ]),
                  
                  // Pet Details Section
                  if (petData != null) ...[
                    const SizedBox(height: 24),
                    _SectionHeader(title: 'Pet Information', icon: Icons.pets),
                    const SizedBox(height: 12),
                    _InfoCard(children: [
                      _InfoRow(label: 'Name', value: petData['name']?.toString() ?? 'N/A'),
                      const Divider(height: 24),
                      _InfoRow(label: 'Breed', value: petData['breed']?.toString() ?? 'N/A'),
                      const Divider(height: 24),
                      _InfoRow(label: 'Age', value: '${petData['age']?.toString() ?? 'N/A'} years'),
                      const Divider(height: 24),
                      _InfoRow(label: 'Colour', value: petData['colour']?.toString() ?? 'N/A'),
                      const Divider(height: 24),
                      _InfoRow(label: 'Size', value: petData['size']?.toString() ?? 'N/A'),
                      const Divider(height: 24),
                      _InfoRow(label: 'Weight', value: '${petData['weight']?.toString() ?? 'N/A'} kg'),
                      if (petData['preferences'] != null && petData['preferences'].toString().isNotEmpty) ...[
                        const Divider(height: 24),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Preferences', style: TextStyle(fontSize: 14, color: Colors.black54)),
                            const SizedBox(height: 8),
                            Text(
                              petData['preferences'].toString(),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ]),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ------------------ Small Reusable Widgets ------------------

class _BookingInfoHeader extends StatelessWidget {
  final String userName;
  final String date;
  const _BookingInfoHeader({required this.userName, required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFFE8F5E9),
            child: Text(userName[0].toUpperCase(),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50))),
          ),
          const SizedBox(height: 16),
          Text(userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(date, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF4CAF50), size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 14, color: Colors.black54)),
      Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
    ]);
  }
}

class _TimeCard extends StatelessWidget {
  final String label;
  final String time;
  final String status;
  final Color color;
  final IconData icon;

  const _TimeCard({required this.label, required this.time, required this.status, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
        ]),
        const SizedBox(height: 12),
        Text(time, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(status, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ]),
    );
  }
}