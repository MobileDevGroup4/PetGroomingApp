import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/package_card.dart';
import 'package_detail.dart';
import '../repositories/packages_repository.dart';
import '../models/package.dart';
import '../utils/package_diff.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = PackagesRepository();

    return Scaffold(
      appBar: AppBar(title: const Text('Admin dashboard'), centerTitle: true),
    );
  }
}
