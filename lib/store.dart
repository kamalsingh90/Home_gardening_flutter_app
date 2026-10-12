import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data.dart';

/// Small wrapper around SharedPreferences that notifies the UI when something changes.
class Store extends ChangeNotifier {
  Store._(this._p);
  final SharedPreferences _p;

  static Future<Store> load() async {
    final s = Store._(await SharedPreferences.getInstance());
    await s._rollover();
    return s;
  }

  // ---------- settings ----------
  bool get onboarded => _p.getBool('onboarded') ?? false;
  bool get notifEnabled => _p.getBool('notif') ?? false;
  int get notifHour => _p.getInt('nh') ?? 7;
  int get notifMinute => _p.getInt('nm') ?? 30;
  double get fontScale => _p.getDouble('fs') ?? 1.0;

  Future<void> setOnboarded() async {
    await _p.setBool('onboarded', true);
    notifyListeners();
  }

  Future<void> setNotifEnabled(bool v) async {
    await _p.setBool('notif', v);
    notifyListeners();
  }

  Future<void> setNotifTime(int h, int m) async {
    await _p.setInt('nh', h);
    await _p.setInt('nm', m);
    notifyListeners();
  }

  Future<void> setFontScale(double v) async {
    await _p.setDouble('fs', v);
    notifyListeners();
  }

  // ---------- reading ----------
  int get lastChapter => _p.getInt('last') ?? 1;
  Set<int> get readChapters => (_p.getStringList('read') ?? <String>[]).map(int.parse).toSet();

  Future<void> setLastChapter(int n) async {
    await _p.setInt('last', n);
    notifyListeners();
  }

  Future<void> markRead(int n) async {
    final s = readChapters..add(n);
    await _p.setStringList('read', s.map((e) => '$e').toList());
    notifyListeners();
  }

  // ---------- daily tasks ----------
  List<String> doneFor(DateTime d) => _p.getStringList('done_${dateKey(d)}') ?? <String>[];

  Future<void> toggleTask(DateTime d, String id) async {
    final list = doneFor(d);
    if (list.contains(id)) {
      list.remove(id);
    } else {
      list.add(id);
    }
    await _p.setStringList('done_${dateKey(d)}', list);
    notifyListeners();
  }

  /// Number of consecutive days (ending today, or yesterday) with at least one finished task.
  int get streak {
    var day = DateTime.now();
    if (doneFor(day).isEmpty) day = day.subtract(const Duration(days: 1));
    var n = 0;
    while (doneFor(day).isNotEmpty && n < 3650) {
      n++;
      day = day.subtract(const Duration(days: 1));
    }
    return n;
  }

  // ---------- weekly / monthly checklists ----------
  Set<String> get weekChecked => (_p.getStringList('chk_week') ?? <String>[]).toSet();
  Set<String> get monthChecked => (_p.getStringList('chk_month') ?? <String>[]).toSet();

  Future<void> toggleWeek(String item) async {
    final s = weekChecked;
    if (!s.add(item)) s.remove(item);
    await _p.setStringList('chk_week', s.toList());
    notifyListeners();
  }

  Future<void> toggleMonth(String item) async {
    final s = monthChecked;
    if (!s.add(item)) s.remove(item);
    await _p.setStringList('chk_month', s.toList());
    notifyListeners();
  }

  Future<void> resetChecklists() async {
    await _p.setStringList('chk_week', <String>[]);
    await _p.setStringList('chk_month', <String>[]);
    notifyListeners();
  }

  Future<void> _rollover() async {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final wk = dateKey(monday);
    if (_p.getString('week_key') != wk) {
      await _p.setString('week_key', wk);
      await _p.setStringList('chk_week', <String>[]);
    }
    final mk = '${now.year}-${two(now.month)}';
    if (_p.getString('month_key') != mk) {
      await _p.setString('month_key', mk);
      await _p.setStringList('chk_month', <String>[]);
    }
  }

  // ---------- updates ----------
  int get lastUpdateCheck => _p.getInt('upd_check') ?? 0;
  String get dismissedVersion => _p.getString('upd_dismissed') ?? '';

  Future<void> setLastUpdateCheck(int ms) => _p.setInt('upd_check', ms);
  Future<void> setDismissedVersion(String v) => _p.setString('upd_dismissed', v);
}
