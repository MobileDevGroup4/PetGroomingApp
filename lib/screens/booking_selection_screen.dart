import 'package:flutter/material.dart';

import '../models/service.dart';
import '../models/package.dart';
import '../services/booking_service.dart';
import 'date_time_screen.dart';

class BookingSelectionScreen extends StatefulWidget {
  const BookingSelectionScreen({super.key});

  @override
  State<BookingSelectionScreen> createState() => _BookingSelectionScreenState();
}

class _BookingSelectionScreenState extends State<BookingSelectionScreen> {
  bool _isLoadingServices = true;
  bool _isLoadingPackages = true;

  List<Service> _services = [];
  List<Package> _packages = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load services and packages in parallel
      final results = await Future.wait([_loadServices(), _loadPackages()]);

      setState(() {
        _services = results[0] as List<Service>;
        _packages = results[1] as List<Package>;
        _isLoadingServices = false;
        _isLoadingPackages = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingServices = false;
        _isLoadingPackages = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  Future<List<Service>> _loadServices() async {
    final bookingService = BookingService();
    return await bookingService.getServices();
  }

  Future<List<Package>> _loadPackages() async {
    final bookingService = BookingService();
    return await bookingService.getPackages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoadingServices || _isLoadingPackages
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service selection
                  _buildSectionHeader('Individual Services'),
                  const SizedBox(height: 12),

                  // TODO: add service list
                  const SizedBox(height: 32),

                  // Package selection
                  _buildSectionHeader('Packages Bundles'),
                  const SizedBox(height: 12),

                  // TODO: add package list
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }
}
