import 'package:flutter/material.dart';
import 'package:flutter_app/services/staff_registration_service.dart';

class AdminRegisterStaffCard extends StatefulWidget {
  const AdminRegisterStaffCard({super.key});
  @override
  State<AdminRegisterStaffCard> createState() => _AdminRegisterStaffCardState();
}

class _AdminRegisterStaffCardState extends State<AdminRegisterStaffCard> {
  final _f = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _tempPw = TextEditingController();

  bool _busy = false;
  bool _pwObscured = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _tempPw.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_f.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final uid = await StaffRegistrationService.createAuthUserAndProfile(
        name: _name.text,
        email: _email.text,
        tempPassword: _tempPw.text, // REQUIRED now
        phone: _phone.text.isEmpty ? null : _phone.text,
        address: _address.text.isEmpty ? null : _address.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Staff created (uid: $uid)')));

      _f.currentState!.reset();
      _name.clear();
      _email.clear();
      _phone.clear();
      _address.clear();
      _tempPw.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _f,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Register new staff',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name required' : null,
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: _email,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  final s = v?.trim() ?? '';
                  if (s.isEmpty) return 'Email required';
                  final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(s);
                  return ok ? null : 'Invalid email';
                },
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(
                  labelText: 'Phone (optional)',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: _address,
                decoration: const InputDecoration(
                  labelText: 'Address (optional)',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const Divider(height: 24),

              TextFormField(
                controller: _tempPw,
                obscureText: _pwObscured,
                decoration: InputDecoration(
                  labelText: 'Temporary password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    tooltip: _pwObscured ? 'Show' : 'Hide',
                    icon: Icon(
                      _pwObscured ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _pwObscured = !_pwObscured),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 16),

              // Submit
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _submit,
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.person_add),
                  label: Text(_busy ? 'Creating...' : 'Create staff user'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
