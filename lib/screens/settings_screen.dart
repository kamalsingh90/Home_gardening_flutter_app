import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../data.dart';
import '../services/notification_service.dart';
import '../services/reminders.dart';
import '../services/update_service.dart';
import '../store.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.store, required this.content});
  final Store store;
  final Content content;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((p) {
      if (mounted) setState(() => _version = p.version);
    });
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _toggleReminder(bool on) async {
    final s = widget.store;
    if (on) {
      final ok = await NotificationService.requestPermission();
      if (!ok) {
        if (mounted) _snack('Please allow notifications for this app in Android settings.');
        return;
      }
    }
    await s.setNotifEnabled(on);
    await refreshReminders(s, widget.content);
    if (mounted) {
      _snack(on ? 'Morning reminder is on' : 'Morning reminder is off');
    }
  }

  Future<void> _pickTime() async {
    final s = widget.store;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: s.notifHour, minute: s.notifMinute),
    );
    if (t == null) return;
    await s.setNotifTime(t.hour, t.minute);
    await refreshReminders(s, widget.content);
  }

  Future<void> _checkUpdates() async {
    if (!UpdateService.configured) {
      _snack('Update link is not set yet. See the README (step: update link).');
      return;
    }
    setState(() => _checking = true);
    try {
      final u = await UpdateService.check();
      if (!mounted) return;
      if (u == null) {
        _snack('You have the latest version.');
      } else {
        await UpdateService.showUpdateDialog(context, widget.store, u);
      }
    } catch (_) {
      if (mounted) _snack('Could not check for updates. Please check your internet connection.');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: ListenableBuilder(
        listenable: widget.store,
        builder: (context, _) {
          final s = widget.store;
          final timeLabel = TimeOfDay(hour: s.notifHour, minute: s.notifMinute).format(context);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Settings', style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: cs.primary)),
              const SizedBox(height: 14),
              Card(
                elevation: 0,
                color: cs.primaryContainer.withAlpha(140),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: Icon(Icons.notifications_active, color: cs.primary),
                      title: const Text('Daily morning reminder', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('A new garden tip every morning'),
                      value: s.notifEnabled,
                      onChanged: _toggleReminder,
                    ),
                    ListTile(
                      enabled: s.notifEnabled,
                      leading: Icon(Icons.access_time, color: s.notifEnabled ? cs.primary : null),
                      title: const Text('Reminder time'),
                      subtitle: Text(timeLabel),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: s.notifEnabled ? _pickTime : null,
                    ),
                    ListTile(
                      leading: Icon(Icons.send, color: cs.primary),
                      title: const Text('Send a test notification'),
                      onTap: () async {
                        final ok = await NotificationService.requestPermission();
                        if (!ok) {
                          if (mounted) _snack('Please allow notifications for this app in Android settings.');
                          return;
                        }
                        await NotificationService.showTest(
                            widget.content.tips[tipIndexFor(DateTime.now(), widget.content.tips.length)]);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: cs.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: Icon(Icons.text_fields, color: cs.primary),
                    title: const Text('Reading text size'),
                    subtitle: Slider(
                      min: 0.85,
                      max: 1.6,
                      divisions: 15,
                      value: s.fontScale.clamp(0.85, 1.6).toDouble(),
                      onChanged: (v) => s.setFontScale(v),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: cs.outlineVariant),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.system_update, color: cs.primary),
                      title: const Text('Check for updates', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(_version.isEmpty ? 'Version ...' : 'Installed version $_version'),
                      trailing: _checking
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                          : const Icon(Icons.chevron_right),
                      onTap: _checking ? null : _checkUpdates,
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: Text(
                        'The app also checks automatically when you open it. When an update exists, tap '
                        '"Download update", then open the downloaded file to install it over this app. '
                        'Your progress and settings are kept.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Card(
                elevation: 0,
                color: cs.surfaceContainerHighest.withAlpha(120),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Home Gardening for Beginners\nGrow Green  •  Live Healthy  •  Enjoy Nature\n\n'
                    'This app contains general gardening information. Always follow product labels and '
                    'keep chemicals, sharp tools and toxic plants away from children and pets.',
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
