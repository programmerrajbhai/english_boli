enum PracticeType {
  mcq,
  banglaToEnglish,
  englishToBangla,
  fillBlank,
  wordArrange,
  matching,
  questionAnswer,
}

class MatchingPairModel {
  const MatchingPairModel({
    required this.left,
    required this.right,
  });

  final String left;
  final String right;

  factory MatchingPairModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return MatchingPairModel(
      left: PracticeItemModel.readRequired(
        json,
        'left',
      ),
      right: PracticeItemModel.readRequired(
        json,
        'right',
      ),
    );
  }
}

class PracticeItemModel {
  const PracticeItemModel({
    required this.id,
    required this.type,
    required this.question,
    required this.questionBn,
    required this.correctAnswer,
    required this.explanation,
    this.options = const <String>[],
    this.acceptedAnswers = const <String>[],
    this.words = const <String>[],
    this.pairs = const <MatchingPairModel>[],
  });

  final String id;
  final PracticeType type;
  final String question;
  final String questionBn;
  final String correctAnswer;
  final String explanation;

  final List<String> options;
  final List<String> acceptedAnswers;
  final List<String> words;
  final List<MatchingPairModel> pairs;

  factory PracticeItemModel.fromJson(
      Map<String, dynamic> json,
      ) {
    final type = _parseType(
      readRequired(json, 'type'),
    );

    final options = _readStringList(
      json['options'],
    );

    final acceptedAnswers = _readStringList(
      json['acceptedAnswers'],
    );

    final words = _readStringList(
      json['words'],
    );

    final rawPairs = json['pairs'];

    final pairs = rawPairs is List
        ? rawPairs
        .whereType<Map>()
        .map(
          (pair) =>
          MatchingPairModel.fromJson(
            Map<String, dynamic>.from(
              pair,
            ),
          ),
    )
        .toList(growable: false)
        : const <MatchingPairModel>[];

    final item = PracticeItemModel(
      id: readRequired(json, 'id'),
      type: type,
      question: readRequired(
        json,
        'question',
      ),
      questionBn:
      json['questionBn']
          ?.toString()
          .trim() ??
          '',
      correctAnswer:
      type == PracticeType.matching
          ? json['correctAnswer']
          ?.toString()
          .trim() ??
          ''
          : readRequired(
        json,
        'correctAnswer',
      ),
      explanation: readRequired(
        json,
        'explanation',
      ),
      options: List<String>.unmodifiable(
        options,
      ),
      acceptedAnswers:
      List<String>.unmodifiable(
        acceptedAnswers,
      ),
      words: List<String>.unmodifiable(
        words,
      ),
      pairs:
      List<MatchingPairModel>.unmodifiable(
        pairs,
      ),
    );

    item._validate();

    return item;
  }

  String get typeLabel {
    return switch (type) {
      PracticeType.mcq =>
      'MULTIPLE CHOICE',
      PracticeType.banglaToEnglish =>
      'BANGLA → ENGLISH',
      PracticeType.englishToBangla =>
      'ENGLISH → BANGLA',
      PracticeType.fillBlank =>
      'FILL IN THE BLANK',
      PracticeType.wordArrange =>
      'WORD ARRANGE',
      PracticeType.matching =>
      'MATCHING',
      PracticeType.questionAnswer =>
      'QUESTION & ANSWER',
    };
  }

  List<String> get allCorrectAnswers {
    return List<String>.unmodifiable(
      <String>{
        correctAnswer,
        ...acceptedAnswers,
      }.where(
            (answer) => answer.trim().isNotEmpty,
      ),
    );
  }

  void _validate() {
    if (type == PracticeType.mcq) {
      if (options.length < 2) {
        throw FormatException(
          '$id: MCQ-তে কমপক্ষে ২টি option লাগবে।',
        );
      }

      if (!options.contains(correctAnswer)) {
        throw FormatException(
          '$id: MCQ correctAnswer options-এর মধ্যে নেই।',
        );
      }
    }

    if (type == PracticeType.wordArrange &&
        words.length < 2) {
      throw FormatException(
        '$id: Word Arrange-এর words পাওয়া যায়নি।',
      );
    }

    if (type == PracticeType.matching &&
        pairs.length < 2) {
      throw FormatException(
        '$id: Matching-এ কমপক্ষে ২টি pair লাগবে।',
      );
    }
  }

  static PracticeType _parseType(
      String value,
      ) {
    return switch (
    value.trim().toLowerCase()) {
      'mcq' => PracticeType.mcq,
      'bangla_to_english' =>
      PracticeType.banglaToEnglish,
      'english_to_bangla' =>
      PracticeType.englishToBangla,
      'fill_blank' =>
      PracticeType.fillBlank,
      'word_arrange' =>
      PracticeType.wordArrange,
      'matching' =>
      PracticeType.matching,
      'question_answer' =>
      PracticeType.questionAnswer,
      _ => throw FormatException(
        'Unknown practice type: $value',
      ),
    };
  }

  static List<String> _readStringList(
      Object? value,
      ) {
    if (value is! List) {
      return const <String>[];
    }

    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static String readRequired(
      Map<String, dynamic> json,
      String key,
      ) {
    final value = json[key];

    if (value is! String ||
        value.trim().isEmpty) {
      throw FormatException(
        'Practice item-এর $key খালি অথবা invalid।',
      );
    }

    return value.trim();
  }
}
