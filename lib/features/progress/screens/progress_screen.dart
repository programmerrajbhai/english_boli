
import 'package:flutter/material.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  // Design System Colors
  static const _ink = Color(0xFF08100E);
  static const _teal = Color(0xFF00BFAE);
  static const _yellow = Color(0xFFFFC928);
  static const _coral = Color(0xFFFF6B57);
  static const _background = Color(0xFFF5F9F8);
  static const _muted = Color(0xFF66736F);
  static const _border = Color(0xFFDCE5E2);

  // Mock Data (Replace with real data from providers/repositories)
  bool _loading = true;
  final double _overallProgress = 0.35; // 35%
  final String _currentWorld = 'World 2';
  final String _currentLevel = 'Level 14';

  final int _completedLevels = 13;
  final int _totalPractices = 156;
  final int _earnedStars = 38;
  final int _streak = 12;

  // Weekly activity data (0.0 to 1.0) for Mon-Sun
  final List<double> _weeklyActivity = [0.2, 0.5, 0.8, 1.0, 0.4, 0.0, 0.6];
  final List<String> _weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    _loadProgressData();
  }

  Future<void> _loadProgressData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _loading = false);
    }
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
          'My Progress',
          style: TextStyle(color: _ink, fontWeight: FontWeight.w900, fontSize: 20),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100), // Bottom padding for Nav Bar
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverallProgressCard(),
            const SizedBox(height: 24),
            _buildStatsGrid(),
            const SizedBox(height: 24),

            const Text(
              'Skill Breakdown',
              style: TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            _buildSkillStats(),

            const SizedBox(height: 24),

            const Text(
              'Weekly Activity',
              style: TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            _buildWeeklyChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallProgressCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _ink,
        borderRadius: BorderRadius.circular(24),
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
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: _overallProgress,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  color: _yellow,
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Text(
                    '${(_overallProgress * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Course Progress',
                  style: TextStyle(color: _yellow, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1),
                ),
                const SizedBox(height: 6),
                const Text(
                  'You are currently on',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  '$_currentWorld, $_currentLevel',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(
          title: 'Total Stars',
          value: '$_earnedStars',
          icon: Icons.star_rounded,
          color: _yellow,
        ),
        _buildStatCard(
          title: 'Day Streak',
          value: '$_streak',
          icon: Icons.local_fire_department_rounded,
          color: _coral,
        ),
        _buildStatCard(
          title: 'Completed',
          value: '$_completedLevels Lvl',
          icon: Icons.emoji_events_rounded,
          color: _teal,
        ),
        _buildStatCard(
          title: 'Practices',
          value: '$_totalPractices',
          icon: Icons.bolt_rounded,
          color: const Color(0xFF8A63D2),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(color: _ink, fontSize: 20, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          _buildSkillRow('Speaking', 0.85, _teal),
          const SizedBox(height: 16),
          _buildSkillRow('Listening', 0.65, _yellow),
          const SizedBox(height: 16),
          _buildSkillRow('Grammar', 0.45, _coral),
          const SizedBox(height: 16),
          _buildSkillRow('Level Tests', 0.90, const Color(0xFF8A63D2)),
        ],
      ),
    );
  }

  Widget _buildSkillRow(String skill, double progress, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            skill,
            style: const TextStyle(color: _ink, fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFF0F4F3),
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 40,
          child: Text(
            '${(progress * 100).toInt()}%',
            textAlign: TextAlign.end,
            style: const TextStyle(color: _muted, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(_weekDays.length, (index) {
          final heightRatio = _weeklyActivity[index];
          final isToday = index == 3; // Mocking 'Today' as Thursday

          return Column(
            children: [
              Container(
                width: 24,
                height: 120,
                alignment: Alignment.bottomCenter,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: 24,
                  height: 120 * heightRatio,
                  decoration: BoxDecoration(
                    color: heightRatio == 0
                        ? Colors.transparent
                        : (isToday ? _teal : _teal.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _weekDays[index],
                style: TextStyle(
                  color: isToday ? _ink : _muted,
                  fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}