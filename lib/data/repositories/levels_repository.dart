import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/level_model.dart';

class LevelsRepository {
  const LevelsRepository({AssetBundle? assetBundle})
    : _assetBundle = assetBundle;

  final AssetBundle? _assetBundle;

  AssetBundle get _bundle => _assetBundle ?? rootBundle;

  Future<List<LevelModel>> loadLevels() async {
    final manifest = await AssetManifest.loadFromAssetBundle(_bundle);

    final worldFilePattern = RegExp(r'^assets/data/levels/world_\d{2}\.json$');

    final levelFiles =
        manifest.listAssets().where(worldFilePattern.hasMatch).toList()..sort();

    if (levelFiles.isEmpty) {
      throw const FormatException(
        'assets/data/levels folder-এ কোনো world JSON পাওয়া যায়নি।',
      );
    }

    final levels = <LevelModel>[];

    for (final filePath in levelFiles) {
      final jsonText = await _bundle.loadString(filePath);

      final decodedData = jsonDecode(jsonText);

      if (decodedData is! List) {
        throw FormatException('$filePath অবশ্যই JSON array হতে হবে।');
      }

      for (var index = 0; index < decodedData.length; index++) {
        final rawLevel = decodedData[index];

        if (rawLevel is! Map) {
          throw FormatException(
            '$filePath-এর item ${index + 1} valid object নয়।',
          );
        }

        levels.add(LevelModel.fromJson(Map<String, dynamic>.from(rawLevel)));
      }
    }

    if (levels.isEmpty) {
      throw const FormatException('কোনো valid level পাওয়া যায়নি।');
    }

    _validateLevels(levels);

    levels.sort((first, second) {
      return first.order.compareTo(second.order);
    });

    return List<LevelModel>.unmodifiable(levels);
  }

  void _validateLevels(List<LevelModel> levels) {
    final usedIds = <int>{};
    final usedOrders = <int>{};

    for (final level in levels) {
      if (level.id <= 0) {
        throw const FormatException('Level id অবশ্যই 0-এর বেশি হতে হবে।');
      }

      if (level.order <= 0) {
        throw FormatException('Level ${level.id}-এর order সঠিক নয়।');
      }

      if (level.worldId <= 0) {
        throw FormatException('Level ${level.id}-এর worldId সঠিক নয়।');
      }

      if (level.title.trim().isEmpty) {
        throw FormatException('Level ${level.id}-এর title খালি।');
      }

      if (!usedIds.add(level.id)) {
        throw FormatException('Duplicate level id: ${level.id}');
      }

      if (!usedOrders.add(level.order)) {
        throw FormatException('Duplicate level order: ${level.order}');
      }
    }
  }
}
