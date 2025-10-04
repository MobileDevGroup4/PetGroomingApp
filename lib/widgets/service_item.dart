import 'package:flutter/material.dart';

class ServiceItem extends StatelessWidget {
  final String text;
  const ServiceItem(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.check_circle_outline),
      title: Text(text),
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
