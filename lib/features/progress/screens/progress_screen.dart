import 'package:flutter/material.dart';
import '../../../core/widgets/magical_background.dart'; // যুক্ত করা হয়েছে

const _surface = Color(0xFF0A1412);
const _cardBg = Color(0xFF13221E);
const _teal = Color(0xFF00E0B8);
const _yellow = Color(0xFFFFC928);
const _coral = Color(0xFFFF4B4B);
const _border = Color(0xFF1E332D);
const _muted = Color(0xFF6B8A80);

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool _loading = true;
  final double _overallProgress = 0.35;
  final String _currentWorld = 'World 2';
  final String _currentLevel = 'Level 14';
  final int _completedLevels = 13;
  final int _totalPractices = 156;
  final int _earnedStars = 38;
  final int _streak = 12;

  final List<double> _weeklyActivity = [0.2, 0.5, 0.8, 1.0, 0.4, 0.0, 0.6];
  final List<String> _weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    _loadProgressData();
  }

  Future<void> _loadProgressData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(backgroundColor: _surface, body: Center(child: CircularProgressIndicator(color: _teal)));
    }

    return Scaffold(
      backgroundColor: _surface,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('My Progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24)),
        centerTitle: false,
      ),
      body: MagicalBackground( // যুক্ত করা হয়েছে
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverallProgressCard(),
                const SizedBox(height: 24),
                _buildStatsGrid(),
                const SizedBox(height: 32),
                const Text('Skill Breakdown', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                _buildSkillStats(),
                const SizedBox(height: 32),
                const Text('Weekly Activity', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                _buildWeeklyChart(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverallProgressCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardBg.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border, width: 1.5),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const CircularProgressIndicator(value: 1.0, strokeWidth: 10, color: _surface),
                CircularProgressIndicator(value: _overallProgress, strokeWidth: 10, color: _teal, strokeCap: StrokeCap.round),
                Center(child: Text('${(_overallProgress * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900))),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Course Progress', style: TextStyle(color: _teal, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                const SizedBox(height: 8),
                const Text('You are currently on', style: TextStyle(color: _muted, fontSize: 15)),
                const SizedBox(height: 4),
                Text('$_currentWorld, $_currentLevel', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
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
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard(title: 'Total Stars', value: '$_earnedStars', icon: Icons.star_rounded, color: _yellow),
        _buildStatCard(title: 'Day Streak', value: '$_streak', icon: Icons.local_fire_department_rounded, color: _coral),
        _buildStatCard(title: 'Completed', value: '$_completedLevels Lvl', icon: Icons.emoji_events_rounded, color: _teal),
        _buildStatCard(title: 'Practices', value: '$_totalPractices', icon: Icons.bolt_rounded, color: const Color(0xFFB57BFF)),
      ],
    );
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(color: _muted, fontSize: 13, fontWeight: FontWeight.w800))),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildSkillStats() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardBg.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          _buildSkillRow('Speaking', 0.85, _teal),
          const SizedBox(height: 20),
          _buildSkillRow('Listening', 0.65, _yellow),
          const SizedBox(height: 20),
          _buildSkillRow('Grammar', 0.45, _coral),
          const SizedBox(height: 20),
          _buildSkillRow('Level Tests', 0.90, const Color(0xFFB57BFF)),
        ],
      ),
    );
  }

  Widget _buildSkillRow(String skill, double progress, Color color) {
    return Row(
      children: [
        SizedBox(width: 85, child: Text(skill, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700))),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(value: progress, minHeight: 10, backgroundColor: _surface, color: color),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(width: 45, child: Text('${(progress * 100).toInt()}%', textAlign: TextAlign.end, style: const TextStyle(color: _muted, fontSize: 14, fontWeight: FontWeight.w800))),
      ],
    );
  }

  Widget _buildWeeklyChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardBg.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(_weekDays.length, (index) {
          final heightRatio = _weeklyActivity[index];
          final isToday = index == 3;
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
                    color: heightRatio == 0 ? Colors.transparent : (isToday ? _teal : _teal.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: isToday ? [BoxShadow(color: _teal.withValues(alpha: 0.4), blurRadius: 10)] : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _weekDays[index],
                style: TextStyle(color: isToday ? _teal : _muted, fontWeight: isToday ? FontWeight.w900 : FontWeight.w700, fontSize: 14),
              ),
            ],
          );
        }),
      ),
    );
  }
}