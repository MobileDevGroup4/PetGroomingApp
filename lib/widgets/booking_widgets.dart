import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingCard extends StatelessWidget {
  final String userName;
  final String petName;
  final String serviceName;
  final Timestamp startTime;
  final Timestamp endTime;
  final String Function(Timestamp) formatDate;
  final String Function(Timestamp) formatTime;
  final String Function(Timestamp, Timestamp) calculateDuration;
  final VoidCallback? onTap; // ✅ Tap callback

  const BookingCard({
    super.key,
    required this.userName,
    required this.petName,
    required this.serviceName,
    required this.startTime,
    required this.endTime,
    required this.formatDate,
    required this.formatTime,
    required this.calculateDuration,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // ✅ Tap triggers navigation
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFE8F5E9),
                  child: Text(
                    userName[0].toUpperCase(),
                    style: const TextStyle(
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    Text(formatDate(startTime),
                        style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(serviceName,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black54)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTimeCard(
                      'Check In', formatTime(startTime), 'On time', const Color(0xFF4CAF50), Icons.login),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimeCard(
                      'Check Out', formatTime(endTime), 'On time', const Color(0xFFFF6B9D), Icons.logout),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Duration: ${calculateDuration(startTime, endTime)}'),
            Text('Pet: $petName'),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCard(
      String label, String time, String status, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ]),
          const SizedBox(height: 4),
          Text(time, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          Text(status, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}
