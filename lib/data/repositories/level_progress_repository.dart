import 'package:shared_preferences/shared_preferences.dart';

class LevelProgress {
  const LevelProgress({
    required this.hasStarted,
    required this.completedPractices,
    required this.currentStage,
    required this.isCompleted,
  });

  const LevelProgress.empty()
    : hasStarted = false,
      completedPractices = 0,
      currentStage = 0,
      isCompleted = false;

  final bool hasStarted;
  final int completedPractices;
  final int currentStage;
  final bool isCompleted;

  double fractionOf(int totalPractices) {
    if (totalPractices <= 0) {
      return 0;
    }

    return (completedPractices / totalPractices).clamp(0.0, 1.0).toDouble();
  }
}

class LevelProgressRepository {
  LevelProgressRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  Future<LevelProgress> loadLevel(int levelId) async {
    if (levelId <= 0) {
      return const LevelProgress.empty();
    }

    return LevelProgress(
      hasStarted: await _preferences.getBool(_startedKey(levelId)) ?? false,
      completedPractices: await _preferences.getInt(_practiceKey(levelId)) ?? 0,
      currentStage: await _preferences.getInt(_stageKey(levelId)) ?? 0,
      isCompleted: await _preferences.getBool(_completedKey(levelId)) ?? false,
    );
  }

  Future<Set<int>> loadCompletedLevelIds(Iterable<int> levelIds) async {
    final completedIds = <int>{};

    for (final levelId in levelIds) {
      final progress = await loadLevel(levelId);

      if (progress.isCompleted) {
        completedIds.add(levelId);
      }
    }

    return completedIds;
  }

  Future<void> markLevelStarted(int levelId) {
    return _preferences.setBool(_startedKey(levelId), true);
  }

  Future<int> loadSectionPosition({
    required int levelId,
    required String sectionId,
  }) async {
    return await _preferences.getInt(_sectionPositionKey(levelId, sectionId)) ??
        0;
  }

  Future<void> saveSectionPosition({
    required int levelId,
    required String sectionId,
    required int itemIndex,
  }) {
    return _preferences.setInt(
      _sectionPositionKey(levelId, sectionId),
      itemIndex < 0 ? 0 : itemIndex,
    );
  }

  Future<void> clearSectionPosition({
    required int levelId,
    required String sectionId,
  }) {
    return _preferences.remove(_sectionPositionKey(levelId, sectionId));
  }

  Future<void> completeStage({
    required int levelId,
    required int totalPractices,
    required int minimumCompletedPractices,
    required int nextStage,
  }) async {
    final oldProgress = await loadLevel(levelId);

    final completedPractices =
        oldProgress.completedPractices > minimumCompletedPractices
        ? oldProgress.completedPractices
        : minimumCompletedPractices;

    await saveLevelProgress(
      levelId: levelId,
      completedPractices: completedPractices,
      totalPractices: totalPractices,
      currentStage: nextStage,
    );
  }

  Future<void> saveLevelProgress({
    required int levelId,
    required int completedPractices,
    required int totalPractices,
    required int currentStage,
  }) async {
    final safeTotal = totalPractices <= 0 ? 1 : totalPractices;

    final safeCompleted = completedPractices.clamp(0, safeTotal).toInt();

    final safeStage = currentStage.clamp(0, 5).toInt();

    await Future.wait(<Future<void>>[
      _preferences.setBool(_startedKey(levelId), true),
      _preferences.setInt(_practiceKey(levelId), safeCompleted),
      _preferences.setInt(_stageKey(levelId), safeStage),
      _preferences.setBool(_completedKey(levelId), safeCompleted >= safeTotal),
    ]);
  }

  Future<void> markLevelCompleted({
    required int levelId,
    required int totalPractices,
  }) {
    return saveLevelProgress(
      levelId: levelId,
      completedPractices: totalPractices,
      totalPractices: totalPractices,
      currentStage: 5,
    );
  }

  Future<void> resetLevel(int levelId) async {
    await Future.wait(<Future<void>>[
      _preferences.remove(_startedKey(levelId)),
      _preferences.remove(_practiceKey(levelId)),
      _preferences.remove(_stageKey(levelId)),
      _preferences.remove(_completedKey(levelId)),
      _preferences.remove(_sectionPositionKey(levelId, 'learn')),
    ]);
  }

  String _startedKey(int levelId) {
    return 'level_${levelId}_started';
  }

  String _practiceKey(int levelId) {
    return 'level_${levelId}_practice_done';
  }

  String _stageKey(int levelId) {
    return 'level_${levelId}_current_stage';
  }

  String _completedKey(int levelId) {
    return 'level_${levelId}_completed';
  }

  String _sectionPositionKey(int levelId, String sectionId) {
    return 'level_${levelId}_${sectionId}_position';
  }
}
