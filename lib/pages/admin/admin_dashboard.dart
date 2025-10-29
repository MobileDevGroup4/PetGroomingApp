import 'dart:async';
import 'package:flutter/material.dart';
import '../../../repositories/profiles_repository.dart';
import 'admin_profiles_page.dart';
import 'register_staff_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _searchCtrl = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;

  bool _onlyStaff = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  String get _search => _searchCtrl.text;

  @override
  Widget build(BuildContext context) {
    final stream = ProfilesRepository().streamProfiles(onlyStaff: _onlyStaff);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Register new staff',
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RegisterStaffPage()),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: _SearchField(
                    controller: _searchCtrl,
                    focusNode: _focus,
                    onClear: () {
                      _searchCtrl.clear();
                      _focus.requestFocus();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Staff-only toggle
                Row(
                  children: [
                    const Text('Staff only'),
                    const SizedBox(width: 6),
                    Switch.adaptive(
                      value: _onlyStaff,
                      onChanged: (v) => setState(() => _onlyStaff = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: AdminProfilesPage(
        stream: stream,
        collection: 'profiles',
        search: _search,
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: const Text('Register staff'),
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const RegisterStaffPage()));
        },
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search by name or email',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.clear),
                onPressed: onClear,
              ),
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      onSubmitted: (_) => FocusScope.of(context).unfocus(),
    );
  }
}
