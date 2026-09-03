import 'package:flutter/material.dart';

import '../../../data/models/level_model.dart';
import '../../../data/repositories/level_progress_repository.dart';

typedef LevelStartCallback = Future<void> Function(LevelModel level);

Future<void> openLevelDetails(
  BuildContext context,
  LevelModel level, {
  LevelStartCallback? onStart,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      settings: RouteSettings(name: '/level/${level.id}'),
      builder: (_) {
        return LevelDetailsScreen(level: level, onStart: onStart);
      },
    ),
  );
}

class LevelDetailsScreen extends StatefulWidget {
  const LevelDetailsScreen({
    super.key,
    required this.level,
    this.onStart,
    this.progressRepository,
  });

  final LevelModel level;
  final LevelStartCallback? onStart;
  final LevelProgressRepository? progressRepository;

  @override
  State<LevelDetailsScreen> createState() {
    return _LevelDetailsScreenState();
  }
}

class _LevelDetailsScreenState extends State<LevelDetailsScreen> {
  static const _ink = Color(0xFF08100E);
  static const _teal = Color(0xFF00BFAE);
  static const _yellow = Color(0xFFFFC928);
  static const _coral = Color(0xFFFF6B57);
  static const _background = Color(0xFFF4F8F7);
  static const _muted = Color(0xFF64706D);
  static const _border = Color(0xFFDDE6E3);

  static const _stages = <({String title, String subtitle, IconData icon})>[
    (
      title: 'Learn',
      subtitle: 'শব্দ ও নিয়ম বুঝুন',
      icon: Icons.menu_book_rounded,
    ),
    (
      title: 'Smart Practice',
      subtitle: 'MCQ, matching ও sentence',
      icon: Icons.extension_rounded,
    ),
    (
      title: 'Listening',
      subtitle: 'শুনে সঠিক উত্তর দিন',
      icon: Icons.headphones_rounded,
    ),
    (title: 'Speaking', subtitle: 'নিজের কণ্ঠে বলুন', icon: Icons.mic_rounded),
    (
      title: 'Conversation',
      subtitle: 'বাস্তব কথোপকথন করুন',
      icon: Icons.forum_rounded,
    ),
    (
      title: 'Level Test',
      subtitle: 'Pass score অর্জন করুন',
      icon: Icons.workspace_premium_rounded,
    ),
  ];

  late final LevelProgressRepository _repository;
  late Future<LevelProgress> _progressFuture;

  bool _isStarting = false;

  @override
  void initState() {
    super.initState();

    _repository = widget.progressRepository ?? LevelProgressRepository();

    _loadProgress();
  }

  void _loadProgress() {
    _progressFuture = _repository.loadLevel(widget.level.id);
  }

  Future<void> _startLevel() async {
    if (_isStarting) {
      return;
    }

    setState(() {
      _isStarting = true;
    });

    try {
      await _repository.markLevelStarted(widget.level.id);

      if (!mounted) {
        return;
      }

      final onStart = widget.onStart;

      if (onStart != null) {
        await onStart(widget.level);
      } else {
        setState(_loadProgress);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Level শুরু হয়েছে। Learn Screen পরবর্তী ধাপে যুক্ত হবে।',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isStarting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _ink,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Level ${widget.level.order}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: FutureBuilder<LevelProgress>(
        future: _progressFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: _teal));
          }

          if (snapshot.hasError) {
            return _buildError();
          }

          return _buildContent(snapshot.data ?? const LevelProgress.empty());
        },
      ),
      bottomNavigationBar: FutureBuilder<LevelProgress>(
        future: _progressFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }

          final progress = snapshot.data!;

          final buttonText = progress.isCompleted
              ? 'Review Level'
              : progress.hasStarted
              ? 'Continue Learning'
              : 'Start Level';

          return _buildBottomButton(buttonText);
        },
      ),
    );
  }

  Widget _buildContent(LevelProgress progress) {
    final level = widget.level;

    final completedPractices = progress.completedPractices
        .clamp(0, level.totalPractices)
        .toInt();

    final progressValue = progress.fractionOf(level.totalPractices);

    final currentStage = progress.currentStage
        .clamp(0, _stages.length - 1)
        .toInt();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 28),
      children: <Widget>[
        _buildHero(level),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildProgressCard(
                progressValue: progressValue,
                completedPractices: completedPractices,
                totalPractices: level.totalPractices,
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  _buildMetric(
                    icon: Icons.bolt_rounded,
                    color: _coral,
                    value: '${level.totalPractices}',
                    label: 'Practice',
                  ),
                  const SizedBox(width: 9),
                  _buildMetric(
                    icon: Icons.schedule_rounded,
                    color: _teal,
                    value: '${level.estimatedMinutes}m',
                    label: 'সময়',
                  ),
                  const SizedBox(width: 9),
                  _buildMetric(
                    icon: Icons.signal_cellular_alt_rounded,
                    color: _yellow,
                    value: level.difficultyBn,
                    label: 'Difficulty',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildHeading(
                title: 'এই Level-এ কী শিখবেন',
                subtitle: 'Level শেষ করলে নিচের কাজগুলো করতে পারবেন',
              ),
              const SizedBox(height: 11),
              _buildCard(
                Column(
                  children: <Widget>[
                    for (
                      var index = 0;
                      index < level.resolvedLearningGoals.length;
                      index++
                    )
                      Padding(
                        padding: EdgeInsets.only(top: index == 0 ? 0 : 14),
                        child: _buildGoal(level.resolvedLearningGoals[index]),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildHeading(
                title: 'Learning Journey',
                subtitle: 'একই flow সব ৫০টি level-এ কাজ করবে',
              ),
              const SizedBox(height: 11),
              _buildCard(
                Column(
                  children: <Widget>[
                    for (var index = 0; index < _stages.length; index++)
                      _buildStage(
                        stage: _stages[index],
                        isCompleted:
                            progress.isCompleted || index < currentStage,
                        isCurrent:
                            !progress.isCompleted && index == currentStage,
                        showDivider: index != _stages.length - 1,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildHeading(
                title: 'Available Rewards',
                subtitle: 'Level test pass করলে rewards পাবেন',
              ),
              const SizedBox(height: 11),
              _buildCard(
                Row(
                  children: <Widget>[
                    _buildReward(
                      icon: Icons.bolt_rounded,
                      color: _coral,
                      value: '+${level.rewardXp}',
                      label: 'XP',
                    ),
                    _buildReward(
                      icon: Icons.star_rounded,
                      color: _yellow,
                      value: '${level.rewardStars}',
                      label: 'Stars',
                    ),
                    _buildReward(
                      icon: Icons.verified_rounded,
                      color: _teal,
                      value: '${level.passPercentage}%',
                      label: 'Pass',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHero(LevelModel level) {
    return Container(
      color: _ink,
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'WORLD ${level.worldId}  •  LEVEL ${level.order}',
                  style: const TextStyle(
                    color: Color(0xFF66E2D6),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 11),
                Text(
                  level.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 29,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  level.subtitleBn,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFB8C3C0),
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Semantics(
            label: 'English speaking illustration',
            image: true,
            child: Container(
              width: 92,
              height: 92,
              decoration: const BoxDecoration(
                color: _teal,
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  const Icon(
                    Icons.record_voice_over_rounded,
                    color: Colors.white,
                    size: 46,
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 31,
                      height: 31,
                      decoration: const BoxDecoration(
                        color: _yellow,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.graphic_eq_rounded,
                        color: _ink,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard({
    required double progressValue,
    required int completedPractices,
    required int totalPractices,
  }) {
    return _buildCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'আপনার Progress',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                '${(progressValue * 100).round()}%',
                style: const TextStyle(
                  color: _teal,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              minHeight: 11,
              value: progressValue,
              color: _teal,
              backgroundColor: const Color(0xFFE3EAE8),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            '$completedPractices / $totalPractices practice completed',
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: _border),
        ),
        child: Column(
          children: <Widget>[
            Icon(icon, color: color, size: 21),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            Text(label, style: const TextStyle(color: _muted, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeading({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(color: _muted, fontSize: 12, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildGoal(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 25,
          height: 25,
          decoration: const BoxDecoration(
            color: Color(0xFFD9F7F3),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: _teal, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(height: 1.45, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildStage({
    required ({String title, String subtitle, IconData icon}) stage,
    required bool isCompleted,
    required bool isCurrent,
    required bool showDivider,
  }) {
    final iconColor = isCompleted || isCurrent
        ? _teal
        : const Color(0xFFADB9B6);

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? _teal
                      : isCurrent
                      ? const Color(0xFFD9F7F3)
                      : const Color(0xFFEDF1F0),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted ? Icons.check_rounded : stage.icon,
                  color: isCompleted ? Colors.white : iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      stage.title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      stage.subtitle,
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (isCurrent)
                const Text(
                  'CURRENT',
                  style: TextStyle(
                    color: _teal,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, color: _border),
      ],
    );
  }

  Widget _buildReward({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Icon(icon, color: color, size: 27),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          Text(label, style: const TextStyle(color: _muted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildCard(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0A08100E),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildBottomButton(String label) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 55,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _yellow,
              foregroundColor: _ink,
              disabledBackgroundColor: const Color(0xFFE2E7E5),
              disabledForegroundColor: _muted,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: _isStarting ? null : _startLevel,
            icon: _isStarting
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: _ink,
                    ),
                  )
                : const Icon(Icons.play_arrow_rounded),
            label: Text(
              _isStarting ? 'Opening...' : label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline_rounded, color: _coral, size: 46),
            const SizedBox(height: 10),
            const Text('Progress load করা যায়নি', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(_loadProgress);
              },
              child: const Text('আবার চেষ্টা করুন'),
            ),
          ],
        ),
      ),
    );
  }
}
