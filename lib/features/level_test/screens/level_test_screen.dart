
import 'package:flutter/material.dart';
import '../../../data/models/level_model.dart';
import '../../../data/repositories/level_progress_repository.dart';

class LevelTestScreen extends StatefulWidget {
  const LevelTestScreen({
    super.key,
    required this.level,
    this.progressRepository,
  });

  final LevelModel level;
  final LevelProgressRepository? progressRepository;

  @override
  State<LevelTestScreen> createState() => _LevelTestScreenState();
}

class _LevelTestScreenState extends State<LevelTestScreen> {
  // Design System Colors
  static const _ink = Color(0xFF08100E);
  static const _teal = Color(0xFF00BFAE);
  static const _yellow = Color(0xFFFFC928);
  static const _coral = Color(0xFFFF6B57);
  static const _green = Color(0xFF20A66A);
  static const _background = Color(0xFFF5F9F8);
  static const _muted = Color(0xFF66736F);
  static const _border = Color(0xFFDCE5E2);

  late final LevelProgressRepository _progressRepository;

  // Test States
  bool _loading = true;
  bool _checked = false;
  bool? _isCorrect;
  bool _finishing = false;
  bool _allowPop = false;

  int _currentIndex = 0;
  final int _totalQuestions = 15;
  int _score = 0;

  String? _selectedOption;

  // Mocking Question Data (In reality, fetch 15 random/mixed questions from level data)
  final List<String> _options = ["I am learning", "She is learning", "He learns", "We learn"];
  final String _correctAnswer = "I am learning";

  @override
  void initState() {
    super.initState();
    _progressRepository = widget.progressRepository ?? LevelProgressRepository();
    _initializeTest();
  }

  Future<void> _initializeTest() async {
    // Mock loading delay for test generation
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _loading = false;
    });
  }

  void _selectOption(String option) {
    if (_checked) return;
    setState(() {
      _selectedOption = option;
    });
  }

  void _submitAnswer() {
    if (_selectedOption == null || _checked) return;

    setState(() {
      _checked = true;
      _isCorrect = _selectedOption == _correctAnswer;
      if (_isCorrect == true) {
        _score++;
      }
    });
  }

  Future<void> _nextQuestion() async {
    if (_finishing) return;

    if (_currentIndex == _totalQuestions - 1) {
      _finishTest();
      return;
    }

    setState(() {
      _currentIndex++;
      _checked = false;
      _isCorrect = null;
      _selectedOption = null;
    });
  }

  Future<void> _finishTest() async {
    setState(() => _finishing = true);

    // Calculate final score percentage
    final double scorePercentage = (_score / _totalQuestions) * 100;
    final bool passed = scorePercentage >= widget.level.passPercentage;

    try {
      if (passed) {
        // Save progress only if passed
        await _progressRepository.markLevelCompleted(
          levelId: widget.level.id,
          totalPractices: widget.level.totalPractices,
        );
      }

      if (!mounted) return;
      setState(() => _allowPop = true);

      // Navigate to Result Screen (Screen 11) with score data
      // For now, we pop with a result map
      Navigator.of(context).pop({
        'score': _score,
        'total': _totalQuestions,
        'passed': passed,
      });

    } catch (error) {
      if (!mounted) return;
      setState(() => _finishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save test results.')),
      );
    }
  }

  Future<void> _confirmClose() async {
    if (_allowPop) {
      Navigator.of(context).pop();
      return;
    }

    final shouldClose = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancel Test?', style: TextStyle(fontWeight: FontWeight.w900)),
          content: const Text('If you leave now, your test progress will be lost and you will get a 0 score.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Continue Test'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _coral, foregroundColor: Colors.white),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Quit'),
            ),
          ],
        );
      },
    );

    if (shouldClose == true && mounted) {
      setState(() => _allowPop = true);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmClose();
      },
      child: Scaffold(
        backgroundColor: _background,
        appBar: _buildAppBar(),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              _buildProgressBar(),
              Expanded(child: _buildBody()),
              if (!_loading) _buildBottomArea(),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _background,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, color: _ink, size: 28),
        onPressed: _confirmClose,
      ),
      title: const Text(
        'Level Test',
        style: TextStyle(color: _ink, fontWeight: FontWeight.w900, fontSize: 18),
      ),
      centerTitle: true,
    );
  }

  Widget _buildProgressBar() {
    final progressValue = _loading ? 0.0 : (_currentIndex + 1) / _totalQuestions;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: progressValue,
                minHeight: 10,
                backgroundColor: const Color(0xFFE0E8E6),
                color: _teal,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _loading ? '0/0' : '${_currentIndex + 1}/$_totalQuestions',
            style: const TextStyle(color: _muted, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _teal));
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _coral.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Text(
              'TEST QUESTION',
              style: TextStyle(color: _coral, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'আমি শিখছি',
            style: TextStyle(color: _ink, fontSize: 26, height: 1.25, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select the correct English translation:',
            style: TextStyle(color: _muted, fontSize: 15),
          ),
          const SizedBox(height: 32),

          // Options List
          ..._options.map((option) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => _selectOption(option),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _selectedOption == option ? _teal.withValues(alpha: 0.12) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedOption == option ? _teal : _border,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedOption == option ? _teal : _muted.withValues(alpha: 0.5),
                          width: 2,
                        ),
                        color: _selectedOption == option ? _teal : Colors.transparent,
                      ),
                      child: _selectedOption == option
                          ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        option,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildBottomArea() {
    if (_checked) {
      return _buildFeedback();
    }

    final hasSelection = _selectedOption != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 54,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: hasSelection ? _yellow : _border,
              foregroundColor: hasSelection ? _ink : _muted,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: hasSelection ? _submitAnswer : null,
            child: const Text(
              'Submit Answer',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedback() {
    final isCorrect = _isCorrect == true;
    final feedbackColor = isCorrect ? _green : _coral;
    final feedbackBackground = isCorrect ? const Color(0xFFE2F7EC) : const Color(0xFFFFE8E4);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 12),
      color: feedbackBackground,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: feedbackColor,
                  size: 28,
                ),
                const SizedBox(width: 9),
                Text(
                  isCorrect ? 'Correct!' : 'Incorrect',
                  style: TextStyle(
                    color: feedbackColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            if (!isCorrect) ...[
              const SizedBox(height: 8),
              Text(
                'Correct answer: $_correctAnswer',
                style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: feedbackColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _finishing ? null : _nextQuestion,
                child: _finishing
                    ? const SizedBox(
                  width: 21,
                  height: 21,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                )
                    : Text(
                  _currentIndex == _totalQuestions - 1 ? 'Finish Test' : 'Next Question',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}