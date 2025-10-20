import 'package:flutter/material.dart';
import '../../repositories/profiles_repository.dart';

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
  final _repo = const ProfilesRepository();
  late bool _value = widget.initialValue;
  bool _saving = false;

  Future<void> _update(bool v) async {
    setState(() {
      _value = v;
      _saving = true;
    });
    try {
      await _repo.updateIsStaff(docId: widget.docId, isStaff: v);
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
