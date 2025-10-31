import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';


class BookingDetailPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final String bookingId, userName, petName, userId, petId;
  final Map<String, dynamic>? petData;

  const BookingDetailPage({
    super.key,
    required this.data,
    required this.bookingId,
    required this.userName,
    required this.petName,
    required this.userId,
    required this.petId,
    this.petData,
  });

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  bool _isUpdating = false;
  String? _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.data['status'] as String?;
  }

  String _date(Timestamp? t) =>
      t == null ? 'N/A' : DateFormat('EEEE, dd MMM yyyy').format(t.toDate());
  String _time(Timestamp? t) =>
      t == null ? 'N/A' : DateFormat('hh:mm a').format(t.toDate());
  String _duration(Timestamp? s, Timestamp? e) {
    if (s == null || e == null) return 'N/A';
    final d = e.toDate().difference(s.toDate());
    return d.inHours > 0 ? '${d.inHours}h ${d.inMinutes % 60}m' : '${d.inMinutes}m';
  }

  Future<Map<String, dynamic>> _fetchPackageInfo(String itemId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('packages')
          .doc(itemId)
          .get();
      if (doc.exists) return doc.data()!;
    } catch (e) {
      print('Error fetching package info: $e');
    }
    return {'name': 'Unknown', 'services': []};
  }

  Future<void> _updateBookingStatus(String newStatus) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _currentStatus = newStatus;
        _isUpdating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking status updated to ${_getStatusLabel(newStatus)}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUpdating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showStatusUpdateDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Booking Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select the new status for this booking:'),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green, size: 32),
                title: const Text('Completed', style: TextStyle(fontWeight: FontWeight.bold)),
                tileColor: Colors.green.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.green.withOpacity(0.3)),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _updateBookingStatus('completed');
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red, size: 32),
                title: const Text('Cancelled', style: TextStyle(fontWeight: FontWeight.bold)),
                tileColor: Colors.red.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.red.withOpacity(0.3)),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _updateBookingStatus('cancelled');
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  String _getStatusLabel(String? status) {
    if (status == null) return 'Pending';
    switch (status.toLowerCase()) {
      case 'started':
        return 'Started';
      case 'inprogress':
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Pending';
    }
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    switch (status.toLowerCase()) {
      case 'started':
        return Colors.blue;
      case 'inprogress':
      case 'in_progress':
        return const Color(0xFF6C63FF);
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final start = widget.data['startTime'] as Timestamp?;
    final end = widget.data['endTime'] as Timestamp?;
    final notes = widget.data['notes'] as String?;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchPackageInfo(widget.data['itemId'] ?? ''),
        builder: (context, snapshot) {
          final packageData = snapshot.data ?? {'services': []};
          final services = (packageData['services'] as List<dynamic>)
              .map((e) => e.toString())
              .join(', ');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _header(start, services),
                const SizedBox(height: 16),
                _statusCard(),
                const SizedBox(height: 16),
                _card([
                  _row('Service', widget.data['itemName'] ?? 'Unknown'),
                  const Divider(height: 24),
                  _row('Pet Name', widget.petName),
                  const Divider(height: 24),
                  _row('Booking ID', widget.bookingId.substring(0, 8)),
                  const Divider(height: 24),
                  _row('Created', '${_date(widget.data['createdAt'] as Timestamp?)}\n${_time(widget.data['createdAt'] as Timestamp?)}'),
                ]),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _timeCard('Check In', _time(start), _date(start), const Color(0xFF4CAF50), Icons.login)),
                    const SizedBox(width: 12),
                    Expanded(child: _timeCard('Check Out', _time(end), _date(end), const Color(0xFFFF6B9D), Icons.logout)),
                  ],
                ),
                const SizedBox(height: 16),
                _card([
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.timer_outlined, color: Color(0xFFFF9800), size: 24),
                      ),
                      const SizedBox(width: 16),
                      Text(_duration(start, end), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ]),
                // Notes Section
                if (notes != null && notes.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _sectionHeader('Customer Notes', Icons.note_alt_outlined),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF6C63FF).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.notes,
                            color: Color(0xFF6C63FF),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            notes,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (widget.petData != null) ...[
                  const SizedBox(height: 24),
                  _sectionHeader('Pet Information', Icons.pets),
                  const SizedBox(height: 12),
                  _card([
                    _detail(Icons.badge_outlined, 'Name', widget.petData!['name']?.toString() ?? 'N/A', const Color(0xFF4CAF50)),
                    const Divider(height: 24),
                    _detail(Icons.category_outlined, 'Breed', widget.petData!['breed']?.toString() ?? 'N/A', const Color(0xFF2196F3)),
                    const Divider(height: 24),
                    _detail(Icons.cake_outlined, 'Age', widget.petData!['age']?.toString() ?? 'N/A', const Color(0xFFFF9800)),
                    const Divider(height: 24),
                    _detail(Icons.color_lens_outlined, 'Colour', widget.petData!['colour']?.toString() ?? 'N/A', const Color(0xFFFF5722)),
                    const Divider(height: 24),
                    _detail(Icons.scale_outlined, 'Weight', widget.petData!['weight']?.toString() ?? 'N/A', const Color(0xFF9C27B0)),
                    const Divider(height: 24),
                    _detail(Icons.favorite_outline, 'Preferences', widget.petData!['preferences']?.toString() ?? 'N/A', const Color(0xFFE91E63)),
                  ]),
                ],
                const SizedBox(height: 24),
                _updateStatusButton(),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statusCard() => Container(
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Current Status:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getStatusColor(_currentStatus).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getStatusColor(_currentStatus),
                  width: 1.5,
                ),
              ),
              child: Text(
                _getStatusLabel(_currentStatus),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(_currentStatus),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _updateStatusButton() => SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _isUpdating ? null : _showStatusUpdateDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: _isUpdating
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.update, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Update Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      );

  Widget _header(Timestamp? start, String services) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF4CAF50), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.white, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(services, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_date(start), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _card(List<Widget> children) => Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(children: children),
      );

  Widget _row(String title, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      );

  Widget _timeCard(String label, String time, String date, Color color, IconData icon) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 8),
            Text(time, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(date, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      );

  Widget _sectionHeader(String title, IconData icon) => Row(
        children: [
          Icon(icon, color: Colors.black54),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      );

  Widget _detail(IconData icon, String title, String value, Color color) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      );
}