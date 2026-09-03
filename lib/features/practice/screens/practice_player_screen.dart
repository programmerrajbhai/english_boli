
import 'package:flutter/material.dart';

import '../../../data/models/level_model.dart';
import '../../../data/models/practice_item_model.dart';
import '../../../data/models/practice_model.dart';
import '../../../data/repositories/level_progress_repository.dart';
import '../controllers/practice_controller.dart';

class PracticePlayerScreen
    extends StatefulWidget {
  const PracticePlayerScreen({
    super.key,
    required this.level,
    this.progressRepository,
  });

  final LevelModel level;
  final LevelProgressRepository?
  progressRepository;

  @override
  State<PracticePlayerScreen>
  createState() {
    return _PracticePlayerScreenState();
  }
}

class _PracticePlayerScreenState
    extends State<PracticePlayerScreen> {
  static const _ink = Color(0xFF08100E);
  static const _teal = Color(0xFF00BFAE);
  static const _yellow = Color(0xFFFFC928);
  static const _coral = Color(0xFFFF6B57);
  static const _green = Color(0xFF20A66A);
  static const _background =
  Color(0xFFF5F9F8);
  static const _muted =
  Color(0xFF66736F);
  static const _border =
  Color(0xFFDCE5E2);

  late final LevelProgressRepository
  _repository;

  final TextEditingController
  _textController =
  TextEditingController();

  PracticeController? _controller;

  bool _loading = true;
  bool _finishing = false;
  bool _allowPop = false;

  String? _error;

  @override
  void initState() {
    super.initState();

    _repository =
        widget.progressRepository ??
            LevelProgressRepository();

    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final practice =
      PracticeModel.fromLevel(
        widget.level,
      );

      final savedIndex =
      await _repository
          .loadSectionPosition(
        levelId: widget.level.id,
        sectionId: practice.id,
      );

      final controller =
      PracticeController(
        practice: practice,
        initialIndex: savedIndex,
      );

      controller.addListener(
        _onControllerChanged,
      );

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      debugPrint(
        'Practice load error: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error =
        'এই level-এর Practice content load করা যায়নি।';
      });
    }
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(
      _onControllerChanged,
    );

    _controller?.dispose();
    _textController.dispose();

    super.dispose();
  }

  Future<void> _continuePractice() async {
    final controller = _controller;

    if (controller == null ||
        !controller.checked ||
        _finishing) {
      return;
    }

    if (controller.isLast) {
      await _finishPractice();
      return;
    }

    controller.moveToNext();
    _textController.clear();

    await _repository.saveSectionPosition(
      levelId: widget.level.id,
      sectionId:
      controller.practice.id,
      itemIndex: controller.index,
    );
  }

  Future<void> _finishPractice() async {
    final controller = _controller;

    if (controller == null ||
        _finishing) {
      return;
    }

    setState(() {
      _finishing = true;
    });

    try {
      await _repository.completeStage(
        levelId: widget.level.id,
        totalPractices:
        widget.level.totalPractices,
        minimumCompletedPractices:
        controller.practice
            .progressAfterCompletion,
        nextStage: 2,
      );

      await _repository
          .clearSectionPosition(
        levelId: widget.level.id,
        sectionId:
        controller.practice.id,
      );

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            icon: const Icon(
              Icons.verified_rounded,
              color: _teal,
              size: 52,
            ),
            title: const Text(
              'Practice Complete!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight:
                FontWeight.w900,
              ),
            ),
            content: Text(
              '${controller.correctCount}/${controller.total} সঠিক উত্তর দিয়েছেন।\nপরবর্তী ধাপ Listening।',
              textAlign: TextAlign.center,
            ),
            actions: <Widget>[
              FilledButton(
                onPressed: () {
                  Navigator.of(
                    dialogContext,
                  ).pop();
                },
                child: const Text(
                  'Continue',
                ),
              ),
            ],
          );
        },
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _allowPop = true;
      });

      Navigator.of(context).pop(true);
    } catch (error) {
      debugPrint(
        'Practice completion error: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _finishing = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Progress save করা যায়নি। আবার চেষ্টা করুন।',
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmClose() async {
    final shouldClose =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Practice বন্ধ করবেন?',
            style: TextStyle(
              fontWeight:
              FontWeight.w900,
            ),
          ),
          content: const Text(
            'Completed question-এর position save থাকবে। পরে এখান থেকেই শুরু করতে পারবেন।',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text(
                'Practice চালিয়ে যান',
              ),
            ),
            FilledButton(
              style:
              FilledButton.styleFrom(
                backgroundColor: _coral,
                foregroundColor:
                Colors.white,
              ),
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: const Text(
                'বন্ধ করুন',
              ),
            ),
          ],
        );
      },
    );

    if (shouldClose != true ||
        !mounted) {
      return;
    }

    setState(() {
      _allowPop = true;
    });

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      canPop: _allowPop,
      onPopInvokedWithResult: (
          didPop,
          result,
          ) {
        if (!didPop) {
          _confirmClose();
        }
      },
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: Column(
            children: <Widget>[
              _buildHeader(),
              Expanded(
                child: _buildBody(),
              ),
              if (!_loading &&
                  _error == null)
                _buildBottomArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final controller = _controller;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        8,
        8,
        18,
        10,
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: 'Close practice',
            onPressed: _confirmClose,
            icon: const Icon(
              Icons.close_rounded,
              size: 28,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: ClipRRect(
              borderRadius:
              BorderRadius.circular(
                100,
              ),
              child:
              LinearProgressIndicator(
                value:
                controller?.progress ??
                    0,
                minHeight: 11,
                color: _teal,
                backgroundColor:
                const Color(
                  0xFFE0E8E6,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            controller == null
                ? '0/0'
                : '${controller.index + 1}/${controller.total}',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child:
        CircularProgressIndicator(
          color: _teal,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding:
          const EdgeInsets.all(24),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons
                    .error_outline_rounded,
                color: _coral,
                size: 50,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign:
                TextAlign.center,
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });

                  _initialize();
                },
                icon: const Icon(
                  Icons.refresh_rounded,
                ),
                label: const Text(
                  'আবার চেষ্টা করুন',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _controller!;
    final item = controller.item;

    return AnimatedSwitcher(
      duration:
      const Duration(milliseconds: 220),
      child: SingleChildScrollView(
        key: ValueKey<String>(item.id),
        physics:
        const BouncingScrollPhysics(),
        padding:
        const EdgeInsets.fromLTRB(
          18,
          8,
          18,
          24,
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: <Widget>[
            _buildTypeLabel(
              item.typeLabel,
            ),
            const SizedBox(height: 17),
            Text(
              item.question,
              style: const TextStyle(
                color: _ink,
                fontSize: 26,
                height: 1.25,
                fontWeight:
                FontWeight.w900,
              ),
            ),
            if (item
                .questionBn.isNotEmpty) ...<
                Widget>[
              const SizedBox(height: 8),
              Text(
                item.questionBn,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
            ],
            const SizedBox(height: 24),
            _buildAnswerArea(
              controller,
              item,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerArea(
      PracticeController controller,
      PracticeItemModel item,
      ) {
    return switch (item.type) {
      PracticeType.mcq =>
          _buildMcq(controller, item),
      PracticeType.banglaToEnglish ||
      PracticeType.englishToBangla ||
      PracticeType.fillBlank ||
      PracticeType.questionAnswer =>
          _buildTextAnswer(
            controller,
            item,
          ),
      PracticeType.wordArrange =>
          _buildWordArrange(
            controller,
            item,
          ),
      PracticeType.matching =>
          _buildMatching(
            controller,
            item,
          ),
    };
  }

  Widget _buildMcq(
      PracticeController controller,
      PracticeItemModel item,
      ) {
    return Column(
      children: <Widget>[
        for (var index = 0;
        index < item.options.length;
        index++)
          Padding(
            padding:
            const EdgeInsets.only(
              bottom: 10,
            ),
            child: InkWell(
              onTap: controller.checked
                  ? null
                  : () {
                controller
                    .selectOption(
                  item.options[
                  index],
                );
              },
              borderRadius:
              BorderRadius.circular(
                16,
              ),
              child: Container(
                width: double.infinity,
                padding:
                const EdgeInsets.all(
                  15,
                ),
                decoration: BoxDecoration(
                  color: controller
                      .selectedOption ==
                      item.options[index]
                      ? _teal.withValues(
                    alpha: 0.12,
                  )
                      : Colors.white,
                  borderRadius:
                  BorderRadius.circular(
                    16,
                  ),
                  border: Border.all(
                    color: controller
                        .selectedOption ==
                        item.options[
                        index]
                        ? _teal
                        : _border,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 30,
                      height: 30,
                      alignment:
                      Alignment.center,
                      decoration:
                      BoxDecoration(
                        color: const Color(
                          0xFFF0F4F3,
                        ),
                        borderRadius:
                        BorderRadius
                            .circular(
                          8,
                        ),
                      ),
                      child: Text(
                        '${index + 1}',
                        style:
                        const TextStyle(
                          fontWeight:
                          FontWeight
                              .w900,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Expanded(
                      child: Text(
                        item.options[
                        index],
                        style:
                        const TextStyle(
                          fontSize: 16,
                          fontWeight:
                          FontWeight
                              .w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTextAnswer(
      PracticeController controller,
      PracticeItemModel item,
      ) {
    final hint = switch (item.type) {
      PracticeType.fillBlank =>
      'Missing word লিখুন',
      PracticeType.questionAnswer =>
      'আপনার answer লিখুন',
      _ => 'Translation লিখুন',
    };

    final singleLine =
        item.type ==
            PracticeType.fillBlank;

    return TextField(
      controller: _textController,
      enabled: !controller.checked,
      minLines: singleLine ? 1 : 3,
      maxLines: singleLine ? 1 : 5,
      textCapitalization:
      TextCapitalization.sentences,
      onChanged:
      controller.setTextAnswer,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(16),
        ),
        enabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(16),
          borderSide:
          const BorderSide(
            color: _border,
            width: 1.5,
          ),
        ),
        focusedBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(16),
          borderSide:
          const BorderSide(
            color: _teal,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildWordArrange(
      PracticeController controller,
      PracticeItemModel item,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: double.infinity,
          constraints:
          const BoxConstraints(
            minHeight: 82,
          ),
          padding:
          const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.circular(16),
            border: Border.all(
              color: _border,
              width: 1.5,
            ),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: controller
                .arrangedIndexes
                .map(
                  (wordIndex) =>
                  ActionChip(
                    label: Text(
                      item.words[
                      wordIndex],
                    ),
                    onPressed:
                    controller.checked
                        ? null
                        : () {
                      controller
                          .toggleWord(
                        wordIndex,
                      );
                    },
                  ),
            )
                .toList(),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: List<Widget>.generate(
            item.words.length,
                (wordIndex) {
              final isUsed = controller
                  .arrangedIndexes
                  .contains(wordIndex);

              return OutlinedButton(
                onPressed:
                isUsed ||
                    controller
                        .checked
                    ? null
                    : () {
                  controller
                      .toggleWord(
                    wordIndex,
                  );
                },
                child: Text(
                  item.words[wordIndex],
                ),
              );
            },
          ),
        ),
        if (controller
            .arrangedIndexes.isNotEmpty &&
            !controller.checked)
          Align(
            alignment:
            Alignment.centerRight,
            child: TextButton.icon(
              onPressed: controller
                  .clearArrangedWords,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text('Clear'),
            ),
          ),
      ],
    );
  }

  Widget _buildMatching(
      PracticeController controller,
      PracticeItemModel item,
      ) {
    final rightItems = item.pairs
        .map((pair) => pair.right)
        .toList(growable: false)
        .reversed
        .toList(growable: false);

    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            children:
            item.pairs.map((pair) {
              final selected =
                  controller.selectedLeft ==
                      pair.left;

              final matched = controller
                  .matches
                  .containsKey(pair.left);

              return Padding(
                padding:
                const EdgeInsets.only(
                  bottom: 9,
                ),
                child: OutlinedButton(
                  style:
                  OutlinedButton.styleFrom(
                    minimumSize:
                    const Size(
                      double.infinity,
                      52,
                    ),
                    backgroundColor:
                    selected || matched
                        ? _teal
                        .withValues(
                      alpha: 0.12,
                    )
                        : Colors.white,
                    side: BorderSide(
                      color:
                      selected || matched
                          ? _teal
                          : _border,
                    ),
                  ),
                  onPressed:
                  controller.checked
                      ? null
                      : () {
                    controller
                        .selectLeft(
                      pair.left,
                    );
                  },
                  child: Text(
                    pair.left,
                    textAlign:
                    TextAlign.center,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children:
            rightItems.map((right) {
              final used = controller
                  .matches
                  .containsValue(right);

              return Padding(
                padding:
                const EdgeInsets.only(
                  bottom: 9,
                ),
                child: OutlinedButton(
                  style:
                  OutlinedButton.styleFrom(
                    minimumSize:
                    const Size(
                      double.infinity,
                      52,
                    ),
                    backgroundColor: used
                        ? _yellow.withValues(
                      alpha: 0.18,
                    )
                        : Colors.white,
                    side: BorderSide(
                      color: used
                          ? _yellow
                          : _border,
                    ),
                  ),
                  onPressed:
                  controller.checked
                      ? null
                      : () {
                    controller
                        .selectRight(
                      right,
                    );
                  },
                  child: Text(
                    right,
                    textAlign:
                    TextAlign.center,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeLabel(String label) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: _teal.withValues(
          alpha: 0.12,
        ),
        borderRadius:
        BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _teal,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildBottomArea() {
    final controller = _controller!;

    if (controller.checked) {
      return _buildFeedback(
        controller,
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(
        18,
        12,
        18,
        12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: _border,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 54,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _yellow,
              foregroundColor: _ink,
            ),
            onPressed:
            controller.canCheck
                ? () {
              controller
                  .checkAnswer();
            }
                : null,
            child: const Text(
              'Check Answer',
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedback(
      PracticeController controller,
      ) {
    final isCorrect =
        controller.isCorrect == true;

    final feedbackColor =
    isCorrect ? _green : _coral;

    final feedbackBackground =
    isCorrect
        ? const Color(0xFFE2F7EC)
        : const Color(0xFFFFE8E4);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        18,
        15,
        18,
        12,
      ),
      color: feedbackBackground,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  isCorrect
                      ? Icons
                      .check_circle_rounded
                      : Icons
                      .cancel_rounded,
                  color: feedbackColor,
                  size: 30,
                ),
                const SizedBox(width: 9),
                Text(
                  isCorrect
                      ? 'Correct!'
                      : 'Not quite',
                  style: TextStyle(
                    color: feedbackColor,
                    fontSize: 20,
                    fontWeight:
                    FontWeight.w900,
                  ),
                ),
              ],
            ),
            if (!isCorrect) ...<Widget>[
              const SizedBox(height: 9),
              Text(
                'Correct answer: ${controller.correctAnswerText}',
                style: const TextStyle(
                  color: _ink,
                  fontWeight:
                  FontWeight.w800,
                ),
              ),
            ],
            const SizedBox(height: 7),
            Text(
              controller.item.explanation,
              style: const TextStyle(
                color: _ink,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 13),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                style:
                FilledButton.styleFrom(
                  backgroundColor:
                  feedbackColor,
                  foregroundColor:
                  Colors.white,
                ),
                onPressed: _finishing
                    ? null
                    : _continuePractice,
                child: _finishing
                    ? const SizedBox(
                  width: 21,
                  height: 21,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color:
                    Colors.white,
                  ),
                )
                    : Text(
                  controller.isLast
                      ? 'Finish Practice'
                      : 'Continue',
                  style:
                  const TextStyle(
                    fontWeight:
                    FontWeight
                        .w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}