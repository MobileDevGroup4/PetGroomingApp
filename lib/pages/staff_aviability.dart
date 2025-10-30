import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/availability_service.dart';
import '../widgets/day_off_dialog.dart';
import '../widgets/working_hours_card.dart';

class StaffAvailability extends StatefulWidget {
  const StaffAvailability({super.key});

  @override
  State<StaffAvailability> createState() => _StaffAvailabilityState();
}

class _StaffAvailabilityState extends State<StaffAvailability> {
  final service = AvailabilityService();
  bool _isLoading = false;
  Map<String, Map<String, dynamic>> _workingHours = {};
  List<Map<String, dynamic>> _daysOff = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _workingHours = await service.getWorkingHours();
    _daysOff = await service.getDaysOff();
    setState(() => _isLoading = false);
  }

  Future<void> _saveHours() async {
    setState(() => _isLoading = true);
    try {
      await service.saveWorkingHours(_workingHours);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Working hours saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateWorkingHours(Map<String, Map<String, dynamic>> hours) {
    setState(() => _workingHours = hours);
  }

  Future<void> _addDayOff() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const DayOffDialog(),
    );

    if (result != null) {
      setState(() => _isLoading = true);
      try {
        await service.addDayOff(result);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Day off added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteDayOff(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Day Off'),
        content: const Text('Are you sure you want to delete this day off?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await service.deleteDayOff(id);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Day off deleted'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildSectionHeader('Weekly Schedule', Icons.schedule),
                  const SizedBox(height: 16),
                  WorkingHoursCard(
                    workingHours: _workingHours,
                    onWorkingHoursChanged: _updateWorkingHours,
                    onSave: _saveHours,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Days Off & Vacation', Icons.event_busy),
                  const SizedBox(height: 16),
                  _buildDaysOffCard(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.green.shade700, size: 28),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDaysOffCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_daysOff.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.event_available,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No days off scheduled',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          else
            ..._daysOff.map((dayOff) => _buildDayOffItem(dayOff)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _addDayOff,
            icon: const Icon(Icons.add),
            label: const Text('Add Day Off / Vacation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayOffItem(Map<String, dynamic> dayOff) {
    final startDate = (dayOff['startDate'] as Timestamp).toDate();
    final endDate = (dayOff['endDate'] as Timestamp).toDate();
    final reason = dayOff['reason'] as String? ?? 'No reason';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.event_busy, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${DateFormat('MMM dd, yyyy').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _deleteDayOff(dayOff['id']),
          ),
        ],
      ),
    );
  }
}
