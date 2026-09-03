import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/widgets/magical_background.dart'; // যুক্ত করা হয়েছে
import '../../../data/models/level_model.dart';
import '../../../data/repositories/level_progress_repository.dart';
import '../../../data/repositories/levels_repository.dart';
import '../../level_detail/screens/level_detail_screen.dart';

import '../../daily_practice/screens/daily_practice_screen.dart';
import '../../progress/screens/progress_screen.dart';
import '../../settings/screens/settings_screen.dart';

// === Premium Magical Night Theme Colors ===
const _surface = Color(0xFF0A1412);
const _cardBg = Color(0xFF13221E);
const _teal = Color(0xFF00E0B8);
const _tealShadow = Color(0xFF00967B);
const _yellow = Color(0xFFFFC928);
const _yellowShadow = Color(0xFFDCA800);
const _coral = Color(0xFFFF4B4B);
const _lockedPathTop = Color(0xFF213631);
const _lockedPathBottom = Color(0xFF13211D);
const _lockedNodeTop = Color(0xFF283F39);
const _lockedNodeBottom = Color(0xFF182924);

enum _LevelStatus { completed, current, locked }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LevelsRepository _levelsRepository = const LevelsRepository();
  final LevelProgressRepository _progressRepository = LevelProgressRepository();

  List<LevelModel> _levels = const <LevelModel>[];
  Set<int> _completedLevelIds = const <int>{};
  int _selectedTab = 0;
  int _dailyTarget = 15;
  int _dailyMinutes = 10;
  int _xp = 2450;
  int _streak = 12;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHome();
  }

  Future<void> _loadHome() async {
    if (mounted) setState(() => _loading = true);
    try {
      final levels = await _levelsRepository.loadLevels();
      final completedLevelIds = await _progressRepository.loadCompletedLevelIds(
        levels.map((level) => level.id),
      );

      if (!mounted) return;
      setState(() {
        _levels = levels;
        _completedLevelIds = completedLevelIds;
        _dailyTarget = 15;
        _dailyMinutes = 10;
        _xp = 2450;
        _streak = 12;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Level data load failed.';
      });
    }
  }

  Future<void> _refreshLevelProgress() async {
    if (_levels.isEmpty) return;
    final completedLevelIds = await _progressRepository.loadCompletedLevelIds(
      _levels.map((level) => level.id),
    );
    if (!mounted) return;
    setState(() => _completedLevelIds = completedLevelIds);
  }

  int get _currentLevelIndex {
    return _levels.indexWhere((level) => !_completedLevelIds.contains(level.id));
  }

  LevelModel? get _currentLevel {
    if (_levels.isEmpty) return null;
    final currentIndex = _currentLevelIndex;
    return currentIndex == -1 ? _levels.last : _levels[currentIndex];
  }

  _LevelStatus _statusFor(int levelIndex) {
    if (levelIndex < 0 || levelIndex >= _levels.length) return _LevelStatus.locked;
    final level = _levels[levelIndex];
    if (_completedLevelIds.contains(level.id)) return _LevelStatus.completed;
    if (levelIndex == _currentLevelIndex) return _LevelStatus.current;
    return _LevelStatus.locked;
  }

  Future<void> _openLevel(LevelModel level) async {
    await openLevelDetails(context, level);
    if (!mounted) return;
    await _refreshLevelProgress();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      _buildHomeTab(),
      const DailyPracticeScreen(),
      const ProgressScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: _surface,
      body: IndexedStack(index: _selectedTab, children: tabs),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _selectedTab == 0 && !_loading && _error == null && _currentLevel != null
          ? FloatingActionButton.extended(
        onPressed: () => _openLevel(_currentLevel!),
        backgroundColor: _yellow,
        foregroundColor: const Color(0xFF332500),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _yellowShadow, width: 3),
        ),
        icon: const Icon(Icons.play_arrow_rounded, size: 28),
        label: const Text('Continue Learning', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: Color(0xFF1E332D), width: 1.5)),
      ),
      child: NavigationBar(
        selectedIndex: _selectedTab,
        height: 75,
        backgroundColor: _surface,
        indicatorColor: _teal.withValues(alpha: 0.2),
        surfaceTintColor: Colors.transparent,
        onDestinationSelected: (index) => setState(() => _selectedTab = index),
        destinations: [
          _buildNavDest(Icons.route_outlined, Icons.route_rounded, 'Home'),
          _buildNavDest(Icons.bolt_outlined, Icons.bolt_rounded, 'Practice'),
          _buildNavDest(Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Progress'),
          _buildNavDest(Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
        ],
      ),
    );
  }

  NavigationDestination _buildNavDest(IconData icon, IconData activeIcon, String label) {
    return NavigationDestination(
      icon: Icon(icon, color: Colors.white54),
      selectedIcon: Icon(activeIcon, color: _teal),
      label: label,
    );
  }

  Widget _buildHomeTab() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _teal));
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: Colors.white)));

    final groupedLevels = SplayTreeMap<int, List<LevelModel>>();
    for (final level in _levels) {
      groupedLevels.putIfAbsent(level.worldId, () => <LevelModel>[]).add(level);
    }

    return MagicalBackground(
      child: RefreshIndicator(
        color: _teal,
        backgroundColor: _cardBg,
        onRefresh: _loadHome,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _HomeHeader(streak: _streak, xp: _xp)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: _DailyProgressCard(completed: _dailyMinutes, target: _dailyTarget),
              ),
            ),
            for (final entry in groupedLevels.entries)
              SliverToBoxAdapter(
                child: _WorldSection(
                  worldId: entry.key,
                  levels: entry.value,
                  allLevels: _levels,
                  statusFor: _statusFor,
                  onLevelTap: (i) {
                    if (_statusFor(i) == _LevelStatus.locked) return;
                    _openLevel(_levels[i]);
                  },
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.streak, required this.xp});
  final int streak;
  final int xp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 20, 24, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ENGLISH BOLI',
                  style: TextStyle(color: _teal, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.8),
                ),
                SizedBox(height: 6),
                Text(
                  'আপনার আজকের\nEnglish',
                  style: TextStyle(color: Colors.white, fontSize: 24, height: 1.2, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          _buildPill(Icons.local_fire_department_rounded, _coral, '$streak'),
          const SizedBox(width: 8),
          _buildPill(Icons.star_rounded, _yellow, '$xp'),
        ],
      ),
    );
  }

  Widget _buildPill(IconData icon, Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E332D), width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x2A000000), blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
        ],
      ),
    );
  }
}

class _DailyProgressCard extends StatelessWidget {
  const _DailyProgressCard({required this.completed, required this.target});
  final int completed;
  final int target;

  @override
  Widget build(BuildContext context) {
    final progress = target <= 0 ? 0.0 : (completed / target).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF233B34), width: 2),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 15, offset: Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _teal.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.calendar_month_rounded, color: _teal, size: 22),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text("Today's speaking goal", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
              ),
              Text('$completed/$target min', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w800, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: const Color(0xFF182B26),
              color: _teal,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorldSection extends StatelessWidget {
  const _WorldSection({
    required this.worldId,
    required this.levels,
    required this.allLevels,
    required this.statusFor,
    required this.onLevelTap,
  });

  final int worldId;
  final List<LevelModel> levels;
  final List<LevelModel> allLevels;
  final _LevelStatus Function(int) statusFor;
  final ValueChanged<int> onLevelTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF1E332D), width: 1.5),
                boxShadow: const [BoxShadow(color: Color(0x3A000000), blurRadius: 15, offset: Offset(0, 8))]
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _yellow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _yellowShadow, width: 3),
                    boxShadow: [BoxShadow(color: _yellow.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: const Icon(Icons.record_voice_over_rounded, color: Color(0xFF332500), size: 34),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('WORLD 1', style: TextStyle(color: _teal, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      SizedBox(height: 2),
                      Text('First Words', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                const Text('0/10', style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          const SizedBox(height: 32),

          LayoutBuilder(
            builder: (context, constraints) {
              final pathPoints = List<Offset>.generate(levels.length, (i) {
                const offsets = [0.25, 0.50, 0.70, 0.50, 0.30];
                return Offset(constraints.maxWidth * offsets[i % offsets.length], 50 + (i * 140.0));
              });

              return SizedBox(
                height: levels.length * 140.0,
                child: Stack(
                  children: [
                    Positioned.fill(child: CustomPaint(painter: _PathLinePainter(pathPoints))),
                    for (var i = 0; i < levels.length; i++)
                      Positioned(
                        left: pathPoints[i].dx - 45,
                        top: pathPoints[i].dy - 45,
                        child: _LevelNode(
                          levelNumber: levels[i].order,
                          status: statusFor(allLevels.indexOf(levels[i])),
                          onTap: () => onLevelTap(allLevels.indexOf(levels[i])),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PathLinePainter extends CustomPainter {
  const _PathLinePainter(this.points);
  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final midY = (prev.dy + curr.dy) / 2;
      path.cubicTo(prev.dx, midY, curr.dx, midY, curr.dx, curr.dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = _lockedPathBottom
        ..style = PaintingStyle.stroke
        ..strokeWidth = 28
        ..strokeCap = StrokeCap.round,
    );

    final topPath = path.shift(const Offset(0, -4));
    canvas.drawPath(
      topPath,
      Paint()
        ..color = _lockedPathTop
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_PathLinePainter old) => old.points != points;
}

class _LevelNode extends StatelessWidget {
  const _LevelNode({required this.levelNumber, required this.status, required this.onTap});
  final int levelNumber;
  final _LevelStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isCurrent = status == _LevelStatus.current;
    final isCompleted = status == _LevelStatus.completed;

    Color topColor;
    Color bottomColor;
    Color borderColor;
    IconData icon;
    Color iconColor;

    if (isCompleted) {
      topColor = _teal;
      bottomColor = _tealShadow;
      borderColor = Colors.white;
      icon = Icons.check_rounded;
      iconColor = Colors.white;
    } else if (isCurrent) {
      topColor = _yellow;
      bottomColor = _yellowShadow;
      borderColor = Colors.white;
      icon = Icons.star_rounded;
      iconColor = const Color(0xFF332500);
    } else {
      topColor = _lockedNodeTop;
      bottomColor = _lockedNodeBottom;
      borderColor = const Color(0xFF3B564E);
      icon = Icons.lock_rounded;
      iconColor = const Color(0xFF6B8A80);
    }

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 90,
        child: Column(
          children: [
            SizedBox(
              height: 85,
              width: 80,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    height: 76,
                    decoration: BoxDecoration(color: bottomColor, shape: BoxShape.circle),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 100),
                    bottom: 8,
                    child: Container(
                      height: 74,
                      width: 74,
                      decoration: BoxDecoration(
                        color: topColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor, width: 3.5),
                        boxShadow: isCurrent ? [BoxShadow(color: _yellow.withValues(alpha: 0.4), blurRadius: 15, spreadRadius: 2)] : null,
                      ),
                      child: Icon(icon, color: iconColor, size: 36),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isCurrent ? _yellow.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Level $levelNumber',
                style: TextStyle(
                  color: isCurrent ? _yellow : (isCompleted ? Colors.white : const Color(0xFF6B8A80)),
                  fontSize: 14,
                  fontWeight: isCurrent || isCompleted ? FontWeight.w900 : FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}