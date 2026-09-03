import 'package:flutter/foundation.dart';

@immutable
class LevelModel {
  const LevelModel({
    this.schemaVersion = 1,
    required this.id,
    required this.order,
    required this.worldId,
    required this.title,
    required this.subtitleBn,
    required this.difficulty,
    required this.estimatedMinutes,
    this.passPercentage = 80,
    this.totalPractices = 80,
    this.rewardXp = 100,
    this.rewardStars = 3,
    this.learningGoals = const <String>[],
    this.sections = const <Map<String, dynamic>>[],
  });

  final int schemaVersion;
  final int id;
  final int order;
  final int worldId;

  final String title;
  final String subtitleBn;
  final String difficulty;

  final int estimatedMinutes;
  final int passPercentage;
  final int totalPractices;
  final int rewardXp;
  final int rewardStars;

  final List<String> learningGoals;
  final List<Map<String, dynamic>> sections;

  factory LevelModel.fromJson(Map<String, dynamic> json) {
    final title = _readString(json['title'], 'Untitled Level');

    final rawGoals = json['learningGoals'];
    final rawSections = json['sections'];

    return LevelModel(
      schemaVersion: _readInt(json['schemaVersion'], 1),
      id: _readInt(json['id'], 0),
      order: _readInt(json['order'], 0),
      worldId: _readInt(json['worldId'], 1),
      title: title,
      subtitleBn: _readString(
        json['subtitleBn'],
        'এই level-এ নতুন English শিখুন',
      ),
      difficulty: _readString(json['difficulty'], 'beginner'),
      estimatedMinutes: _readInt(json['estimatedMinutes'], 20),
      passPercentage: _readInt(
        json['passPercentage'],
        80,
      ).clamp(1, 100).toInt(),
      totalPractices: _readInt(
        json['totalPractices'],
        80,
      ).clamp(1, 500).toInt(),
      rewardXp: _readInt(json['rewardXp'], 100).clamp(0, 100000).toInt(),
      rewardStars: _readInt(json['rewardStars'], 3).clamp(0, 5).toInt(),
      learningGoals: rawGoals is List
          ? List<String>.unmodifiable(
              rawGoals
                  .whereType<String>()
                  .map((goal) => goal.trim())
                  .where((goal) => goal.isNotEmpty),
            )
          : const <String>[],
      sections: rawSections is List
          ? List<Map<String, dynamic>>.unmodifiable(
              rawSections.whereType<Map>().map(
                (item) => Map<String, dynamic>.from(item),
              ),
            )
          : const <Map<String, dynamic>>[],
    );
  }

  List<String> get resolvedLearningGoals {
    if (learningGoals.isNotEmpty) {
      return learningGoals;
    }

    return <String>[
      '“$title” চিনতে ও বুঝতে পারবেন',
      'সঠিক বাক্যে ব্যবহার করতে পারবেন',
      'শুনে বুঝে নিজে বলে practice করতে পারবেন',
    ];
  }

  String get difficultyBn {
    return switch (difficulty.toLowerCase()) {
      'beginner' => 'সহজ',
      'elementary' => 'প্রাথমিক',
      'intermediate' => 'মধ্যম',
      'advanced' => 'কঠিন',
      _ => difficulty,
    };
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      'id': id,
      'order': order,
      'worldId': worldId,
      'title': title,
      'subtitleBn': subtitleBn,
      'difficulty': difficulty,
      'estimatedMinutes': estimatedMinutes,
      'passPercentage': passPercentage,
      'totalPractices': totalPractices,
      'rewardXp': rewardXp,
      'rewardStars': rewardStars,
      'learningGoals': learningGoals,
      'sections': sections,
    };
  }

  static int _readInt(Object? value, int fallback) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }

    return fallback;
  }

  static String _readString(Object? value, String fallback) {
    if (value is! String || value.trim().isEmpty) {
      return fallback;
    }

    return value.trim();
  }
}
