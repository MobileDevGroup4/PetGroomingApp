import 'package:flutter/material.dart';

class Appointments extends StatelessWidget {
  const Appointments({super.key, required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      shadowColor: Colors.transparent,
      margin: const EdgeInsets.all(8.0),
      child: SizedBox.expand(
        child: Center(
          child: Text('Appointments', style: theme.textTheme.titleLarge),
        ),
      ),
    );
  }
}
