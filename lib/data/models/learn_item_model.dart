import 'level_model.dart';

enum LearnItemType { word, sentence }

class LearnItemModel {
  const LearnItemModel({
    required this.id,
    required this.type,
    required this.english,
    required this.bangla,
    required this.exampleEnglish,
    required this.exampleBangla,
    required this.illustrationKey,
  });

  final String id;
  final LearnItemType type;
  final String english;
  final String bangla;
  final String exampleEnglish;
  final String exampleBangla;
  final String illustrationKey;

  factory LearnItemModel.fromJson(Map<String, dynamic> json) {
    final id = _readRequiredString(json, 'id');

    final english = _readRequiredString(json, 'english');

    final bangla = _readRequiredString(json, 'bangla');

    final exampleEnglish = _readRequiredString(json, 'exampleEnglish');

    final exampleBangla = _readRequiredString(json, 'exampleBangla');

    final typeText = json['type']?.toString().trim().toLowerCase() ?? 'word';

    return LearnItemModel(
      id: id,
      type: typeText == 'sentence'
          ? LearnItemType.sentence
          : LearnItemType.word,
      english: english,
      bangla: bangla,
      exampleEnglish: exampleEnglish,
      exampleBangla: exampleBangla,
      illustrationKey:
          json['illustrationKey']?.toString().trim().toLowerCase() ??
          'speaking',
    );
  }

  static List<LearnItemModel> fromLevel(LevelModel level) {
    Map<String, dynamic>? learnSection;

    for (final section in level.sections) {
      final sectionType = section['type']?.toString().trim().toLowerCase();

      if (sectionType == 'learn') {
        learnSection = section;
        break;
      }
    }

    if (learnSection == null) {
      throw FormatException('Level ${level.id}-এ learn section পাওয়া যায়নি।');
    }

    final rawItems = learnSection['items'];

    if (rawItems is! List || rawItems.isEmpty) {
      throw FormatException('Level ${level.id}-এর learn items খালি।');
    }

    final items = <LearnItemModel>[];
    final usedIds = <String>{};

    for (var index = 0; index < rawItems.length; index++) {
      final rawItem = rawItems[index];

      if (rawItem is! Map) {
        throw FormatException('Learn item ${index + 1} valid object নয়।');
      }

      final item = LearnItemModel.fromJson(Map<String, dynamic>.from(rawItem));

      if (!usedIds.add(item.id)) {
        throw FormatException('Duplicate learn item id: ${item.id}');
      }

      items.add(item);
    }

    return List<LearnItemModel>.unmodifiable(items);
  }

  static String _readRequiredString(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Learn item-এর $key খালি অথবা invalid।');
    }

    return value.trim();
  }
}
