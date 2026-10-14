import 'activities.dart';
import 'learning.dart';

/// Builds the green tip on the Grown-ups page from how much of each world
/// has been explored (activities with at least one star / all activities).
String parentTipFor(
  Map<String, int> activityStars, {
  Map<String, WorldCatalog> catalogs = worldCatalogs,
  List<LearningModule> modules = learningModules,
}) {
  LearningModule? lowest;
  var lowestRatio = 2.0;
  var anyProgress = false;
  for (final module in modules) {
    final activities = catalogs[module.id]?.activities ?? const [];
    if (activities.isEmpty) continue;
    final done =
        activities.where((a) => (activityStars[a.id] ?? 0) > 0).length;
    if (done > 0) anyProgress = true;
    final ratio = done / activities.length;
    if (ratio < 1 && ratio < lowestRatio) {
      lowestRatio = ratio;
      lowest = module;
    }
  }
  if (lowest == null) {
    return 'Tip: every activity is done! Replay your favourites to earn more stars.';
  }
  if (!anyProgress) {
    return 'Tip: start with any world. Letters is a good first one.';
  }
  return 'Tip: try ${lowest.title} next. It has the most left to explore.';
}
