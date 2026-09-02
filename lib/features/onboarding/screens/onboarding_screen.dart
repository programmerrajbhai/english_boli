import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/routes/app_routes.dart';

const _ink = Color(0xFF08100E);
const _surface = Color(0xFFF7FAF9);
const _white = Color(0xFFFFFFFF);
const _muted = Color(0xFF66736F);
const _teal = Color(0xFF00BFAE);
const _yellow = Color(0xFFFFC928);
const _coral = Color(0xFFFF6B57);

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  int _currentPage = 0;
  int _dailyTarget = 15;
  bool _saving = false;

  static const _totalPages = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goNext() async {
    if (_currentPage < _totalPages - 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    await _completeOnboarding();
  }

  Future<void> _goBack() async {
    if (_currentPage == 0) return;

    await _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _skipToSetup() async {
    await _pageController.animateToPage(
      _totalPages - 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _completeOnboarding() async {
    if (_saving) return;

    setState(() => _saving = true);

    try {
      final preferences = SharedPreferencesAsync();

      await preferences.setInt('daily_target_minutes', _dailyTarget);

      await preferences.setBool('onboarding_completed', true);

      if (!mounted) return;

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
    } catch (_) {
      if (!mounted) return;

      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Setup save করা যায়নি। আবার চেষ্টা করুন।'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _totalPages - 1;

    return PopScope(
      canPop: _currentPage == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentPage > 0) {
          _goBack();
        }
      },
      child: Scaffold(
        backgroundColor: _surface,
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(
                currentPage: _currentPage,
                onBack: _goBack,
                onSkip: _skipToSetup,
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const ClampingScrollPhysics(),
                  onPageChanged: (page) {
                    setState(() => _currentPage = page);
                  },
                  children: [
                    const _IntroductionPage(
                      icon: Icons.route_rounded,
                      secondaryIcon: Icons.check_rounded,
                      accentColor: _yellow,
                      badgeColor: _teal,
                      title: 'Start step by step',
                      description:
                          'একদম সহজ শব্দ ও বাক্য থেকে শুরু করুন। '
                          'প্রতিটি level আগের শেখার উপর তৈরি হবে।',
                    ),
                    const _IntroductionPage(
                      icon: Icons.mic_rounded,
                      secondaryIcon: Icons.graphic_eq_rounded,
                      accentColor: _teal,
                      badgeColor: _coral,
                      title: 'Listen. Repeat. Speak.',
                      description:
                          'শুনুন, নিজের কণ্ঠে বলুন এবং নিয়মিত '
                          'practice করে speaking confidence তৈরি করুন।',
                    ),
                    _GoalSetupPage(
                      selectedMinutes: _dailyTarget,
                      onChanged: (minutes) {
                        setState(() => _dailyTarget = minutes);
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
                child: Column(
                  children: [
                    _PageIndicator(
                      currentPage: _currentPage,
                      pageCount: _totalPages,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _saving ? null : _goNext,
                      style: FilledButton.styleFrom(
                        backgroundColor: _ink,
                        foregroundColor: _white,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _saving
                            ? const SizedBox(
                                key: ValueKey('loading'),
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: _white,
                                ),
                              )
                            : Text(
                                isLastPage ? 'Start Learning' : 'Continue',
                                key: ValueKey(isLastPage),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.currentPage,
    required this.onBack,
    required this.onSkip,
  });

  final int currentPage;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: currentPage > 0
                ? IconButton(
                    tooltip: 'Previous',
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded, color: _ink),
                  )
                : null,
          ),
          const Expanded(
            child: Text(
              'ENGLISH BOLI',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ink,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
              ),
            ),
          ),
          SizedBox(
            width: 58,
            child: currentPage < 2
                ? TextButton(
                    onPressed: onSkip,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: _muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _IntroductionPage extends StatelessWidget {
  const _IntroductionPage({
    required this.icon,
    required this.secondaryIcon,
    required this.accentColor,
    required this.badgeColor,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final IconData secondaryIcon;
  final Color accentColor;
  final Color badgeColor;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 36),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _OnboardingIllustration(
                  icon: icon,
                  secondaryIcon: secondaryIcon,
                  accentColor: accentColor,
                  badgeColor: badgeColor,
                ),
                const SizedBox(height: 36),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 29,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Text(
                    description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 16,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OnboardingIllustration extends StatelessWidget {
  const _OnboardingIllustration({
    required this.icon,
    required this.secondaryIcon,
    required this.accentColor,
    required this.badgeColor,
  });

  final IconData icon;
  final IconData secondaryIcon;
  final Color accentColor;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 270,
      height: 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 18,
            right: 12,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(secondaryIcon, color: _white, size: 30),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 10,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: _yellow,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: accentColor, width: 3),
            ),
            child: Icon(icon, size: 86, color: _ink),
          ),
          Positioned(
            left: 18,
            top: 36,
            child: Container(
              width: 26,
              height: 9,
              decoration: BoxDecoration(
                color: _coral,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          Positioned(
            left: 5,
            top: 58,
            child: Container(
              width: 40,
              height: 9,
              decoration: BoxDecoration(
                color: _teal,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalSetupPage extends StatelessWidget {
  const _GoalSetupPage({
    required this.selectedMinutes,
    required this.onChanged,
  });

  final int selectedMinutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 34),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _OnboardingIllustration(
                  icon: Icons.local_fire_department_rounded,
                  secondaryIcon: Icons.schedule_rounded,
                  accentColor: _coral,
                  badgeColor: _teal,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Choose your daily goal',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _ink,
                    fontSize: 27,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'প্রতিদিন কত মিনিট English practice করতে চান?',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _muted, fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [10, 15, 20].map((minutes) {
                    final selected = selectedMinutes == minutes;

                    return ChoiceChip(
                      selected: selected,
                      onSelected: (_) => onChanged(minutes),
                      showCheckmark: false,
                      side: BorderSide(
                        color: selected ? _teal : const Color(0xFFD5DEDB),
                      ),
                      selectedColor: _teal,
                      backgroundColor: _white,
                      label: Text(
                        '$minutes min',
                        style: TextStyle(
                          color: selected ? _white : _ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _teal.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _teal.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.mic_none_rounded, color: _teal),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Speaking practice-এর সময় microphone permission '
                          'চাওয়া হবে। Permission না দিলেও অন্য lesson করা যাবে।',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 13,
                            height: 1.45,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.currentPage, required this.pageCount});

  final int currentPage;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Page ${currentPage + 1} of $pageCount',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(pageCount, (index) {
          final selected = index == currentPage;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: selected ? 26 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: selected ? _teal : const Color(0xFFD2DCDA),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}
