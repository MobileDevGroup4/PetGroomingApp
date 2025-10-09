import '../models/package.dart';


List<String> addedServicesForTier(
  Package current,
  List<Package> all, {
  List<String> tierOrder = const ['silver', 'gold', 'platinium'],
}) {

  final idx = tierOrder.indexOf(current.id.toLowerCase().trim());
  if (idx <= 0) return const []; 

  final baselineId = tierOrder[idx - 1];
  final baseline = all.firstWhere(
    (p) => p.id.toLowerCase().trim() == baselineId,
    orElse: () => current, 
  );
  if (identical(baseline, current)) return const [];

  
  final baseSet = baseline.services
      .map((s) => s.toLowerCase().trim())
      .toSet();

  final added = current.services
      .where((s) => !baseSet.contains(s.toLowerCase().trim()))
      .toList();

  return added;
}


String highlightsLabel(Package current, List<Package> all, {int previewCount = 2}) {
  final added = addedServicesForTier(current, all);
  if (added.isEmpty) return '';
  return added.length > previewCount
      ? 'Adds: ${added.take(previewCount).join(', ')}…'
      : 'Adds: ${added.join(', ')}';
}
