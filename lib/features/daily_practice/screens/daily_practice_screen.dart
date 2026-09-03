import 'package:flutter/material.dart';

class DailyPracticeScreen extends StatefulWidget {
  const DailyPracticeScreen({super.key});

  @override
  State<DailyPracticeScreen> createState() => _DailyPracticeScreenState();
}

class _DailyPracticeScreenState extends State<DailyPracticeScreen> {
  // Design System Colors
  static const _ink = Color(0xFF08100E);
  static const _teal = Color(0xFF00BFAE);
  static const _yellow = Color(0xFFFFC928);
  static const _coral = Color(0xFFFF6B57);
  static const _background = Color(0xFFF5F9F8);
  static const _muted = Color(0xFF66736F);
  static const _border = Color(0xFFDCE5E2);

  // Mock Data (Replace with real data from repository/providers)
  bool _loading = true;
  final int _streak = 12;
  final int _dailyTarget = 15;
  final int _completedMinutes = 10;
  final int _recentMistakes = 8;
  final int _dueRevision = 14;

  int _selectedDuration = 10; // Default selection

  @override
  void initState() {
    super.initState();
    _loadDailyData();
  }

  Future<void> _loadDailyData() async {
    // Simulate loading
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _startDailyPractice() {
    // Navigate to a combined practice session based on _selectedDuration
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Starting $_selectedDuration minutes practice...')),
    );
  }

  void _openMistakeReview() {
    // Navigate to Mistake Review Screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening Mistake Review...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _background,
        body: Center(child: CircularProgressIndicator(color: _teal)),
      );
    }

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Daily Practice',
          style: TextStyle(color: _ink, fontWeight: FontWeight.w900, fontSize: 20),
        ),
        centerTitle: false,
        actions: [
          _buildStreakBadge(),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDailyGoalCard(),
                    const SizedBox(height: 24),
                    const Text(
                      'Choose Practice Time',
                      style: TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 12),
                    _buildTimeSelection(),
                    const SizedBox(height: 32),
                    const Text(
                      'Targeted Practice',
                      style: TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 12),
                    _buildTargetedPracticeCards(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _buildBottomStartButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _coral.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: _coral.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded, color: _coral, size: 20),
          const SizedBox(width: 4),
          Text(
            '$_streak',
            style: const TextStyle(color: _coral, fontWeight: FontWeight.w900, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyGoalCard() {
    final double progress = (_completedMinutes / _dailyTarget).clamp(0.0, 1.0);
    final bool isCompleted = _completedMinutes >= _dailyTarget;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _ink,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A08100E),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCompleted ? 'Goal Reached! 🎉' : 'Daily Goal',
                  style: const TextStyle(color: _yellow, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
                const SizedBox(height: 8),
                Text(
                  isCompleted
                      ? 'You are doing amazing! Keep practicing to earn more XP.'
                      : '$_completedMinutes out of $_dailyTarget minutes completed.',
                  style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    color: _teal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted ? _teal : _yellow,
            ),
            child: Icon(
              isCompleted ? Icons.check_rounded : Icons.timer_rounded,
              color: _ink,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelection() {
    return Row(
      children: [5, 10, 15].map((minutes) {
        final isSelected = _selectedDuration == minutes;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: minutes != 15 ? 10 : 0),
            child: InkWell(
              onTap: () => setState(() => _selectedDuration = minutes),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected ? _teal : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? _teal : _border,
                    width: 2,
                  ),
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                      color: _teal.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                      : [],
                ),
                child: Column(
                  children: [
                    Text(
                      '$minutes',
                      style: TextStyle(
                        color: isSelected ? Colors.white : _ink,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'min',
                      style: TextStyle(
                        color: isSelected ? Colors.white.withValues(alpha: 0.8) : _muted,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTargetedPracticeCards() {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            title: 'Mistakes',
            count: _recentMistakes,
            icon: Icons.manage_search_rounded,
            color: _coral,
            onTap: _openMistakeReview,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            title: 'Revision',
            count: _dueRevision,
            icon: Icons.auto_awesome_rounded,
            color: const Color(0xFF8A63D2), // Purple for revision
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Starting Revision...')),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final bool hasItems = count > 0;

    return InkWell(
      onTap: hasItems ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: hasItems ? 1.0 : 0.5, // Fixed opacity usage
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                hasItems ? '$count Items' : 'All Clear',
                style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomStartButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                Icon(Icons.stars_rounded, color: _yellow, size: 20),
                SizedBox(width: 8),
                Text(
                  'Earn +50 XP for daily completion',
                  style: TextStyle(color: _muted, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _startDailyPractice,
                child: Text(
                  'Start $_selectedDuration min Practice',
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