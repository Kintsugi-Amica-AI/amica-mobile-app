import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_notification.dart';

/// The list behind the Notifications screen.
///
/// Kept on the device in SharedPreferences: pushes can arrive while Amica is
/// closed (in a background isolate), and the list has to be there when she
/// next opens the app. Every change re-reads the stored copy first, so a
/// notification recorded by the background isolate is never overwritten by a
/// stale in-memory list.
class NotificationInboxService {
  NotificationInboxService._();

  static final NotificationInboxService instance = NotificationInboxService._();

  static const String _key = 'amica_notification_inbox_v1';

  /// Older notifications fall off the end, so the list cannot grow forever.
  static const int maxItems = 100;

  /// Newest first.
  final ValueNotifier<List<AppNotification>> items =
      ValueNotifier<List<AppNotification>>(const []);
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  Future<List<AppNotification>> _read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Another isolate may have written since this one last looked.
      await prefs.reload();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return [
        for (final entry in decoded)
          if (AppNotification.fromJson(entry) case final item?) item,
      ];
    } catch (_) {
      return [];
    }
  }

  Future<void> _write(List<AppNotification> list) async {
    _publish(list);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode([for (final n in list) n.toJson()]),
      );
    } catch (_) {/* Best effort: the system notification was still shown. */}
  }

  void _publish(List<AppNotification> list) {
    items.value = List.unmodifiable(list);
    unreadCount.value = list.where((n) => !n.read).length;
  }

  Future<void> _change(void Function(List<AppNotification> list) edit) async {
    final list = await _read();
    edit(list);
    await _write(list);
  }

  /// Reads the stored list into [items] and [unreadCount].
  ///
  /// Only publishes when something changed, so calling it on a timer does not
  /// rebuild the screens listening to it.
  Future<void> load() async {
    final list = await _read();
    final current = items.value;
    var same = list.length == current.length;
    for (var i = 0; same && i < list.length; i++) {
      same = list[i].id == current[i].id && list[i].read == current[i].read;
    }
    if (!same) _publish(list);
  }

  Timer? _refreshTimer;
  int _watchers = 0;

  /// Keeps the list fresh while a screen that shows it is open.
  ///
  /// Android services and background pushes add to the stored list from
  /// outside this isolate, so the in-memory copy has to be re-read now and
  /// then, not only when the app is resumed. Call [stopWatching] to match.
  void startWatching({Duration every = const Duration(seconds: 4)}) {
    _watchers++;
    _refreshTimer ??= Timer.periodic(every, (_) => unawaited(load()));
  }

  void stopWatching() {
    if (_watchers > 0) _watchers--;
    if (_watchers == 0) {
      _refreshTimer?.cancel();
      _refreshTimer = null;
    }
  }

  Future<void> add(AppNotification notification) => _change((list) {
        list.insert(0, notification);
        if (list.length > maxItems) list.removeRange(maxItems, list.length);
      });

  Future<void> markRead(String id) => _change((list) {
        final i = list.indexWhere((n) => n.id == id);
        if (i >= 0 && !list[i].read) list[i] = list[i].copyWith(read: true);
      });

  Future<void> markAllRead() => _change((list) {
        for (var i = 0; i < list.length; i++) {
          if (!list[i].read) list[i] = list[i].copyWith(read: true);
        }
      });

  Future<void> remove(String id) {
    // Published at once: a swiped-away row must leave the tree this frame.
    _publish(items.value.where((n) => n.id != id).toList());
    return _change((list) => list.removeWhere((n) => n.id == id));
  }

  /// Puts a removed notification back where it was (by time), for "Undo".
  Future<void> restore(AppNotification notification) => _change((list) {
        if (list.any((n) => n.id == notification.id)) return;
        list.add(notification);
        list.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
      });

  Future<void> clear() => _change((list) => list.clear());
}
