import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app.dart';
import '../../../core/routes/app_routes.dart';

const _background = Color(0xFF08100E);
const _white = Color(0xFFF9F8F3);
const _mutedWhite = Color(0xFFB9C4C1);
const _yellow = Color(0xFFFFC928);
const _teal = Color(0xFF00BFAE);
const _error = Color(0xFFFF7766);

enum SplashState { loading, ready, error }

enum SplashDestination { onboarding, home }

abstract interface class CourseContentLoader {
  Future<void> validateCourse();
}

abstract interface class OnboardingStatusReader {
  Future<bool> hasCompletedOnboarding();
}

class AssetCourseContentLoader implements CourseContentLoader {
  const AssetCourseContentLoader();

  @override
  Future<void> validateCourse() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);

    final levelFiles = manifest
        .listAssets()
        .where(
          (path) =>
              path.startsWith('assets/data/levels/') && path.endsWith('.json'),
        )
        .toList(growable: false);

    if (levelFiles.isEmpty) {
      throw StateError('No level content found');
    }

    final usedIds = <int>{};

    for (final file in levelFiles) {
      final source = await rootBundle.loadString(file);
      final Object? decoded;

      try {
        decoded = jsonDecode(source);
      } on FormatException {
        throw StateError('Invalid JSON: $file');
      }

      if (decoded is! Map<String, dynamic>) {
        throw StateError('Invalid level object: $file');
      }

      final id = decoded['id'];
      final order = decoded['order'];
      final title = decoded['title'];
      final schemaVersion = decoded['schemaVersion'];

      if (schemaVersion is! int || schemaVersion < 1) {
        throw StateError('Invalid schema version: $file');
      }

      if (id is! int || id < 1 || !usedIds.add(id)) {
        throw StateError('Missing or duplicate level ID: $file');
      }

      if (order is! int || order < 1) {
        throw StateError('Invalid level order: $file');
      }

      if (title is! String || title.trim().isEmpty) {
        throw StateError('Missing level title: $file');
      }
    }
  }
}

class LocalOnboardingStatusReader implements OnboardingStatusReader {
  LocalOnboardingStatusReader({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _key = 'onboarding_completed';

  final SharedPreferencesAsync _preferences;

  @override
  Future<bool> hasCompletedOnboarding() async {
    return await _preferences.getBool(_key) ?? false;
  }
}

class SplashController {
  SplashController({
    required CourseContentLoader contentLoader,
    required OnboardingStatusReader onboardingReader,
    this.minimumDuration = const Duration(milliseconds: 1500),
  }) : _contentLoader = contentLoader,
       _onboardingReader = onboardingReader;

  final CourseContentLoader _contentLoader;
  final OnboardingStatusReader _onboardingReader;
  final Duration minimumDuration;

  SplashState state = SplashState.loading;
  SplashDestination? destination;
  String? errorMessage;

  Future<void> initialize() async {
    state = SplashState.loading;
    destination = null;
    errorMessage = null;

    final stopwatch = Stopwatch()..start();

    try {
      final contentFuture = _contentLoader.validateCourse();
      final onboardingFuture = _onboardingReader.hasCompletedOnboarding();

      await contentFuture;
      final onboardingCompleted = await onboardingFuture;

      final remaining = minimumDuration - stopwatch.elapsed;

      if (remaining > Duration.zero) {
        await Future<void>.delayed(remaining);
      }

      destination = onboardingCompleted
          ? SplashDestination.home
          : SplashDestination.onboarding;

      state = SplashState.ready;
    } catch (_) {
      state = SplashState.error;
      errorMessage = 'Learning content load করা যায়নি।';
    } finally {
      stopwatch.stop();
    }
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.controller});

  final SplashController? controller;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final SplashController _controller;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  bool _requestRunning = false;

  @override
  void initState() {
    super.initState();

    _controller =
        widget.controller ??
        SplashController(
          contentLoader: const AssetCourseContentLoader(),
          onboardingReader: LocalOnboardingStatusReader(),
        );

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
    _initialize();
  }

  Future<void> _initialize() async {
    if (_requestRunning) return;

    _requestRunning = true;

    final initialization = _controller.initialize();

    if (mounted) {
      setState(() {});
    }

    await initialization;
    _requestRunning = false;

    if (!mounted) return;

    setState(() {});

    if (_controller.state == SplashState.ready) {
      final route = _controller.destination == SplashDestination.home
          ? AppRoutes.home
          : AppRoutes.onboarding;

      Navigator.of(context).pushReplacementNamed(route);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.clamp(260.0, 390.0).toDouble();

            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: SizedBox(
                        width: width,
                        child: const FittedBox(
                          fit: BoxFit.contain,
                          child: EnglishBoliLogo(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'শিখি। বলি। এগিয়ে যাই।',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _mutedWhite,
                      fontSize: 16,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(flex: 3),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _controller.state == SplashState.error
                        ? _ErrorView(
                            key: const ValueKey('error'),
                            message: _controller.errorMessage,
                            onRetry: _requestRunning ? null : _initialize,
                          )
                        : const _LoadingView(key: ValueKey('loading')),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class EnglishBoliLogo extends StatelessWidget {
  const EnglishBoliLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'English Boli',
      child: SizedBox(
        width: 340,
        height: 205,
        child: CustomPaint(painter: _EnglishBoliLogoPainter()),
      ),
    );
  }
}

class _EnglishBoliLogoPainter extends CustomPainter {
  const _EnglishBoliLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    _paintText(
      canvas,
      text: 'E N G L I S H',
      offset: const Offset(47, 4),
      fontSize: 25,
      weight: FontWeight.w700,
    );

    _paintText(
      canvas,
      text: 'B',
      offset: const Offset(20, 52),
      fontSize: 108,
      weight: FontWeight.w900,
    );

    _paintText(
      canvas,
      text: 'LI',
      offset: const Offset(200, 52),
      fontSize: 108,
      weight: FontWeight.w900,
    );

    final yellowPaint = Paint()
      ..color = _yellow
      ..style = PaintingStyle.fill;

    const center = Offset(154, 112);

    canvas.drawCircle(center, 45, yellowPaint);
    canvas.drawCircle(center, 22, Paint()..color = _background);

    final tail = Path()
      ..moveTo(179, 145)
      ..lineTo(201, 159)
      ..lineTo(184, 132)
      ..close();

    canvas.drawPath(tail, yellowPaint);

    final underline = Path()
      ..moveTo(57, 183)
      ..cubicTo(105, 190, 132, 181, 163, 196)
      ..cubicTo(190, 181, 235, 190, 285, 181);

    canvas.drawPath(
      underline,
      Paint()
        ..color = _teal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _paintText(
    Canvas canvas, {
    required String text,
    required Offset offset,
    required double fontSize,
    required FontWeight weight,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: _white,
          fontSize: fontSize,
          height: 1,
          fontWeight: weight,
          letterSpacing: 0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_EnglishBoliLogoPainter oldDelegate) => false;
}

class _LoadingView extends StatefulWidget {
  const _LoadingView({super.key});

  @override
  State<_LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<_LoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Learning content loading',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 62,
            height: 20,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(3, (index) {
                    final phase = (_controller.value - index * 0.18) % 1;

                    final strength = 1 - ((phase - 0.5).abs() * 2);

                    final dotSize = (7 + strength.clamp(0.0, 1.0) * 4)
                        .toDouble();

                    return Container(
                      width: dotSize,
                      height: dotSize,
                      decoration: BoxDecoration(
                        color: index == 1 ? _teal : _yellow,
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Learning journey প্রস্তুত হচ্ছে...',
            style: TextStyle(
              color: _mutedWhite,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({super.key, required this.message, required this.onRetry});

  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: _error, size: 32),
            const SizedBox(height: 10),
            const Text(
              'App চালু করা যায়নি',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message ?? 'অনুগ্রহ করে আবার চেষ্টা করো।',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _mutedWhite,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                minimumSize: const Size(150, 52),
                backgroundColor: _yellow,
                foregroundColor: _background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                'আবার চেষ্টা করুন',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
