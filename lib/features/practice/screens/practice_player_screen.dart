import 'package:flutter/material.dart';
import '../../../core/services/audio_service.dart';
import '../../../data/models/level_model.dart';
import '../../../data/models/practice_item_model.dart';
import '../../../data/models/practice_model.dart';
import '../../../data/repositories/level_progress_repository.dart';
import '../controllers/practice_controller.dart';

class PracticePlayerScreen extends StatefulWidget {
  const PracticePlayerScreen({
    super.key,
    required this.level,
    this.progressRepository,
  });

  final LevelModel level;
  final LevelProgressRepository? progressRepository;

  @override
  State<PracticePlayerScreen> createState() => _PracticePlayerScreenState();
}

class _PracticePlayerScreenState extends State<PracticePlayerScreen> {
  // Design System Colors
  static const _ink = Color(0xFF08100E);
  static const _teal = Color(0xFF58C3A4);
  static const _tealBg = Color(0xFFE8F6F2);
  static const _coral = Color(0xFFFF4B4B);
  static const _green = Color(0xFF58CC02);
  static const _background = Color(0xFFF7F9F9);
  static const _muted = Color(0xFF777777);
  static const _border = Color(0xFFE5E5E5);
  static const _disabledBtn = Color(0xFFE5E5E5);
  static const _disabledText = Color(0xFFAFAFAF);

  late final LevelProgressRepository _repository;
  late final AudioService _ttsService;
  final TextEditingController _textController = TextEditingController();

  PracticeController? _controller;

  bool _loading = true;
  bool _finishing = false;
  bool _allowPop = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = widget.progressRepository ?? LevelProgressRepository();
    _ttsService = AudioService();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _ttsService.initialize();
      final practice = PracticeModel.fromLevel(widget.level);
      final savedIndex = await _repository.loadSectionPosition(
        levelId: widget.level.id,
        sectionId: practice.id,
      );
      final controller = PracticeController(
        practice: practice,
        initialIndex: savedIndex,
      );

      controller.addListener(_onControllerChanged);

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
      debugPrint('Practice load error: $error');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'এই level-এর Practice content load করা যায়নি।';
      });
    }
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerChanged);
    _controller?.dispose();
    _textController.dispose();
    _ttsService.dispose();
    super.dispose();
  }

  // --- TTS Logic ---
  Future<void> _playTts(String text) async {
    await _ttsService.speak(text);
  }

  // --- Hint System ---
  void _showHint() {
    final hintText = _controller?.item.explanation ?? 'Think about the grammar structure.';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFFFC928), size: 32),
                const SizedBox(width: 12),
                const Text('Hint', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _ink)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            Text(hintText, style: const TextStyle(fontSize: 16, color: _muted, height: 1.5)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // --- Core Practice Logic ---
  void _handleCheckAnswer() {
    if (_controller == null) return;
    _controller!.checkAnswer();
  }

  Future<void> _continuePractice() async {
    final controller = _controller;
    if (controller == null || !controller.checked || _finishing) return;

    if (controller.isLast) {
      await _finishPractice();
      return;
    }

    controller.moveToNext();
    _textController.clear();

    await _repository.saveSectionPosition(
      levelId: widget.level.id,
      sectionId: controller.practice.id,
      itemIndex: controller.index,
    );
  }

  Future<void> _finishPractice() async {
    final controller = _controller;
    if (controller == null || _finishing) return;

    setState(() => _finishing = true);

    try {
      await _repository.completeStage(
        levelId: widget.level.id,
        totalPractices: widget.level.totalPractices,
        minimumCompletedPractices: controller.practice.progressAfterCompletion,
        nextStage: 2,
      );

      await _repository.clearSectionPosition(
        levelId: widget.level.id,
        sectionId: controller.practice.id,
      );

      if (!mounted) return;
      setState(() => _allowPop = true);
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _finishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Progress save করা যায়নি। আবার চেষ্টা করুন।'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _confirmClose() async {
    final shouldClose = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Practice বন্ধ করবেন?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Completed question-এর position save থাকবে। পরে এখান থেকেই শুরু করতে পারবেন।'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Practice চালিয়ে যান', style: TextStyle(color: _ink)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _coral, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('বন্ধ করুন'),
          ),
        ],
      ),
    );

    if (shouldClose == true && mounted) {
      setState(() => _allowPop = true);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmClose();
      },
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: Column(
            children: <Widget>[
              _buildHeader(),
              Expanded(child: _buildBody()),
              if (!_loading && _error == null) _buildBottomArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final controller = _controller;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 18, 10),
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: 'Close practice',
            onPressed: _confirmClose,
            icon: const Icon(Icons.close_rounded, size: 28, color: _muted),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: controller?.progress ?? 0,
                minHeight: 12,
                color: _teal,
                backgroundColor: _border,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            controller == null ? '0/0' : '${controller.index + 1}/${controller.total}',
            style: const TextStyle(fontWeight: FontWeight.w900, color: _ink),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _teal));
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline_rounded, color: _coral, size: 50),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _initialize();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('আবার চেষ্টা করুন'),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _controller!;
    final item = controller.item;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: SingleChildScrollView(
        key: ValueKey<String>(item.id),
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _tealBg,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                item.typeLabel,
                style: const TextStyle(color: _teal, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.8),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.question,
                    style: const TextStyle(color: _ink, fontSize: 28, height: 1.25, fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  onPressed: () => _playTts(item.question),
                  icon: const Icon(Icons.volume_up_rounded, color: _teal, size: 30),
                  style: IconButton.styleFrom(backgroundColor: _tealBg),
                ),
              ],
            ),
            if (item.questionBn.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                item.questionBn,
                style: const TextStyle(color: _muted, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
            const SizedBox(height: 32),
            _buildAnswerArea(controller, item),
            const SizedBox(height: 32),
            if (!controller.checked)
              TextButton.icon(
                onPressed: _showHint,
                icon: const Icon(Icons.lightbulb_outline_rounded, color: _teal),
                label: const Text('Need a hint?', style: TextStyle(color: _teal, fontWeight: FontWeight.w700, fontSize: 16)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerArea(PracticeController controller, PracticeItemModel item) {
    return switch (item.type) {
      PracticeType.mcq => _buildMcq(controller, item),
      PracticeType.banglaToEnglish ||
      PracticeType.englishToBangla ||
      PracticeType.fillBlank ||
      PracticeType.questionAnswer => _buildTextAnswer(controller, item),
      PracticeType.wordArrange => _buildWordArrange(controller, item),
      PracticeType.matching => _buildMatching(controller, item),
    };
  }

  Widget _buildMcq(PracticeController controller, PracticeItemModel item) {
    return Column(
      children: <Widget>[
        for (var index = 0; index < item.options.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: controller.checked ? null : () => controller.selectOption(item.options[index]),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: controller.selectedOption == item.options[index] ? _tealBg : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: controller.selectedOption == item.options[index] ? _teal : _border,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: controller.selectedOption == item.options[index] ? _teal : const Color(0xFFF0F4F3),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: controller.selectedOption == item.options[index] ? Colors.white : _ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        item.options[index],
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _ink),
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

  Widget _buildTextAnswer(PracticeController controller, PracticeItemModel item) {
    final hint = switch (item.type) {
      PracticeType.fillBlank => 'Missing word লিখুন',
      PracticeType.questionAnswer => 'আপনার answer লিখুন',
      _ => 'Translation লিখুন',
    };
    final singleLine = item.type == PracticeType.fillBlank;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 2),
      ),
      child: TextField(
        controller: _textController,
        enabled: !controller.checked,
        minLines: singleLine ? 1 : 4,
        maxLines: singleLine ? 1 : 4,
        textCapitalization: TextCapitalization.sentences,
        onChanged: controller.setTextAnswer,
        style: const TextStyle(fontSize: 18, color: _ink, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _muted, fontWeight: FontWeight.w500),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildWordArrange(PracticeController controller, PracticeItemModel item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 100),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border, width: 2),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: controller.arrangedIndexes.map((wordIndex) => ActionChip(
              label: Text(item.words[wordIndex], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              backgroundColor: _tealBg,
              side: const BorderSide(color: _teal),
              onPressed: controller.checked ? null : () => controller.toggleWord(wordIndex),
            )).toList(),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List<Widget>.generate(
            item.words.length,
                (wordIndex) {
              final isUsed = controller.arrangedIndexes.contains(wordIndex);
              return OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: isUsed ? _disabledBtn : Colors.white,
                  side: const BorderSide(color: _border, width: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isUsed || controller.checked ? null : () => controller.toggleWord(wordIndex),
                child: Text(
                  item.words[wordIndex],
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isUsed ? _disabledText : _ink),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMatching(PracticeController controller, PracticeItemModel item) {
    final rightItems = item.pairs.map((pair) => pair.right).toList().reversed.toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            children: item.pairs.map((pair) {
              final selected = controller.selectedLeft == pair.left;
              final matched = controller.matches.containsKey(pair.left);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    backgroundColor: selected || matched ? _tealBg : Colors.white,
                    side: BorderSide(color: selected || matched ? _teal : _border, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: controller.checked ? null : () => controller.selectLeft(pair.left),
                  child: Text(pair.left, textAlign: TextAlign.center, style: TextStyle(color: selected || matched ? _teal : _ink, fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: rightItems.map((right) {
              final used = controller.matches.containsValue(right);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    backgroundColor: used ? const Color(0xFFFFF7DD) : Colors.white,
                    side: BorderSide(color: used ? const Color(0xFFFFC928) : _border, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: controller.checked ? null : () => controller.selectRight(right),
                  child: Text(right, textAlign: TextAlign.center, style: TextStyle(color: used ? const Color(0xFFC79A00) : _ink, fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomArea() {
    final controller = _controller!;

    if (controller.checked) {
      return _buildFeedback(controller);
    }

    final canCheck = controller.canCheck;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: canCheck ? _teal : _disabledBtn,
              foregroundColor: canCheck ? Colors.white : _disabledText,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: canCheck ? _handleCheckAnswer : null,
            child: const Text(
              'Check Answer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedback(PracticeController controller) {
    final isCorrect = controller.isCorrect == true;
    final feedbackColor = isCorrect ? _green : _coral;
    final feedbackBackground = isCorrect ? const Color(0xFFD7FFB8) : const Color(0xFFFFE8E4);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      color: feedbackBackground,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded, color: feedbackColor, size: 36),
                const SizedBox(width: 12),
                Text(
                  isCorrect ? 'Excellent!' : 'Incorrect',
                  style: TextStyle(color: feedbackColor, fontSize: 24, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            if (!isCorrect) ...<Widget>[
              const SizedBox(height: 12),
              Text('Correct answer:', style: TextStyle(color: feedbackColor, fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 4),
              Text(controller.correctAnswerText, style: TextStyle(color: feedbackColor, fontSize: 18, fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: feedbackColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _finishing ? null : _continuePractice,
                child: _finishing
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                    : Text(controller.isLast ? 'Finish Practice' : 'Continue', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}