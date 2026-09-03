import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/level_model.dart';
import '../../../data/repositories/level_progress_repository.dart';
import '../../../data/repositories/levels_repository.dart';
import '../../level_detail/screens/level_detail_screen.dart';

const _ink = Color(0xFF08100E);
const _surface = Color(0xFFF5F9F8);
const _white = Color(0xFFFFFFFF);
const _muted = Color(0xFF66736F);
const _teal = Color(0xFF00BFAE);
const _yellow = Color(0xFFFFC928);
const _coral = Color(0xFFFF6B57);
const _locked = Color(0xFFD8E0DE);

enum _LevelStatus {
  completed,
  current,
  locked,
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() {
    return _HomeScreenState();
  }
}

class _HomeScreenState extends State<HomeScreen> {
  final LevelsRepository _levelsRepository =
  const LevelsRepository();

  final LevelProgressRepository
  _progressRepository =
  LevelProgressRepository();

  List<LevelModel> _levels =
  const <LevelModel>[];

  Set<int> _completedLevelIds =
  const <int>{};

  int _selectedTab = 0;
  int _dailyTarget = 15;
  int _dailyMinutes = 0;
  int _xp = 0;
  int _streak = 0;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHome();
  }

  Future<void> _loadHome() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final levels =
      await _levelsRepository.loadLevels();

      final completedLevelIds =
      await _progressRepository
          .loadCompletedLevelIds(
        levels.map((level) => level.id),
      );

      final preferences =
      SharedPreferencesAsync();

      final dailyTarget =
          await preferences.getInt(
            'daily_target_minutes',
          ) ??
              15;

      final dailyMinutes =
          await preferences.getInt(
            'daily_completed_minutes',
          ) ??
              0;

      final xp =
          await preferences.getInt(
            'total_xp',
          ) ??
              0;

      final streak =
          await preferences.getInt(
            'current_streak',
          ) ??
              0;

      if (!mounted) {
        return;
      }

      setState(() {
        _levels = levels;
        _completedLevelIds =
            completedLevelIds;
        _dailyTarget = dailyTarget;
        _dailyMinutes = dailyMinutes;
        _xp = xp;
        _streak = streak;
        _loading = false;
      });
    } catch (error) {
      debugPrint(
        'Home load error: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error =
        'Level data load করা যায়নি।';
      });
    }
  }

  Future<void> _refreshLevelProgress() async {
    if (_levels.isEmpty) {
      return;
    }

    final completedLevelIds =
    await _progressRepository
        .loadCompletedLevelIds(
      _levels.map((level) => level.id),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _completedLevelIds =
          completedLevelIds;
    });
  }

  int get _currentLevelIndex {
    return _levels.indexWhere(
          (level) =>
      !_completedLevelIds.contains(
        level.id,
      ),
    );
  }

  LevelModel? get _currentLevel {
    if (_levels.isEmpty) {
      return null;
    }

    final currentIndex =
        _currentLevelIndex;

    if (currentIndex == -1) {
      return _levels.last;
    }

    return _levels[currentIndex];
  }

  _LevelStatus _statusFor(
      int levelIndex,
      ) {
    if (levelIndex < 0 ||
        levelIndex >= _levels.length) {
      return _LevelStatus.locked;
    }

    final level = _levels[levelIndex];

    if (_completedLevelIds.contains(
      level.id,
    )) {
      return _LevelStatus.completed;
    }

    if (levelIndex ==
        _currentLevelIndex) {
      return _LevelStatus.current;
    }

    return _LevelStatus.locked;
  }

  Future<void> _openLevel(
      LevelModel level,
      ) async {
    await openLevelDetails(
      context,
      level,
    );

    if (!mounted) {
      return;
    }

    await _refreshLevelProgress();
  }

  Future<void> _continueLearning() async {
    final level = _currentLevel;

    if (level == null) {
      return;
    }

    await _openLevel(level);
  }

  Future<void> _handleLevelTap(
      int index,
      ) async {
    final status = _statusFor(index);
    final level = _levels[index];

    if (status == _LevelStatus.locked) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'আগের level complete করলে Level ${level.order} unlock হবে।',
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
      );

      return;
    }

    await _openLevel(level);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      _buildHomeTab(),
      const _TemporaryTab(
        icon: Icons.bolt_rounded,
        title: 'Daily Practice',
      ),
      const _TemporaryTab(
        icon: Icons.bar_chart_rounded,
        title: 'Progress',
      ),
      const _TemporaryTab(
        icon: Icons.settings_rounded,
        title: 'Settings',
      ),
    ];

    return Scaffold(
      backgroundColor: _surface,
      body: IndexedStack(
        index: _selectedTab,
        children: tabs,
      ),
      bottomNavigationBar:
      NavigationBar(
        selectedIndex: _selectedTab,
        height: 70,
        backgroundColor: _white,
        indicatorColor:
        _teal.withValues(
          alpha: 0.15,
        ),
        onDestinationSelected: (
            index,
            ) {
          setState(() {
            _selectedTab = index;
          });
        },
        destinations: const <
            NavigationDestination>[
          NavigationDestination(
            icon:
            Icon(Icons.route_outlined),
            selectedIcon: Icon(
              Icons.route_rounded,
              color: _teal,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon:
            Icon(Icons.bolt_outlined),
            selectedIcon: Icon(
              Icons.bolt_rounded,
              color: _teal,
            ),
            label: 'Practice',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.bar_chart_outlined,
            ),
            selectedIcon: Icon(
              Icons.bar_chart_rounded,
              color: _teal,
            ),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.settings_outlined,
            ),
            selectedIcon: Icon(
              Icons.settings_rounded,
              color: _teal,
            ),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton:
      _selectedTab == 0 &&
          !_loading &&
          _error == null &&
          _currentLevel != null
          ? FloatingActionButton
          .extended(
        onPressed:
        _continueLearning,
        backgroundColor:
        _yellow,
        foregroundColor: _ink,
        icon: const Icon(
          Icons
              .play_arrow_rounded,
        ),
        label: const Text(
          'Continue Learning',
          style: TextStyle(
            fontWeight:
            FontWeight.w900,
          ),
        ),
      )
          : null,
    );
  }

  Widget _buildHomeTab() {
    if (_loading) {
      return const Center(
        child:
        CircularProgressIndicator(
          color: _teal,
        ),
      );
    }

    if (_error != null) {
      return _ErrorView(
        message: _error!,
        onRetry: _loadHome,
      );
    }

    if (_levels.isEmpty) {
      return _ErrorView(
        message:
        'কোনো level পাওয়া যায়নি।',
        onRetry: _loadHome,
      );
    }

    final groupedLevels =
    SplayTreeMap<
        int,
        List<LevelModel>>();

    for (final level in _levels) {
      groupedLevels
          .putIfAbsent(
        level.worldId,
            () => <LevelModel>[],
      )
          .add(level);
    }

    return RefreshIndicator(
      color: _teal,
      onRefresh: _loadHome,
      child: CustomScrollView(
        physics:
        const AlwaysScrollableScrollPhysics(
          parent:
          BouncingScrollPhysics(),
        ),
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: _HomeHeader(
              streak: _streak,
              xp: _xp,
            ),
          ),
          SliverPadding(
            padding:
            const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              8,
            ),
            sliver: SliverToBoxAdapter(
              child: _DailyProgressCard(
                completedMinutes:
                _dailyMinutes,
                targetMinutes:
                _dailyTarget,
              ),
            ),
          ),
          for (
          final entry
          in groupedLevels.entries
          )
            SliverToBoxAdapter(
              child: _WorldSection(
                worldId: entry.key,
                levels: entry.value,
                allLevels: _levels,
                statusFor: _statusFor,
                onLevelTap:
                _handleLevelTap,
              ),
            ),
          const SliverToBoxAdapter(
            child:
            SizedBox(height: 110),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.streak,
    required this.xp,
  });

  final int streak;
  final int xp;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _ink,
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        18,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: <Widget>[
            const Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'ENGLISH BOLI',
                    style: TextStyle(
                      color: _teal,
                      fontSize: 13,
                      fontWeight:
                      FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'চলুন আজ English বলি',
                    style: TextStyle(
                      color: _white,
                      fontSize: 21,
                      fontWeight:
                      FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            _HeaderStat(
              icon: Icons
                  .local_fire_department_rounded,
              color: _coral,
              value: '$streak',
            ),
            const SizedBox(width: 8),
            _HeaderStat(
              icon: Icons.star_rounded,
              color: _yellow,
              value: '$xp',
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({
    required this.icon,
    required this.color,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: _white.withValues(
          alpha: 0.08,
        ),
        borderRadius:
        BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: _white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyProgressCard
    extends StatelessWidget {
  const _DailyProgressCard({
    required this.completedMinutes,
    required this.targetMinutes,
  });

  final int completedMinutes;
  final int targetMinutes;

  @override
  Widget build(BuildContext context) {
    final progress = targetMinutes <= 0
        ? 0.0
        : (completedMinutes /
        targetMinutes)
        .clamp(0.0, 1.0)
        .toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius:
        BorderRadius.circular(8),
        border: Border.all(
          color:
          const Color(0xFFDCE5E2),
        ),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.today_rounded,
                color: _teal,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Today’s speaking goal',
                  style: TextStyle(
                    color: _ink,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$completedMinutes/$targetMinutes min',
                style: const TextStyle(
                  color: _muted,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius:
            BorderRadius.circular(4),
            child:
            LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor:
              const Color(
                0xFFE5ECEA,
              ),
              color: _teal,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorldSection
    extends StatelessWidget {
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
  final _LevelStatus Function(int index)
  statusFor;
  final ValueChanged<int> onLevelTap;

  String get _worldTitle {
    const worldTitles = <int, String>{
      1: 'First Words',
      2: 'Ask & Answer',
      3: 'Time & Sentences',
      4: 'Real Life',
      5: 'Speak Freely',
    };

    return worldTitles[worldId] ??
        'Speaking Journey';
  }

  @override
  Widget build(BuildContext context) {
    final completedCount =
        levels.where((level) {
          final globalIndex =
          allLevels.indexOf(level);

          return statusFor(globalIndex) ==
              _LevelStatus.completed;
        }).length;

    return Padding(
      padding:
      const EdgeInsets.fromLTRB(
        16,
        10,
        16,
        12,
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            padding:
            const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: worldId.isEven
                  ? _teal
                  : _ink,
              borderRadius:
              BorderRadius.circular(8),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 46,
                  height: 46,
                  decoration:
                  BoxDecoration(
                    color: _yellow,
                    borderRadius:
                    BorderRadius.circular(
                      8,
                    ),
                  ),
                  child: const Icon(
                    Icons
                        .record_voice_over_rounded,
                    color: _ink,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: <Widget>[
                      Text(
                        'WORLD $worldId',
                        style: TextStyle(
                          color: _white
                              .withValues(
                            alpha: 0.7,
                          ),
                          fontSize: 12,
                          fontWeight:
                          FontWeight
                              .w800,
                        ),
                      ),
                      Text(
                        _worldTitle,
                        style:
                        const TextStyle(
                          color: _white,
                          fontSize: 19,
                          fontWeight:
                          FontWeight
                              .w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$completedCount/${levels.length}',
                  style: const TextStyle(
                    color: _white,
                    fontWeight:
                    FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (
                context,
                constraints,
                ) {
              final pathPoints =
              List<Offset>.generate(
                levels.length,
                    (index) {
                  const horizontalPositions =
                  <double>[
                    0.25,
                    0.50,
                    0.75,
                    0.58,
                    0.32,
                  ];

                  final x =
                      constraints.maxWidth *
                          horizontalPositions[
                          index %
                              horizontalPositions
                                  .length];

                  final y =
                      37 + (index * 118.0);

                  return Offset(x, y);
                },
              );

              return SizedBox(
                height:
                levels.length * 118.0,
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: CustomPaint(
                        painter:
                        _SpeechPathPainter(
                          pathPoints,
                        ),
                      ),
                    ),
                    for (
                    var index = 0;
                    index <
                        levels.length;
                    index++
                    )
                      Positioned(
                        left: (pathPoints[index]
                            .dx -
                            48)
                            .clamp(
                          0.0,
                          constraints
                              .maxWidth -
                              96,
                        )
                            .toDouble(),
                        top: index * 118.0,
                        child: _LevelNode(
                          level:
                          levels[index],
                          status: statusFor(
                            allLevels.indexOf(
                              levels[index],
                            ),
                          ),
                          onTap: () {
                            onLevelTap(
                              allLevels.indexOf(
                                levels[index],
                              ),
                            );
                          },
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

class _SpeechPathPainter
    extends CustomPainter {
  const _SpeechPathPainter(
      this.points,
      );

  final List<Offset> points;

  @override
  void paint(
      Canvas canvas,
      Size size,
      ) {
    if (points.length < 2) {
      return;
    }

    final path = Path()
      ..moveTo(
        points.first.dx,
        points.first.dy,
      );

    for (
    var index = 1;
    index < points.length;
    index++
    ) {
      final previous =
      points[index - 1];

      final current = points[index];

      final middleY =
          (previous.dy + current.dy) / 2;

      path.cubicTo(
        previous.dx,
        middleY,
        current.dx,
        middleY,
        current.dx,
        current.dy,
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = _locked
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(
      _SpeechPathPainter oldDelegate,
      ) {
    return oldDelegate.points != points;
  }
}

class _LevelNode extends StatelessWidget {
  const _LevelNode({
    required this.level,
    required this.status,
    required this.onTap,
  });

  final LevelModel level;
  final _LevelStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isCompleted =
        status == _LevelStatus.completed;

    final isCurrent =
        status == _LevelStatus.current;

    final backgroundColor = isCompleted
        ? _teal
        : isCurrent
        ? _yellow
        : _locked;

    final nodeIcon = isCompleted
        ? Icons.check_rounded
        : isCurrent
        ? Icons.mic_rounded
        : Icons.lock_rounded;

    return Semantics(
      button: true,
      label:
      'Level ${level.order}, ${status.name}',
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(48),
        child: SizedBox(
          width: 96,
          child: Column(
            children: <Widget>[
              AnimatedContainer(
                duration:
                const Duration(
                  milliseconds: 250,
                ),
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCurrent
                        ? _ink
                        : _white,
                    width:
                    isCurrent ? 4 : 3,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color:
                      _ink.withValues(
                        alpha: 0.13,
                      ),
                      offset:
                      const Offset(0, 5),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Icon(
                  nodeIcon,
                  color: isCurrent
                      ? _ink
                      : _white,
                  size: 31,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Level ${level.order}',
                textAlign:
                TextAlign.center,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 12,
                  fontWeight:
                  FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemporaryTab
    extends StatelessWidget {
  const _TemporaryTab({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              color: _teal,
              size: 52,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: _ink,
                fontSize: 23,
                fontWeight:
                FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'এই screen পরবর্তী step-এ তৈরি হবে।',
              style: TextStyle(
                color: _muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(24),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.error_outline_rounded,
              color: _coral,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign:
              TextAlign.center,
              style: const TextStyle(
                color: _ink,
                fontSize: 17,
                fontWeight:
                FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}