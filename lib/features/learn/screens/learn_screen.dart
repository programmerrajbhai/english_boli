import 'package:flutter/material.dart';

import '../../../core/services/audio_service.dart';
import '../../../data/models/learn_item_model.dart';
import '../../../data/models/level_model.dart';
import '../../../data/repositories/level_progress_repository.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({
    super.key,
    required this.level,
    this.audioService,
    this.progressRepository,
  });

  final LevelModel level;
  final AudioService? audioService;
  final LevelProgressRepository? progressRepository;

  @override
  State<LearnScreen> createState() {
    return _LearnScreenState();
  }
}

class _LearnScreenState extends State<LearnScreen> {
  static const _ink = Color(0xFF08100E);
  static const _teal = Color(0xFF00BFAE);
  static const _yellow = Color(0xFFFFC928);
  static const _coral = Color(0xFFFF6B57);
  static const _background = Color(0xFFF5F9F8);
  static const _muted = Color(0xFF66736F);
  static const _border = Color(0xFFDCE5E2);

  late final AudioService _audioService;
  late final LevelProgressRepository _progressRepository;

  List<LearnItemModel> _items = const <LearnItemModel>[];

  int _currentIndex = 0;

  bool _loading = true;
  bool _isSpeaking = false;
  bool _isSlowAudio = false;
  bool _isCompleting = false;
  bool _allowPop = false;

  String? _error;

  LearnItemModel get _currentItem {
    return _items[_currentIndex];
  }

  double get _progress {
    if (_items.isEmpty) {
      return 0;
    }

    return (_currentIndex + 1) / _items.length;
  }

  @override
  void initState() {
    super.initState();

    _audioService = widget.audioService ?? AudioService();

    _progressRepository =
        widget.progressRepository ?? LevelProgressRepository();

    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final items = LearnItemModel.fromLevel(widget.level);

      final levelProgress = await _progressRepository.loadLevel(
        widget.level.id,
      );

      final savedIndex = await _progressRepository.loadSectionPosition(
        levelId: widget.level.id,
        sectionId: 'learn',
      );

      await _audioService.initialize();

      if (!mounted) {
        return;
      }

      setState(() {
        _items = items;

        _currentIndex = levelProgress.currentStage > 0
            ? 0
            : savedIndex.clamp(0, items.length - 1).toInt();

        _loading = false;
        _error = null;
      });
    } catch (error) {
      debugPrint('Learn screen error: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = 'এই level-এর Learn content load করা যায়নি।';
      });
    }
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _playAudio({required bool slow}) async {
    if (_isSpeaking || _items.isEmpty) {
      return;
    }

    setState(() {
      _isSpeaking = true;
      _isSlowAudio = slow;
    });

    try {
      await _audioService.speak(_currentItem.english, slow: slow);
    } catch (error) {
      debugPrint('TTS error: $error');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Audio play করা যায়নি। Device-এর TTS language check করুন।',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
      }
    }
  }

  Future<void> _previous() async {
    if (_currentIndex <= 0 || _isCompleting) {
      return;
    }

    await _audioService.stop();

    final previousIndex = _currentIndex - 1;

    await _progressRepository.saveSectionPosition(
      levelId: widget.level.id,
      sectionId: 'learn',
      itemIndex: previousIndex,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _currentIndex = previousIndex;
      _isSpeaking = false;
    });
  }

  Future<void> _continue() async {
    if (_items.isEmpty || _isCompleting) {
      return;
    }

    await _audioService.stop();

    final isLastItem = _currentIndex == _items.length - 1;

    if (isLastItem) {
      await _completeLearn();
      return;
    }

    final nextIndex = _currentIndex + 1;

    await _progressRepository.saveSectionPosition(
      levelId: widget.level.id,
      sectionId: 'learn',
      itemIndex: nextIndex,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _currentIndex = nextIndex;
      _isSpeaking = false;
    });
  }

  Future<void> _completeLearn() async {
    if (_isCompleting) {
      return;
    }

    setState(() {
      _isCompleting = true;
    });

    try {
      await _progressRepository.completeStage(
        levelId: widget.level.id,
        totalPractices: widget.level.totalPractices,
        minimumCompletedPractices: _items.length,
        nextStage: 1,
      );

      await _progressRepository.clearSectionPosition(
        levelId: widget.level.id,
        sectionId: 'learn',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _allowPop = true;
      });

      Navigator.of(context).pop(true);
    } catch (error) {
      debugPrint('Learn completion error: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _isCompleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Progress save করা যায়নি। আবার চেষ্টা করুন।'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmClose() async {
    if (_allowPop) {
      Navigator.of(context).pop();
      return;
    }

    await _audioService.stop();

    if (!mounted) {
      return;
    }

    final shouldClose = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Lesson বন্ধ করবেন?',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: const Text(
            'আপনার বর্তমান position save থাকবে। পরে এখান থেকেই continue করতে পারবেন।',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('শিখতে থাকুন'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _coral,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('বন্ধ করুন'),
            ),
          ],
        );
      },
    );

    if (shouldClose != true || !mounted) {
      return;
    }

    setState(() {
      _allowPop = true;
    });

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _confirmClose();
        }
      },
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: Column(
            children: <Widget>[
              _buildTopBar(),
              Expanded(child: _buildBody()),
              if (!_loading && _error == null) _buildBottomButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final progressValue = _loading ? 0.0 : _progress;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 18, 10),
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: 'Close lesson',
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
            _loading ? '0/0' : '${_currentIndex + 1}/${_items.length}',
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline_rounded, color: _coral, size: 50),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
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

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.06, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: SingleChildScrollView(
        key: ValueKey<String>(_currentItem.id),
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          children: <Widget>[
            _buildLessonLabel(),
            const SizedBox(height: 18),
            _buildIllustration(_currentItem.illustrationKey),
            const SizedBox(height: 25),
            Text(
              _currentItem.english,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ink,
                fontSize: _currentItem.type == LearnItemType.word ? 38 : 29,
                height: 1.2,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _currentItem.bangla,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _muted,
                fontSize: 18,
                height: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            _buildAudioButtons(),
            const SizedBox(height: 22),
            _buildExampleCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonLabel() {
    final label = _currentItem.type == LearnItemType.word
        ? 'NEW WORD'
        : 'NEW SENTENCE';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: _teal.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _teal,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildIllustration(String illustrationKey) {
    final illustration = _illustrationFor(illustrationKey);

    return Semantics(
      image: true,
      label: '$illustrationKey illustration',
      child: Container(
        width: double.infinity,
        height: 190,
        decoration: BoxDecoration(
          color: illustration.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: illustration.color.withValues(alpha: 0.24)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Positioned(left: 25, top: 24, child: _decorationDot(22, _yellow)),
            Positioned(
              right: 28,
              bottom: 25,
              child: _decorationDot(16, _coral),
            ),
            Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                color: illustration.color,
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: illustration.color.withValues(alpha: 0.28),
                    blurRadius: 20,
                    offset: const Offset(0, 9),
                  ),
                ],
              ),
              child: Icon(illustration.icon, color: Colors.white, size: 62),
            ),
          ],
        ),
      ),
    );
  }

  Widget _decorationDot(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  ({IconData icon, Color color}) _illustrationFor(String key) {
    return switch (key) {
      'self' => (icon: Icons.person_rounded, color: _teal),
      'you' => (icon: Icons.waving_hand_rounded, color: _yellow),
      'male' => (icon: Icons.face_rounded, color: const Color(0xFF4C7CF3)),
      'female' => (icon: Icons.face_3_rounded, color: _coral),
      'friends' => (icon: Icons.groups_rounded, color: const Color(0xFF8A63D2)),
      'home' => (icon: Icons.home_rounded, color: _teal),
      'teacher' => (icon: Icons.school_rounded, color: const Color(0xFF4C7CF3)),
      'happy' => (icon: Icons.sentiment_very_satisfied_rounded, color: _yellow),
      _ => (icon: Icons.record_voice_over_rounded, color: _teal),
    };
  }

  Widget _buildAudioButtons() {
    return Row(
      children: <Widget>[
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _teal,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: _isSpeaking
                ? null
                : () {
                    _playAudio(slow: false);
                  },
            icon: _isSpeaking && !_isSlowAudio
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.volume_up_rounded),
            label: const Text(
              'Listen',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: _ink,
              minimumSize: const Size(0, 52),
              side: const BorderSide(color: _border, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: _isSpeaking
                ? null
                : () {
                    _playAudio(slow: true);
                  },
            icon: _isSpeaking && _isSlowAudio
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _ink,
                    ),
                  )
                : const Icon(Icons.slow_motion_video_rounded),
            label: const Text(
              'Slow',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExampleCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: _border),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0A08100E),
            blurRadius: 15,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.lightbulb_rounded, color: _yellow, size: 22),
              SizedBox(width: 8),
              Text(
                'Simple Usage',
                style: TextStyle(
                  color: _ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _currentItem.exampleEnglish,
            style: const TextStyle(
              color: _ink,
              fontSize: 18,
              height: 1.4,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _currentItem.exampleBangla,
            style: const TextStyle(color: _muted, fontSize: 15, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    final isLastItem = _currentIndex == _items.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 112,
              height: 54,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _ink,
                  side: const BorderSide(color: _border, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: _currentIndex == 0 || _isCompleting
                    ? null
                    : _previous,
                child: const Text(
                  'Previous',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 54,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _yellow,
                    foregroundColor: _ink,
                    disabledBackgroundColor: const Color(0xFFE2E7E5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: _isCompleting ? null : _continue,
                  child: _isCompleting
                      ? const SizedBox(
                          width: 21,
                          height: 21,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: _ink,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              isLastItem ? 'Complete Learn' : 'Continue',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Icon(
                              isLastItem
                                  ? Icons.check_rounded
                                  : Icons.arrow_forward_rounded,
                            ),
                          ],
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
