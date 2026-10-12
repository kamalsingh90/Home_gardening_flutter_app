import 'package:flutter/material.dart';

import 'data.dart';
import 'screens/care_screen.dart';
import 'screens/library_screen.dart';
import 'screens/reader_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/today_screen.dart';
import 'services/notification_service.dart';
import 'services/reminders.dart';
import 'services/update_service.dart';
import 'store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await Store.load();
  final content = await Content.load();
  await NotificationService.init();
  runApp(GardenApp(store: store, content: content));
}

class GardenApp extends StatelessWidget {
  const GardenApp({super.key, required this.store, required this.content});
  final Store store;
  final Content content;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF2E7D32);
    return MaterialApp(
      title: 'Home Gardening',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        scaffoldBackgroundColor: const Color(0xFFFBFBF7),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
      ),
      home: HomeShell(store: store, content: content),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.store, required this.content});
  final Store store;
  final Content content;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    final s = widget.store;
    if (!s.onboarded) {
      await _askForReminder();
    } else {
      await refreshReminders(s, widget.content);
    }
    if (!mounted) return;
    await UpdateService.autoCheck(context, s);
  }

  Future<void> _askForReminder() async {
    final s = widget.store;
    final yes = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Text('🌱', style: TextStyle(fontSize: 40)),
        title: const Text('Welcome to Home Gardening'),
        content: const Text(
          'Would you like a short gardening tip every morning at 7:30 AM? '
          'You can change the time or turn it off any time in Settings.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not now')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, remind me')),
        ],
      ),
    );
    var enable = false;
    if (yes == true) {
      enable = await NotificationService.requestPermission();
    }
    await s.setNotifEnabled(enable);
    await s.setOnboarded();
    await refreshReminders(s, widget.content);
  }

  void _open(int chapterNum) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ReaderScreen(
        content: widget.content,
        store: widget.store,
        startIndex: widget.content.indexOfNum(chapterNum),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      TodayScreen(store: widget.store, content: widget.content, openChapter: _open),
      LibraryScreen(store: widget.store, content: widget.content, openChapter: _open),
      CareScreen(store: widget.store, openChapter: _open),
      SettingsScreen(store: widget.store, content: widget.content),
    ];
    return Scaffold(
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.wb_sunny_outlined), selectedIcon: Icon(Icons.wb_sunny), label: 'Today'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Book'),
          NavigationDestination(icon: Icon(Icons.checklist), selectedIcon: Icon(Icons.checklist_rtl), label: 'Care'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
