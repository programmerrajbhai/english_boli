
import 'package:flutter/material.dart';
import '../../../data/models/level_model.dart';
import '../../../core/routes/app_routes.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.level,
    required this.score,
    required this.totalQuestions,
    required this.passed,
  });

  final LevelModel level;
  final int score;
  final int totalQuestions;
  final bool passed;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  // Design System Colors
  static const _ink = Color(0xFF08100E);
  static const _teal = Color(0xFF00BFAE);
  static const _yellow = Color(0xFFFFC928);
  static const _coral = Color(0xFFFF6B57);
  static const _background = Color(0xFFF5F9F8);
  static const _muted = Color(0xFF66736F);
  static const _border = Color(0xFFDCE5E2);

  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;

  late final int _earnedStars;
  late final int _earnedXp;
  late final double _percentage;

  @override
  void initState() {
    super.initState();
    _percentage = (widget.score / widget.totalQuestions) * 100;

    // Calculate Stars
    if (!widget.passed) {
      _earnedStars = 0;
    } else if (_percentage >= 95) {
      _earnedStars = 3;
    } else if (_percentage >= 85) {
      _earnedStars = 2;
    } else {
      _earnedStars = 1;
    }

    // Calculate XP (Full XP if passed, 20% if failed for effort)
    _earnedXp = widget.passed
        ? widget.level.rewardXp
        : (widget.level.rewardXp * 0.2).toInt();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _reviewMistakes() {
    // Navigate to mistake review screen (Screen 13)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening Mistake Review...')),
    );
  }

  void _continueAction() {
    if (widget.passed) {
      // Go back to Home
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
    } else {
      // Retry Test (Pop back to Level Details to restart)
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.passed ? 'Level Completed!' : 'Keep Trying!';
    final subtitle = widget.passed
        ? 'Great job! You have unlocked the next challenges.'
        : 'Don\'t give up. Review your mistakes and try again.';

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(color: _ink, fontSize: 28, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _muted, fontSize: 15, height: 1.4),
                ),
              ),
              const Spacer(),

              // Stars & Score Header
              ScaleTransition(
                scale: _scaleAnimation,
                child: _buildStarsIndicator(),
              ),
              const SizedBox(height: 32),

              // Stats Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildStatsCard(),
              ),
              const Spacer(flex: 2),

              _buildBottomButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStarsIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (index) {
        final isEarned = index < _earnedStars;
        final isCenter = index == 1;

        return Padding(
          padding: EdgeInsets.only(
            bottom: isCenter ? 20 : 0,
            left: 8,
            right: 8,
          ),
          child: Icon(
            Icons.star_rounded,
            size: isCenter ? 80 : 60,
            color: isEarned ? _yellow : _border,
            shadows: isEarned ? [
              BoxShadow(
                color: _yellow.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 4),
              )
            ] : null,
          ),
        );
      }),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A08100E),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                title: 'Score',
                value: '${_percentage.round()}%',
                icon: Icons.percent_rounded,
                color: widget.passed ? _teal : _coral,
              ),
              Container(width: 1, height: 40, color: _border),
              _buildStatItem(
                title: 'Earned XP',
                value: '+$_earnedXp',
                icon: Icons.bolt_rounded,
                color: _coral,
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: _border, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSmallStatItem(
                title: 'Correct',
                value: '${widget.score}',
                color: const Color(0xFF20A66A),
              ),
              _buildSmallStatItem(
                title: 'Wrong',
                value: '${widget.totalQuestions - widget.score}',
                color: _coral,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({required String title, required String value, required IconData icon, required Color color}) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(color: _muted, fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildSmallStatItem({required String title, required String value, required Color color}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(color: _muted, fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    final wrongAnswers = widget.totalQuestions - widget.score;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (wrongAnswers > 0) ...[
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: _ink,
                side: const BorderSide(color: _border, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _reviewMistakes,
              icon: const Icon(Icons.manage_search_rounded),
              label: const Text('Review Mistakes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 12),
          ],
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: widget.passed ? _teal : _yellow,
              foregroundColor: widget.passed ? Colors.white : _ink,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _continueAction,
            child: Text(
              widget.passed ? 'Continue to Next Level' : 'Retry Test',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}