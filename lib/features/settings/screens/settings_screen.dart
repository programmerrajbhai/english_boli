import 'package:flutter/material.dart';
import '../../../core/widgets/magical_background.dart'; // আলাদা করা ব্যাকগ্রাউন্ড ফাইলটি ইমপোর্ট করা হলো

const _surface = Color(0xFF0A1412);
const _cardBg = Color(0xFF13221E);
const _teal = Color(0xFF00E0B8);
const _coral = Color(0xFFFF4B4B);
const _border = Color(0xFF1E332D);
const _muted = Color(0xFF6B8A80);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: _teal, onSurface: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _reminderTime) {
      setState(() => _reminderTime = picked);
    }
  }

  Future<void> _confirmResetProgress() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardBg,
        title: const Text('Reset All Progress?', style: TextStyle(fontWeight: FontWeight.w900, color: _coral)),
        content: const Text(
            'Are you sure you want to completely reset your progress? This action cannot be undone.',
            style: TextStyle(color: Colors.white70, height: 1.4)
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white))
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _coral, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset Progress', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Progress has been reset.'), backgroundColor: _coral)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24)),
        centerTitle: false,
      ),
      // Stack এবং CustomPainter মুছে দিয়ে সরাসরি MagicalBackground ব্যবহার করা হলো
      body: MagicalBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Learning Preferences'),
                _buildSettingsGroup(children: [
                  _buildSwitchTile('Sound Effects', Icons.volume_up_rounded, _soundEnabled, (val) => setState(() => _soundEnabled = val)),
                  _buildDivider(),
                  _buildSwitchTile('Default Slow Audio', Icons.slow_motion_video_rounded, _slowAudioDefault, (val) => setState(() => _slowAudioDefault = val)),
                  _buildDivider(),
                  _buildSwitchTile('Bangla Explanations', Icons.translate_rounded, _banglaExplanation, (val) => setState(() => _banglaExplanation = val)),
                ]),
                const SizedBox(height: 28),

                _buildSectionHeader('Notifications'),
                _buildSettingsGroup(children: [
                  _buildSwitchTile('Daily Practice Reminder', Icons.notifications_active_rounded, _dailyReminder, (val) => setState(() => _dailyReminder = val)),
                  if (_dailyReminder) ...[
                    _buildDivider(),
                    ListTile(
                      leading: const Icon(Icons.schedule_rounded, color: _teal),
                      title: const Text('Reminder Time', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(color: _teal.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                        child: Text(_reminderTime.format(context), style: const TextStyle(color: _teal, fontWeight: FontWeight.w900)),
                      ),
                      onTap: () => _selectReminderTime(context),
                    ),
                  ],
                ]),
                const SizedBox(height: 28),

                _buildSectionHeader('Permissions'),
                _buildSettingsGroup(children: [
                  ListTile(
                    leading: const Icon(Icons.mic_rounded, color: _muted),
                    title: const Text('Microphone Access', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    subtitle: const Text('Required for speaking practice', style: TextStyle(color: _muted, fontSize: 13)),
                    trailing: Text(_micPermissionGranted ? 'Granted' : 'Denied', style: TextStyle(color: _micPermissionGranted ? _teal : _coral, fontWeight: FontWeight.w900)),
                  ),
                ]),
                const SizedBox(height: 28),

                _buildSectionHeader('Account & Data'),
                _buildSettingsGroup(children: [
                  ListTile(
                    leading: const Icon(Icons.delete_forever_rounded, color: _coral),
                    title: const Text('Reset Progress', style: TextStyle(color: _coral, fontWeight: FontWeight.w800)),
                    onTap: _confirmResetProgress,
                  ),
                ]),
                const SizedBox(height: 28),

                _buildSectionHeader('About'),
                _buildSettingsGroup(children: [
                  ListTile(
                      leading: const Icon(Icons.privacy_tip_rounded, color: _muted),
                      title: const Text('Privacy Policy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: _muted)
                  ),
                  _buildDivider(),
                  ListTile(
                      leading: const Icon(Icons.info_outline_rounded, color: _muted),
                      title: const Text('About English Boli', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: _muted)
                  ),
                ]),
                const SizedBox(height: 40),

                Center(
                  child: Text(
                      'Version $_appVersion\nMade with ❤️ in Bangladesh',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: _muted, fontSize: 13, height: 1.5, fontWeight: FontWeight.w600)
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 12),
      child: Text(title.toUpperCase(), style: const TextStyle(color: _teal, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
    );
  }

  Widget _buildSettingsGroup({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(color: _cardBg.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(20), border: Border.all(color: _border)),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile(String title, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile.adaptive(
      secondary: Icon(icon, color: _muted),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      value: value,
      activeTrackColor: _teal.withValues(alpha: 0.5),
      activeThumbColor: _teal,
      inactiveTrackColor: _surface,
      onChanged: onChanged,
    );
  }

  Widget _buildDivider() => const Divider(height: 1, color: _border, indent: 56);
}