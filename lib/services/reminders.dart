import '../data.dart';
import '../store.dart';
import 'notification_service.dart';

/// Re-creates (or cancels) the next 30 days of morning notifications from the saved settings.
Future<void> refreshReminders(Store s, Content c) async {
  if (s.notifEnabled) {
    await NotificationService.scheduleDaily(hour: s.notifHour, minute: s.notifMinute, tips: c.tips);
  } else {
    await NotificationService.cancelAll();
  }
}
