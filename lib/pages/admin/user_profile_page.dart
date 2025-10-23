import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/admin/staff_toggle.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({
    super.key,
    required this.docId,
    this.collection = 'users',
  });

  final String docId;
  final String collection;

  @override
  Widget build(BuildContext context) {
    final docRef = FirebaseFirestore.instance.collection(collection).doc(docId);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: docRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: const Text('User')),
            body: const Center(child: Text('User not found')),
          );
        }

        final data = snapshot.data!.data()!;
        final name = (data['name'] as String?)?.trim() ?? '—';
        final email = (data['email'] as String?)?.trim() ?? '—';
        final phone = (data['phone'] as String?)?.trim() ?? '—';
        final address = (data['address'] as String?)?.trim() ?? '—';
        final photoUrl = (data['photoUrl'] as String?) ?? '';
        final authUid = (data['uid'] as String?) ?? docId; // fallback to docId
        final updatedAt = data['updatedAt'];

        return Scaffold(
          appBar: AppBar(title: Text(name.isNotEmpty ? name : 'User')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundImage: photoUrl.isNotEmpty
                          ? NetworkImage(photoUrl)
                          : null,
                      child: photoUrl.isEmpty
                          ? Text(
                              _initials(name),
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(color: Colors.white),
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Info(
                icon: Icons.badge_outlined,
                label: 'Auth UID',
                value: authUid,
              ),
              _Info(icon: Icons.perm_identity, label: 'Doc ID', value: docId),
              _Info(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: phone,
                copyable: true,
              ),
              _Info(
                icon: Icons.home_outlined,
                label: 'Address',
                value: address,
              ),
              _Info(
                icon: Icons.event_outlined,
                label: 'Updated',
                value: _fmt(updatedAt),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: StaffToggle(docId: docId, collection: collection),
                ),
              ),
              const SizedBox(height: 16),

              _PasswordResetCard(profileEmail: email == '—' ? '' : email),
            ],
          ),
        );
      },
    );
  }

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    return (parts.first[0] + (parts.length > 1 ? parts[1][0] : ''))
        .toUpperCase();
  }

  static String _fmt(dynamic ts) {
    if (ts is! Timestamp) return '—';
    final dt = ts.toDate();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }
}

class _Info extends StatelessWidget {
  const _Info({
    required this.icon,
    required this.label,
    required this.value,
    this.copyable = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label, style: Theme.of(context).textTheme.labelMedium),
      subtitle: Text(value.isEmpty ? '—' : value),
      trailing: copyable
          ? IconButton(
              tooltip: 'Copy',
              icon: const Icon(Icons.copy),
              onPressed: value.isEmpty
                  ? null
                  : () async {
                      await Clipboard.setData(ClipboardData(text: value));
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(const SnackBar(content: Text('Copied')));
                      }
                    },
            )
          : null,
    );
  }
}

class _PasswordResetCard extends StatefulWidget {
  const _PasswordResetCard({required this.profileEmail});

  final String profileEmail;

  @override
  State<_PasswordResetCard> createState() => _PasswordResetCardState();
}

class _PasswordResetCardState extends State<_PasswordResetCard> {
  bool _busy = false;

  String get _emailToShow {
    final me = FirebaseAuth.instance.currentUser;
    return (widget.profileEmail.isNotEmpty
            ? widget.profileEmail
            : (me?.email ?? ''))
        .trim();
  }

  Future<void> _sendResetEmail() async {
    final email = _emailToShow;
    if (email.isEmpty) {
      _snack('No email on file for this user.', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _snack('Reset email sent to $email');
    } on FirebaseAuthException catch (e) {
      _snack('Failed to send reset email: ${e.message ?? e.code}', error: true);
    } catch (e) {
      _snack('Failed to send reset email: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: error ? Colors.red : null),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canEmail = _emailToShow.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Password', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),

            TextFormField(
              readOnly: true,
              initialValue: canEmail ? _emailToShow : '—',
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                helperText: canEmail ? null : 'No email on file for this user',
                suffixIcon: IconButton(
                  tooltip: 'Copy email',
                  icon: const Icon(Icons.copy),
                  onPressed: canEmail
                      ? () async {
                          await Clipboard.setData(
                            ClipboardData(text: _emailToShow),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Email copied')),
                            );
                          }
                        }
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: Text(
                    canEmail
                        ? 'Send a password reset link to $_emailToShow'
                        : 'No email on file for this user',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _busy || !canEmail ? null : _sendResetEmail,
                  icon: const Icon(Icons.mail_outlined),
                  label: const Text('Send reset email'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
