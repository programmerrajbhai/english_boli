
import 'level_model.dart';
import 'practice_item_model.dart';

class PracticeModel {
  const PracticeModel({
    required this.id,
    required this.title,
    required this.progressAfterCompletion,
    required this.items,
  });

  final String id;
  final String title;
  final int progressAfterCompletion;
  final List<PracticeItemModel> items;

  factory PracticeModel.fromLevel(
      LevelModel level,
      ) {
    Map<String, dynamic>? practiceSection;

    for (final section in level.sections) {
      final sectionType = section['type']
          ?.toString()
          .trim()
          .toLowerCase();

      if (sectionType == 'practice') {
        practiceSection = section;
        break;
      }
    }

    if (practiceSection == null) {
      throw FormatException(
        'Level ${level.id}-এ practice section পাওয়া যায়নি।',
      );
    }

    final rawItems =
    practiceSection['items'];

    if (rawItems is! List ||
        rawItems.isEmpty) {
      throw FormatException(
        'Level ${level.id}-এর practice items খালি।',
      );
    }

    final items = <PracticeItemModel>[];
    final usedIds = <String>{};

    for (var index = 0;
    index < rawItems.length;
    index++) {
      final rawItem = rawItems[index];

      if (rawItem is! Map) {
        throw FormatException(
          'Practice item ${index + 1} valid object নয়।',
        );
      }

      final item =
      PracticeItemModel.fromJson(
        Map<String, dynamic>.from(
          rawItem,
        ),
      );

      if (!usedIds.add(item.id)) {
        throw FormatException(
          'Duplicate practice item id: ${item.id}',
        );
      }

      items.add(item);
    }

    final rawProgress =
    practiceSection[
    'progressAfterCompletion'];

    final parsedProgress =
    rawProgress is num
        ? rawProgress.toInt()
        : int.tryParse(
      rawProgress?.toString() ??
          '',
    ) ??
        items.length;

    final rawTitle =
    practiceSection['title'];

    final title =
    rawTitle is String &&
        rawTitle.trim().isNotEmpty
        ? rawTitle.trim()
        : 'Smart Practice';

    return PracticeModel(
      id: PracticeItemModel.readRequired(
        practiceSection,
        'id',
      ),
      title: title,
      progressAfterCompletion:
      parsedProgress
          .clamp(
        items.length,
        level.totalPractices,
      )
          .toInt(),
      items:
      List<PracticeItemModel>.unmodifiable(
        items,
      ),
    );
  }
}