import 'package:flutter/material.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/speech_service.dart';
import '../../../data/models/level_model.dart';
import '../../../data/repositories/level_progress_repository.dart';

class SpeakingScreen extends StatefulWidget {
  const SpeakingScreen({
    super.key,
    required this.level,
    this.audioService,
    this.speechService,
    this.progressRepository,
  });

  final LevelModel level;
  final AudioService? audioService;
  final SpeechService? speechService;
  final LevelProgressRepository? progressRepository;

  @override
  State<SpeakingScreen> createState() => _SpeakingScreenState();
}

enum SpeakingFeedback { none, correct, almost, tryAgain }

class _SpeakingScreenState extends State<SpeakingScreen> with SingleTickerProviderStateMixin {
  static const _ink = Color(0xFF08100E);
  static const _teal = Color(0xFF00BFAE);
  static const _yellow = Color(0xFFFFC928);
  static const _coral = Color(0xFFFF6B57);
  static const _green = Color(0xFF20A66A);
  static const _background = Color(0xFFF5F9F8);
  static const _muted = Color(0xFF66736F);
  static const _border = Color(0xFFDCE5E2);

  late final AudioService _audioService;
  late final SpeechService _speechService;
  late final LevelProgressRepository _progressRepository;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  bool _loading = true;
  bool _isSpeaking = false;
  bool _isListening = false;
  String _recognizedText = '';
  SpeakingFeedback _feedback = SpeakingFeedback.none;
  final bool _micDenied = false; // Set this based on actual permissions
  bool _finishing = false;
  bool _allowPop = false;
  String? _error;

  int _currentIndex = 0;
  final int _totalItems = 5;
  final String _targetSentence = "How are you doing today?";
  final String _targetBangla = "আপনি আজ কেমন আছেন?";

  @override
  void initState() {
    super.initState();
    _audioService = widget.audioService ?? AudioService();
    _speechService = widget.speechService ?? SpeechService();
    _progressRepository = widget.progressRepository ?? LevelProgressRepository();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _audioService.initialize();
      await _speechService.initialize();

      if (!mounted) return;
      setState(() {
        _loading = false;
      });

      _playExampleAudio();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load speaking practice.';
      });
    }
  }

  @override
  void dispose() {
    _audioService.dispose();
    _speechService.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _playExampleAudio() async {
    if (_isSpeaking || _isListening) return;

    setState(() => _isSpeaking = true);
    try {
      await _audioService.speak(_targetSentence, slow: false);
    } catch (error) {
      debugPrint('TTS error: $error');
    } finally {
      if (mounted) setState(() => _isSpeaking = false);
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  Future<void> _startListening() async {
    if (_micDenied) return;

    setState(() {
      _isListening = true;
      _recognizedText = '';
      _feedback = SpeakingFeedback.none;
    });
    _pulseController.repeat(reverse: true);

    await _speechService.startListening();

    await Future.delayed(const Duration(seconds: 3));
    if (!_isListening) return;

    setState(() {
      _recognizedText = "How are you doing";
    });

    _stopListening();
  }

  void _stopListening() {
    _speechService.stopListening();
    _pulseController.stop();
    _pulseController.reset();
    setState(() {
      _isListening = false;
    });
    _evaluateSpeech();
  }

  void _evaluateSpeech() {
    if (_recognizedText.isEmpty) return;

    final recognized = _recognizedText.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    final target = _targetSentence.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');

    setState(() {
      if (recognized == target) {
        _feedback = SpeakingFeedback.correct;
      } else if (target.contains(recognized) || recognized.contains(target)) {
        _feedback = SpeakingFeedback.almost;
      } else {
        _feedback = SpeakingFeedback.tryAgain;
      }
    });
  }

  // Warning fixed: Removed unused _handleMicDenied()

  Future<void> _continue() async {
    if (_finishing) return;
    await _audioService.stop();

    if (_currentIndex == _totalItems - 1) {
      _finishPractice();
      return;
    }

    setState(() {
      _currentIndex++;
      _feedback = SpeakingFeedback.none;
      _recognizedText = '';
    });

    Future.delayed(const Duration(milliseconds: 300), _playExampleAudio);
  }

  Future<void> _finishPractice() async {
    setState(() => _finishing = true);
    try {
      await _progressRepository.completeStage(
        levelId: widget.level.id,
        totalPractices: widget.level.totalPractices,
        minimumCompletedPractices: 5,
        nextStage: 4,
      );

      if (!mounted) return;
      setState(() => _allowPop = true);
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _finishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Progress save failed.')),
      );
    }
  }

  Future<void> _confirmClose() async {
    if (_allowPop) {
      Navigator.of(context).pop();
      return;
    }

    await _audioService.stop();
    if (_isListening) _stopListening();
    if (!mounted) return;

    final shouldClose = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Quit Practice?', style: TextStyle(fontWeight: FontWeight.w900)),
          content: const Text('Your progress for this lesson will be saved.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep Practicing'),
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
    if (_loading) return const Center(child: CircularProgressIndicator(color: _teal));
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: _coral)));

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        children: <Widget>[
          const Text(
            'Speak this sentence',
            style: TextStyle(color: _muted, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24),
          Text(
            _targetSentence,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _ink, fontSize: 28, height: 1.25, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Text(
            _targetBangla,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 16, height: 1.45),
          ),
          const SizedBox(height: 24),

          IconButton(
            onPressed: _playExampleAudio,
            style: IconButton.styleFrom(
              backgroundColor: _teal.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(12),
            ),
            icon: Icon(
                _isSpeaking ? Icons.more_horiz_rounded : Icons.volume_up_rounded,
                color: _teal,
                size: 28
            ),
          ),

          const SizedBox(height: 48),

          if (_micDenied)
            _buildMicDeniedWarning()
          else
            _buildMicButton(),

          const SizedBox(height: 36),

          if (_recognizedText.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: Column(
                children: [
                  const Text('You said:', style: TextStyle(color: _muted, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    _recognizedText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _feedback == SpeakingFeedback.tryAgain ? _coral : _ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMicButton() {
    return GestureDetector(
      onTap: _toggleListening,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isListening ? _pulseAnimation.value : 1.0,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _isListening ? _coral : _teal,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isListening ? _coral : _teal).withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: _isListening ? 10 : 0,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMicDeniedWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE8E4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _coral.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.mic_off_rounded, color: _coral, size: 32),
          const SizedBox(height: 8),
          const Text(
            'Microphone access is denied. Please enable it in Settings to practice speaking.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _ink, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(backgroundColor: _coral),
            child: const Text('Open Settings'),
          )
        ],
      ),
    );
  }

  Widget _buildBottomArea() {
    if (_feedback == SpeakingFeedback.none) {
      return const SizedBox.shrink();
    }

    final isCorrect = _feedback == SpeakingFeedback.correct;
    final isAlmost = _feedback == SpeakingFeedback.almost;

    Color feedbackColor;
    String feedbackTitle;
    Color feedbackBg;
    IconData feedbackIcon;

    if (isCorrect) {
      feedbackColor = _green;
      feedbackTitle = 'Perfect pronunciation!';
      feedbackBg = const Color(0xFFE2F7EC);
      feedbackIcon = Icons.check_circle_rounded;
    } else if (isAlmost) {
      feedbackColor = _yellow;
      feedbackTitle = 'Almost there!';
      feedbackBg = const Color(0xFFFFF7DD);
      feedbackIcon = Icons.info_rounded;
    } else {
      feedbackColor = _coral;
      feedbackTitle = 'Let\'s try again';
      feedbackBg = const Color(0xFFFFE8E4);
      feedbackIcon = Icons.refresh_rounded;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 12),
      color: feedbackBg,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(feedbackIcon, color: feedbackColor, size: 28),
                const SizedBox(width: 9),
                Text(
                  feedbackTitle,
                  style: TextStyle(
                    color: feedbackColor == _yellow ? _ink : feedbackColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isCorrect || isAlmost)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: feedbackColor,
                    foregroundColor: feedbackColor == _yellow ? _ink : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _finishing ? null : _continue,
                  child: _finishing
                      ? const SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                  )
                      : Text(
                    _currentIndex == _totalItems - 1 ? 'Finish Speaking' : 'Continue',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _coral,
                    side: const BorderSide(color: _coral, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    setState(() {
                      _feedback = SpeakingFeedback.none;
                      _recognizedText = '';
                    });
                  },
                  child: const Text('Try Again', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}