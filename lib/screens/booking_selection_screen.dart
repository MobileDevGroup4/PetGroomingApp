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

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _services.length,
                    itemBuilder: (context, index) {
                      final service = _services[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          title: Text(
                            service.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${service.description}\nDuration: ${service.duration} minutes',
                          ),
                          trailing: Text(
                            '${service.price.toStringAsFixed(2)} CHF',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DateTimeScreen(service: service),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Package selection
                  _buildSectionHeader('Packages Bundles'),
                  const SizedBox(height: 12),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _packages.length,
                    itemBuilder: (context, index) {
                      final package = _packages[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DateTimeScreen(package: package),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header row: Badge + Duration
                                Row(
                                  children: [
                                    // Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: Colors.black12,
                                        ),
                                        color: Colors.grey[100],
                                      ),
                                      child: Text(
                                        package.badge,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    // Duration
                                    const Icon(Icons.schedule, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${package.durationMinutes} min',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Package name
                                Text(
                                  package.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Short description
                                Text(
                                  package.shortDescription,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Price (at bottom)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFFFC107,
                                    ).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFFFC107,
                                      ).withValues(alpha: 0.6),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    package.priceLabel,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
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
