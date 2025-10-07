import '../models/package.dart';

List<String> addedServicesComparedTo(Package current, Package baseline) {
  final base = baseline.services.map((e) => e.toLowerCase()).toSet();
  return current.services
      .where((s) => !base.contains(s.toLowerCase()))
      .toList();
}
