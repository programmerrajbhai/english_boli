import 'package:flutter/material.dart';
import '../../../core/widgets/magical_background.dart'; // যুক্ত করা হয়েছে

const _surface = Color(0xFF0A1412);
const _cardBg = Color(0xFF13221E);
const _teal = Color(0xFF00E0B8);
const _yellow = Color(0xFFFFC928);
const _coral = Color(0xFFFF4B4B);
const _border = Color(0xFF1E332D);

class DailyPracticeScreen extends StatefulWidget {
  const DailyPracticeScreen({super.key});

  @override
  State<DailyPracticeScreen> createState() => _DailyPracticeScreenState();
}

class _DailyPracticeScreenState extends State<DailyPracticeScreen> {
  bool _loading = true;
  final int _streak = 12;
  final int _dailyTarget = 15;
  final int _completedMinutes = 10;
  final int _recentMistakes = 8;
  final int _dueRevision = 14;
  int _selectedDuration = 10;

  @override
  void initState() {
    super.initState();
    _loadDailyData();
  }

  Future<void> _loadDailyData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _loading = false);
  }

  void _startDailyPractice() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Starting $_selectedDuration minutes practice...'), backgroundColor: _teal),
    );
  }

  void _openMistakeReview() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening Mistake Review...'), backgroundColor: _coral),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _surface,
        body: Center(child: CircularProgressIndicator(color: _teal)),
      );
    }

    return Scaffold(
      backgroundColor: _surface,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Daily Practice', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24)),
        centerTitle: false,
        actions: [
          _buildStreakBadge(),
          const SizedBox(width: 20),
        ],
      ),
      body: MagicalBackground( // যুক্ত করা হয়েছে
        child: SafeArea(
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
                      const SizedBox(height: 32),
                      const Text('Choose Practice Time', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 16),
                      _buildTimeSelection(),
                      const SizedBox(height: 32),
                      const Text('Targeted Practice', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 16),
                      _buildTargetedPracticeCards(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
              _buildBottomStartButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _coral.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: _coral.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded, color: _coral, size: 20),
          const SizedBox(width: 6),
          Text('$_streak', style: const TextStyle(color: _coral, fontWeight: FontWeight.w900, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildDailyGoalCard() {
    final double progress = (_completedMinutes / _dailyTarget).clamp(0.0, 1.0);
    final bool isCompleted = _completedMinutes >= _dailyTarget;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardBg.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border, width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x3A000000), blurRadius: 15, offset: Offset(0, 8))],
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
                  isCompleted ? 'You are doing amazing! Keep practicing to earn more XP.' : '$_completedMinutes out of $_dailyTarget minutes completed.',
                  style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: _surface,
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
              color: isCompleted ? _teal.withValues(alpha: 0.2) : _yellow.withValues(alpha: 0.2),
              border: Border.all(color: isCompleted ? _teal : _yellow, width: 2),
            ),
            child: Icon(isCompleted ? Icons.check_rounded : Icons.timer_rounded, color: isCompleted ? _teal : _yellow, size: 36),
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
            padding: EdgeInsets.only(right: minutes != 15 ? 12 : 0),
            child: InkWell(
              onTap: () => setState(() => _selectedDuration = minutes),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: isSelected ? _teal.withValues(alpha: 0.15) : _cardBg.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? _teal : _border, width: 2),
                  boxShadow: isSelected ? [BoxShadow(color: _teal.withValues(alpha: 0.2), blurRadius: 10)] : [],
                ),
                child: Column(
                  children: [
                    Text('$minutes', style: TextStyle(color: isSelected ? _teal : Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                    Text('min', style: TextStyle(color: isSelected ? _teal : const Color(0xFF6B8A80), fontSize: 15, fontWeight: FontWeight.w700)),
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
        Expanded(child: _buildActionCard(title: 'Mistakes', count: _recentMistakes, icon: Icons.manage_search_rounded, color: _coral, onTap: _openMistakeReview)),
        const SizedBox(width: 16),
        Expanded(child: _buildActionCard(title: 'Revision', count: _dueRevision, icon: Icons.auto_awesome_rounded, color: const Color(0xFFB57BFF), onTap: () {})),
      ],
    );
  }

  Widget _buildActionCard({required String title, required int count, required IconData icon, required Color color, required VoidCallback onTap}) {
    final bool hasItems = count > 0;
    return InkWell(
      onTap: hasItems ? onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: Opacity(
        opacity: hasItems ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _cardBg.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 20),
              Text(hasItems ? '$count Items' : 'All Clear', style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
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
        color: _surface,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.stars_rounded, color: _yellow, size: 22),
                const SizedBox(width: 8),
                const Text('Earn +50 XP for daily completion', style: TextStyle(color: Color(0xFF6B8A80), fontWeight: FontWeight.w800, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _teal,
                  foregroundColor: const Color(0xFF072A22),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: _startDailyPractice,
                child: Text('Start $_selectedDuration min Practice', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}