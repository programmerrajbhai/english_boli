
import 'package:flutter/material.dart';

// Mock Model for Achievement/Reward
class AchievementItem {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isUnlocked;
  final int requiredLevel;
  final int rewardXp;

  AchievementItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isUnlocked,
    required this.requiredLevel,
    required this.rewardXp,
  });
}

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  // Design System Colors
  static const _ink = Color(0xFF08100E);
  static const _teal = Color(0xFF00BFAE);
  static const _yellow = Color(0xFFFFC928);
  static const _coral = Color(0xFFFF6B57);
  static const _background = Color(0xFFF5F9F8);
  static const _muted = Color(0xFF66736F);
  static const _border = Color(0xFFDCE5E2);

  // Mock Data
  final int _totalXp = 2450;
  final int _totalStars = 38;
  late List<AchievementItem> _achievements;

  @override
  void initState() {
    super.initState();
    _achievements = [
      AchievementItem(
        id: '1',
        title: 'Beginner Steps',
        description: 'Complete Level 10 to earn this badge.',
        icon: Icons.directions_walk_rounded,
        color: _teal,
        isUnlocked: true,
        requiredLevel: 10,
        rewardXp: 100,
      ),
      AchievementItem(
        id: '2',
        title: 'Steady Learner',
        description: 'Complete Level 20 to earn this badge.',
        icon: Icons.directions_run_rounded,
        color: _yellow,
        isUnlocked: true,
        requiredLevel: 20,
        rewardXp: 200,
      ),
      AchievementItem(
        id: '3',
        title: 'Halfway There',
        description: 'Complete Level 30 to earn this badge.',
        icon: Icons.hiking_rounded,
        color: const Color(0xFF8A63D2), // Purple
        isUnlocked: false,
        requiredLevel: 30,
        rewardXp: 300,
      ),
      AchievementItem(
        id: '4',
        title: 'Advanced Speaker',
        description: 'Complete Level 40 to earn this badge.',
        icon: Icons.record_voice_over_rounded,
        color: _coral,
        isUnlocked: false,
        requiredLevel: 40,
        rewardXp: 400,
      ),
      AchievementItem(
        id: '5',
        title: 'English Master',
        description: 'Complete Level 50 to earn the ultimate badge.',
        icon: Icons.workspace_premium_rounded,
        color: _ink,
        isUnlocked: false,
        requiredLevel: 50,
        rewardXp: 500,
      ),
    ];
  }

  void _showRewardDetails(AchievementItem achievement) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: _border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: achievement.isUnlocked
                      ? achievement.color.withValues(alpha: 0.15)
                      : _border.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  achievement.isUnlocked ? achievement.icon : Icons.lock_rounded,
                  color: achievement.isUnlocked ? achievement.color : _muted,
                  size: 42,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                achievement.title,
                style: const TextStyle(color: _ink, fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                achievement.description,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted, fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _yellow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _yellow.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded, color: _coral, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Reward: +${achievement.rewardXp} XP',
                      style: const TextStyle(color: _ink, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _ink,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Awesome!', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Rewards & Badges',
          style: TextStyle(color: _ink, fontWeight: FontWeight.w900, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTotalRewardsCard(),
            const SizedBox(height: 32),
            const Text(
              'Milestone Badges',
              style: TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            const Text(
              'Unlock these by completing levels',
              style: TextStyle(color: _muted, fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildBadgesGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRewardsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
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
              children: [
                const Icon(Icons.bolt_rounded, color: _coral, size: 36),
                const SizedBox(height: 8),
                Text(
                  '$_totalXp',
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                ),
                const Text(
                  'Total XP',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 60, color: Colors.white24),
          Expanded(
            child: Column(
              children: [
                const Icon(Icons.star_rounded, color: _yellow, size: 36),
                const SizedBox(height: 8),
                Text(
                  '$_totalStars',
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                ),
                const Text(
                  'Total Stars',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: _achievements.length,
      itemBuilder: (context, index) {
        final achievement = _achievements[index];
        return _buildBadgeCard(achievement);
      },
    );
  }

  Widget _buildBadgeCard(AchievementItem achievement) {
    return InkWell(
      onTap: () => _showRewardDetails(achievement),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          boxShadow: achievement.isUnlocked
              ? const [
            BoxShadow(
              color: Color(0x0808100E),
              blurRadius: 10,
              offset: Offset(0, 4),
            )
          ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: achievement.isUnlocked
                    ? achievement.color.withValues(alpha: 0.15)
                    : _background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                achievement.isUnlocked ? achievement.icon : Icons.lock_rounded,
                color: achievement.isUnlocked ? achievement.color : _muted.withValues(alpha: 0.5),
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                color: achievement.isUnlocked ? _ink : _muted,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Level ${achievement.requiredLevel}',
              style: TextStyle(
                color: achievement.isUnlocked ? _teal : _muted.withValues(alpha: 0.6),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}