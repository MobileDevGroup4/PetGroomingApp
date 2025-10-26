import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/admin/admin_register_staff_card.dart';

class RegisterStaffPage extends StatelessWidget {
  const RegisterStaffPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register New Staff')),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: AdminRegisterStaffCard(),
        ),
      ),
    );
  }
}
