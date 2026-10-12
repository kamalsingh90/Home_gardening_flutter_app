import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../store.dart';

/// 1) Replace YOUR_GITHUB_USERNAME (and the repo name if you changed it).
/// 2) Every time you release a new version, edit version.json in your repo.
const String kUpdateJsonUrl =
    'https://raw.githubusercontent.com/YOUR_GITHUB_USERNAME/home-gardening-app/main/version.json';

class UpdateInfo {
  UpdateInfo(this.version, this.apkUrl, this.notes);
  final String version;
  final String apkUrl;
  final String notes;
}

class UpdateService {
  static bool get configured => !kUpdateJsonUrl.contains('YOUR_GITHUB_USERNAME');

  static bool _isNewer(String latest, String current) {
    final a = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final b = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (var i = 0; i < 3; i++) {
      final x = i < a.length ? a[i] : 0;
      final y = i < b.length ? b[i] : 0;
      if (x > y) return true;
      if (x < y) return false;
    }
    return false;
  }

  /// Returns update info if a newer version exists, otherwise null.
  /// Throws if the server cannot be reached.
  static Future<UpdateInfo?> check() async {
    final res = await http.get(Uri.parse(kUpdateJsonUrl)).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final latest = (j['version'] ?? '0.0.0') as String;
    final info = await PackageInfo.fromPlatform();
    if (_isNewer(latest, info.version)) {
      return UpdateInfo(latest, (j['apkUrl'] ?? '') as String, (j['notes'] ?? '') as String);
    }
    return null;
  }

  /// Automatic check on app start (at most once every 12 hours, silent on errors).
  static Future<void> autoCheck(BuildContext context, Store store) async {
    if (!configured) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - store.lastUpdateCheck < 12 * 3600 * 1000) return;
    await store.setLastUpdateCheck(now);
    try {
      final u = await check();
      if (u == null || u.version == store.dismissedVersion) return;
      if (!context.mounted) return;
      await showUpdateDialog(context, store, u);
    } catch (_) {}
  }

  static Future<void> showUpdateDialog(BuildContext context, Store store, UpdateInfo u) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update available (v${u.version})'),
        content: Text(u.notes.isEmpty ? 'A new version of Home Gardening is ready.' : u.notes),
        actions: [
          TextButton(
            onPressed: () {
              store.setDismissedVersion(u.version);
              Navigator.pop(ctx);
            },
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              launchUrl(Uri.parse(u.apkUrl), mode: LaunchMode.externalApplication);
              Navigator.pop(ctx);
            },
            child: const Text('Download update'),
          ),
        ],
      ),
    );
  }
}
