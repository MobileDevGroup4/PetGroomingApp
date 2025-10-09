import 'package:flutter/material.dart';

import '../models/service.dart';
import '../services/booking_service.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final BookingService _bookingService = BookingService();
  late Future<List<Service>> _servicesFuture;

  @override
  void initState() {
    super.initState();
    // Fetch services when the widget is initialized.
    _servicesFuture = _bookingService.getServices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a service'),
        backgroundColor: Colors.greenAccent[50],
      ),
      body: FutureBuilder<List<Service>>(
        future: _servicesFuture,
        builder: (context, snapshot) {
          // 1. Show a loading indicator while data is being fetched.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // 2. Show an error messgage if something went wrong
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          // 3. Hansle the case where no services are found
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No services available at the mometn.'));
          }
          
          // 4. If data is available, display it in a list
          List<Service> services = snapshot.data!;
          return ListView.builder(
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16 , vertical: 8),
                child: ListTile(
                  title: Text(service.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${service.description}\nDuration: ${service.duration} minutes'),
                  trailing: Text(
                      '${service.price.toStringAsFixed(2)} CHF',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
              ),
                  onTap: () {
                  // TODO: Navigate to next step of the booking process
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Selected ${service.name}')),
                    );
                  },
              ),
              );
            },
          );
        },
      ),
    );
  }
}