import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _ink = Color(0xFF08100E);
  static const _teal = Color(0xFF00BFAE);
  static const _coral = Color(0xFFFF6B57);
  static const _background = Color(0xFFF5F9F8);
  static const _muted = Color(0xFF66736F);
  static const _border = Color(0xFFDCE5E2);

  bool _soundEnabled = true;
  bool _slowAudioDefault = false;
  bool _banglaExplanation = true;
  bool _dailyReminder = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  final bool _micPermissionGranted = true;
  final String _appVersion = "1.0.0 (Build 12)";

  Future<void> _selectReminderTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: _teal,
              onSurface: _ink,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _reminderTime) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  Future<void> _confirmResetProgress() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Reset All Progress?',
            style: TextStyle(fontWeight: FontWeight.w900, color: _coral),
          ),
          content: const Text(
            'Are you sure you want to completely reset your progress? This action cannot be undone. All your stars, XP, and unlocked levels will be lost.',
            style: TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: _ink)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _coral,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reset Progress', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Progress has been reset.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(color: _ink, fontWeight: FontWeight.w900, fontSize: 20),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Learning Preferences'),
            _buildSettingsGroup(
              children: [
                _buildSwitchTile(
                  title: 'Sound Effects',
                  icon: Icons.volume_up_rounded,
                  value: _soundEnabled,
                  onChanged: (val) => setState(() => _soundEnabled = val),
                ),
                _buildDivider(),
                _buildSwitchTile(
                  title: 'Default Slow Audio',
                  icon: Icons.slow_motion_video_rounded,
                  value: _slowAudioDefault,
                  onChanged: (val) => setState(() => _slowAudioDefault = val),
                ),
                _buildDivider(),
                _buildSwitchTile(
                  title: 'Bangla Explanations',
                  icon: Icons.translate_rounded,
                  value: _banglaExplanation,
                  onChanged: (val) => setState(() => _banglaExplanation = val),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Notifications'),
            _buildSettingsGroup(
              children: [
                _buildSwitchTile(
                  title: 'Daily Practice Reminder',
                  icon: Icons.notifications_active_rounded,
                  value: _dailyReminder,
                  onChanged: (val) => setState(() => _dailyReminder = val),
                ),
                if (_dailyReminder) ...[
                  _buildDivider(),
                  ListTile(
                    leading: const Icon(Icons.schedule_rounded, color: _muted),
                    title: const Text('Reminder Time', style: TextStyle(color: _ink, fontWeight: FontWeight.w700)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _teal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _reminderTime.format(context),
                        style: const TextStyle(color: _teal, fontWeight: FontWeight.w900),
                      ),
                    ),
                    onTap: () => _selectReminderTime(context),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Permissions'),
            _buildSettingsGroup(
              children: [
                ListTile(
                  leading: const Icon(Icons.mic_rounded, color: _muted),
                  title: const Text('Microphone Access', style: TextStyle(color: _ink, fontWeight: FontWeight.w700)),
                  subtitle: const Text('Required for speaking practice', style: TextStyle(color: _muted, fontSize: 12)),
                  trailing: Text(
                    _micPermissionGranted ? 'Granted' : 'Denied',
                    style: TextStyle(
                      color: _micPermissionGranted ? _teal : _coral,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Account & Data'),
            _buildSettingsGroup(
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_forever_rounded, color: _coral),
                  title: const Text(
                    'Reset Progress',
                    style: TextStyle(color: _coral, fontWeight: FontWeight.w800),
                  ),
                  onTap: _confirmResetProgress,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('About'),
            _buildSettingsGroup(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_rounded, color: _muted),
                  title: const Text('Privacy Policy', style: TextStyle(color: _ink, fontWeight: FontWeight.w700)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: _muted),
                  onTap: () {},
                ),
                _buildDivider(),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded, color: _muted),
                  title: const Text('About English Boli', style: TextStyle(color: _ink, fontWeight: FontWeight.w700)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: _muted),
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Version $_appVersion\nMade with ❤️ in Bangladesh',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted, fontSize: 13, height: 1.5, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: _muted,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      secondary: Icon(icon, color: _muted),
      title: Text(title, style: const TextStyle(color: _ink, fontWeight: FontWeight.w700)),
      value: value,
      activeTrackColor: _teal.withValues(alpha: 0.5), // activeColor replaced
      activeThumbColor: _teal, // activeColor replaced
      onChanged: onChanged,
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, color: _border, indent: 56);
  }
}