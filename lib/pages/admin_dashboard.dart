import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const String userProfilesCollection = 'profiles';

Query<Map<String, dynamic>> _baseQuery({required bool onlyStaff}) {
  final col = FirebaseFirestore.instance.collection(userProfilesCollection);
  if (onlyStaff) {
    return col.where('isStaff', isEqualTo: true).limit(200);
  }
  return col.orderBy('updatedAt', descending: true).limit(200);
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _search = '';
  bool _onlyStaff = false;

  @override
  Widget build(BuildContext context) {
    final query = _baseQuery(onlyStaff: _onlyStaff);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin • User Profiles'),
        actions: [
          Row(
            children: [
              const Text('Only staff'),
              Switch(
                value: _onlyStaff,
                onChanged: (v) => setState(() => _onlyStaff = v),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search by name or email (client-side)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search name or email…',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v.trim()),
            ),
          ),
          Expanded(
            child: ProfilesList(query: query, search: _search),
          ),
        ],
      ),
    );
  }
}

class ProfilesList extends StatelessWidget {
  final Query<Map<String, dynamic>> query;
  final String search;
  const ProfilesList({super.key, required this.query, required this.search});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return const Center(child: Text('Failed to load profiles'));
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var docs = snap.data?.docs ?? const [];
        if (search.isNotEmpty) {
          final q = search.toLowerCase();
          docs = docs.where((d) {
            final m = d.data();
            final name = (m['name'] as String?)?.toLowerCase() ?? '';
            final email = (m['email'] as String?)?.toLowerCase() ?? '';
            return name.contains(q) || email.contains(q);
          }).toList();
        }

        if (docs.isEmpty) return const Center(child: Text('No profiles found'));
        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) => ProfileTile(doc: docs[i]),
        );
      },
    );
  }
}

class ProfileTile extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  const ProfileTile({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    final d = doc.data();
    final name = (d['name'] as String?)?.trim();
    final email = (d['email'] as String?)?.trim();
    final uid = (d['uid'] as String?) ?? '—';
    final isStaff = (d['isStaff'] as bool?) ?? false;

    return ListTile(
      visualDensity: VisualDensity.compact,
      title: Text(
        name?.isNotEmpty == true
            ? name!
            : (email?.isNotEmpty == true ? email! : 'Unnamed user'),
      ),
      subtitle: Text(
        [if (email != null && email.isNotEmpty) email, 'UID: $uid'].join('\n'),
      ),
      trailing: StaffToggle(docId: doc.id, initialValue: isStaff),
    );
  }
}

class StaffToggle extends StatefulWidget {
  final String docId;
  final bool initialValue;
  const StaffToggle({
    super.key,
    required this.docId,
    required this.initialValue,
  });

  @override
  State<StaffToggle> createState() => _StaffToggleState();
}

class _StaffToggleState extends State<StaffToggle> {
  late bool _value = widget.initialValue;
  bool _saving = false;

  Future<void> _update(bool v) async {
    setState(() {
      _value = v;
      _saving = true;
    });
    try {
      await FirebaseFirestore.instance
          .collection(userProfilesCollection)
          .doc(widget.docId)
          .update({'isStaff': v, 'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      setState(() => _value = !v);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update role: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: _saving,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _value ? 'Staff' : 'Customer',
            overflow: TextOverflow.fade,
            softWrap: false,
          ),
          const SizedBox(width: 6),
          Switch(value: _value, onChanged: _update),
          if (_saving) const SizedBox(width: 6),
          if (_saving)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}
