import 'package:flutter/material.dart';
import '../../../core/services/audio_service.dart';
import '../../../data/models/level_model.dart';
import '../../../data/repositories/level_progress_repository.dart';

class ListeningScreen extends StatefulWidget {
  const ListeningScreen({
    super.key,
    required this.level,
    this.audioService,
    this.progressRepository,
  });

  final LevelModel level;
  final AudioService? audioService;
  final LevelProgressRepository? progressRepository;

  @override
  State<ListeningScreen> createState() => _ListeningScreenState();
}

class _ListeningScreenState extends State<ListeningScreen> {
  static const _ink = Color(0xFF08100E);
  static const _teal = Color(0xFF00BFAE);
  static const _coral = Color(0xFFFF6B57);
  static const _green = Color(0xFF20A66A);
  static const _background = Color(0xFFF5F9F8);
  static const _muted = Color(0xFF66736F);
  static const _border = Color(0xFFDCE5E2);

  late final AudioService _audioService;
  late final LevelProgressRepository _progressRepository;
  final TextEditingController _textController = TextEditingController();

  bool _loading = true;
  bool _isSpeaking = false;
  bool _isSlowAudio = false;
  bool _checked = false;
  bool? _isCorrect;
  bool _cantHearState = false;
  bool _finishing = false;
  bool _allowPop = false;
  String? _error;

  int _currentIndex = 0;
  final int _totalItems = 5;
  final String _correctAnswer = "I want to learn English";

  @override
  void initState() {
    super.initState();
    _audioService = widget.audioService ?? AudioService();
    _progressRepository = widget.progressRepository ?? LevelProgressRepository();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _audioService.initialize();
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      _playAudio(slow: false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load listening practice.';
      });
    }
  }

  @override
  void dispose() {
    _audioService.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _playAudio({required bool slow}) async {
    if (_isSpeaking) return;

    setState(() {
      _isSpeaking = true;
      _isSlowAudio = slow;
    });

    try {
      await _audioService.speak(_correctAnswer, slow: slow);
    } catch (error) {
      debugPrint('TTS error: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
      }
    }
  }

  void _checkAnswer() {
    final userAnswer = _textController.text.trim().toLowerCase();
    final actualAnswer = _correctAnswer.toLowerCase();

    setState(() {
      _checked = true;
      _isCorrect = userAnswer.replaceAll(RegExp(r'[^\w\s]'), '') ==
          actualAnswer.replaceAll(RegExp(r'[^\w\s]'), '');
    });
  }

  void _skipBecauseCantHear() {
    setState(() {
      _cantHearState = true;
      _checked = true;
      _isCorrect = false;
    });
  }

  Future<void> _continue() async {
    if (_finishing) return;
    await _audioService.stop();

    if (_currentIndex == _totalItems - 1) {
      _finishPractice();
      return;
    }

    setState(() {
      _currentIndex++;
      _checked = false;
      _isCorrect = null;
      _cantHearState = false;
      _textController.clear();
    });

    Future.delayed(const Duration(milliseconds: 300), () => _playAudio(slow: false));
  }

  Future<void> _finishPractice() async {
    setState(() => _finishing = true);
    try {
      await _progressRepository.completeStage(
        levelId: widget.level.id,
        totalPractices: widget.level.totalPractices,
        minimumCompletedPractices: 5,
        nextStage: 3,
      );

      if (!mounted) return;
      setState(() => _allowPop = true);
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _finishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save progress.')),
      );
    }
  }

  Future<void> _confirmClose() async {
    if (_allowPop) {
      Navigator.of(context).pop();
      return;
    }

    await _audioService.stop();
    if (!mounted) return;

    final shouldClose = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Quit Practice?',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: const Text('Your progress for this lesson will be saved.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep Practicing'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _coral,
                foregroundColor: Colors.white,
              ),
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
        body: SafeArea(
          child: Column(
            children: <Widget>[
              _buildTopBar(),
              Expanded(child: _buildBody()),
              if (!_loading && _error == null) _buildBottomArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final progressValue = _loading ? 0.0 : (_currentIndex + 1) / _totalItems;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 18, 10),
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: 'Close practice',
            onPressed: _confirmClose,
            icon: const Icon(Icons.close_rounded, color: _ink, size: 28),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: progressValue,
                minHeight: 11,
                backgroundColor: const Color(0xFFE0E8E6),
                color: _teal,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _loading ? '0/0' : '${_currentIndex + 1}/$_totalItems',
            style: const TextStyle(color: _ink, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _teal));
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: _coral)));
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: SingleChildScrollView(
        key: ValueKey<int>(_currentIndex),
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          children: <Widget>[
            const Text(
              'Type what you hear',
              style: TextStyle(
                color: _ink,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAudioButton(
                  icon: Icons.volume_up_rounded,
                  size: 80,
                  iconSize: 42,
                  isSlow: false,
                ),
                const SizedBox(width: 24),
                _buildAudioButton(
                  icon: Icons.slow_motion_video_rounded,
                  size: 60,
                  iconSize: 30,
                  isSlow: true,
                ),
              ],
            ),

            const SizedBox(height: 40),

            TextField(
              controller: _textController,
              enabled: !_checked,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (val) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Tap to type...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _border, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _teal, width: 2),
                ),
              ),
            ),

            const SizedBox(height: 24),

            if (!_checked)
              TextButton(
                onPressed: _skipBecauseCantHear,
                child: const Text(
                  "I can't listen right now",
                  style: TextStyle(
                    color: _muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioButton({
    required IconData icon,
    required double size,
    required double iconSize,
    required bool isSlow,
  }) {
    final isActive = _isSpeaking && _isSlowAudio == isSlow;

    return GestureDetector(
      onTap: () => _playAudio(slow: isSlow),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isActive ? _teal.withValues(alpha: 0.15) : _teal,
          shape: BoxShape.circle,
          boxShadow: isActive ? [] : [
            BoxShadow(
              color: _teal.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Icon(
          isActive ? Icons.more_horiz_rounded : icon,
          color: isActive ? _teal : Colors.white,
          size: iconSize,
        ),
      ),
    );
  }

  Widget _buildBottomArea() {
    if (_checked) {
      return _buildFeedback();
    }

    final hasText = _textController.text.trim().isNotEmpty;

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
              backgroundColor: hasText ? _teal : _border,
              foregroundColor: hasText ? Colors.white : _muted,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: hasText ? _checkAnswer : null,
            child: const Text(
              'Check Answer',
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
                  size: 30,
                ),
                const SizedBox(width: 9),
                Text(
                  _cantHearState
                      ? 'Skipped for now'
                      : (isCorrect ? 'Excellent!' : 'Not quite'),
                  style: TextStyle(
                    color: feedbackColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            if (!isCorrect) ...<Widget>[
              const SizedBox(height: 9),
              const Text(
                'Correct answer:',
                style: TextStyle(color: _ink, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                _correctAnswer,
                style: const TextStyle(color: _ink, fontSize: 16, height: 1.4),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _finishing ? null : _continue,
                child: _finishing
                    ? const SizedBox(
                  width: 21,
                  height: 21,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
                    : Text(
                  _currentIndex == _totalItems - 1 ? 'Finish Listening' : 'Continue',
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