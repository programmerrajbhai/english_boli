import 'package:flutter/foundation.dart';

import '../../../data/models/practice_item_model.dart';
import '../../../data/models/practice_model.dart';

class PracticeController extends ChangeNotifier {
  PracticeController({
    required this.practice,
    int initialIndex = 0,
  }) : _index = initialIndex
      .clamp(
    0,
    practice.items.length - 1,
  )
      .toInt();

  final PracticeModel practice;

  int _index;
  int _correctCount = 0;

  bool _checked = false;
  bool? _isCorrect;

  String? _selectedOption;
  String _textAnswer = '';

  final List<int> _arrangedIndexes = <int>[];
  final Map<String, String> _matches = <String, String>{};

  String? _selectedLeft;

  int get index => _index;

  int get correctCount => _correctCount;

  bool get checked => _checked;

  bool? get isCorrect => _isCorrect;

  String? get selectedOption => _selectedOption;

  String get textAnswer => _textAnswer;

  String? get selectedLeft => _selectedLeft;

  PracticeItemModel get item {
    return practice.items[_index];
  }

  int get total {
    return practice.items.length;
  }

  bool get isLast {
    return _index == total - 1;
  }

  double get progress {
    if (total <= 0) return 0;

    return (_index + 1) / total;
  }

  List<int> get arrangedIndexes {
    return List<int>.unmodifiable(
      _arrangedIndexes,
    );
  }

  Map<String, String> get matches {
    return Map<String, String>.unmodifiable(
      _matches,
    );
  }

  String get arrangedAnswer {
    return _arrangedIndexes
        .map(
          (wordIndex) => item.words[wordIndex],
    )
        .join(' ');
  }

  String get correctAnswerText {
    if (item.type == PracticeType.matching) {
      return item.pairs
          .map(
            (pair) => '${pair.left} = ${pair.right}',
      )
          .join('  •  ');
    }

    return item.correctAnswer;
  }

  bool get canCheck {
    return switch (item.type) {
      PracticeType.mcq => _selectedOption != null,
      PracticeType.banglaToEnglish ||
      PracticeType.englishToBangla ||
      PracticeType.fillBlank ||
      PracticeType.questionAnswer =>
      _textAnswer.trim().isNotEmpty,
      PracticeType.wordArrange => _arrangedIndexes.isNotEmpty,
      PracticeType.matching => _matches.length == item.pairs.length,
    };
  }

  void selectOption(String option) {
    if (_checked) return;

    _selectedOption = option;
    notifyListeners();
  }

  void setTextAnswer(String value) {
    if (_checked) return;

    _textAnswer = value;
    notifyListeners();
  }

  void toggleWord(int wordIndex) {
    if (_checked) return;

    if (wordIndex < 0 || wordIndex >= item.words.length) {
      return;
    }

    if (_arrangedIndexes.contains(wordIndex)) {
      _arrangedIndexes.remove(wordIndex);
    } else {
      _arrangedIndexes.add(wordIndex);
    }

    notifyListeners();
  }

  void clearArrangedWords() {
    if (_checked) return;

    _arrangedIndexes.clear();
    notifyListeners();
  }

  void selectLeft(String left) {
    if (_checked) return;

    _selectedLeft = left;
    notifyListeners();
  }

  void selectRight(String right) {
    if (_checked || _selectedLeft == null) {
      return;
    }

    /*
     * একই right answer একাধিক subject-এর জন্য ব্যবহার করা যাবে।
     *
     * Example:
     * He  = is
     * She = is
     *
     * আগে একই "is" দ্বিতীয়বার select করলে প্রথম match remove হয়ে যেত।
     */
    _matches[_selectedLeft!] = right;
    _selectedLeft = null;

    notifyListeners();
  }

  void removeMatch(String left) {
    if (_checked) return;

    _matches.remove(left);

    if (_selectedLeft == left) {
      _selectedLeft = null;
    }

    notifyListeners();
  }

  void checkAnswer() {
    if (_checked || !canCheck) {
      return;
    }

    _checked = true;
    _isCorrect = _evaluateAnswer();

    if (_isCorrect == true) {
      _correctCount++;
    }

    notifyListeners();
  }

  bool moveToNext() {
    if (!_checked || isLast) {
      return false;
    }

    _index++;
    _resetCurrentAnswer();
    notifyListeners();

    return true;
  }

  bool _evaluateAnswer() {
    return switch (item.type) {
      PracticeType.mcq =>
      _normalize(_selectedOption ?? '') ==
          _normalize(item.correctAnswer),
      PracticeType.banglaToEnglish ||
      PracticeType.englishToBangla ||
      PracticeType.fillBlank ||
      PracticeType.questionAnswer =>
          item.allCorrectAnswers.any(
                (answer) {
              return _normalize(_textAnswer) ==
                  _normalize(answer);
            },
          ),
      PracticeType.wordArrange =>
      _normalize(arrangedAnswer) ==
          _normalize(item.correctAnswer),
      PracticeType.matching => item.pairs.every(
            (pair) {
          return _normalize(
            _matches[pair.left] ?? '',
          ) ==
              _normalize(pair.right);
        },
      ),
    };
  }

  void _resetCurrentAnswer() {
    _checked = false;
    _isCorrect = null;
    _selectedOption = null;
    _textAnswer = '';
    _arrangedIndexes.clear();
    _matches.clear();
    _selectedLeft = null;
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(
      RegExp(
        '[^a-z0-9\\u0980-\\u09ff\\s]',
      ),
      '',
    )
        .replaceAll(
      RegExp(r'\s+'),
      ' ',
    )
        .trim();
  }
}