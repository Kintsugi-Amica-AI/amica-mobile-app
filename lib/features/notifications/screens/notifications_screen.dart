import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/amica_primitives.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../circle/models/guardian_alert.dart';
import '../models/app_notification.dart';
import '../services/notification_inbox_service.dart';

/// Every alert and update Amica has shown as a notification, kept in one
/// place: SOS alerts from people whose circle she is in, their journeys
/// starting and ending, replies to her own SOS, and new circle links.
///
/// Swipe a row away to remove it (with Undo), tap it to open what it is
/// about, and it is marked read.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationInboxService _inbox = NotificationInboxService.instance;
  bool _unreadOnly = false;

  @override
  void initState() {
    super.initState();
    _inbox.load();
  }

  Future<void> _open(AppNotification item) async {
    if (!item.read) _inbox.markRead(item.id);
    final alert = GuardianAlert.fromData(item.data);
    final navigator = Navigator.of(context);

    switch (item.type) {
      case 'sos':
        navigator.pushNamed(AppRoutes.guardianAlert, arguments: alert);
      case 'journey_started':
        final url = alert.liveUrl;
        if (url != null) {
          try {
            await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          } catch (_) {}
        } else {
          navigator.pushNamed(AppRoutes.guardianAlert, arguments: alert);
        }
      case 'guardian_linked':
        navigator.pushNamed(AppRoutes.emergencyContacts);
      default:
        break;
    }
  }

  Future<void> _remove(AppNotification item) async {
    await _inbox.remove(item.id);
    if (!mounted) return;
    final loc = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(loc.notificationsRemoved),
        action: SnackBarAction(
          label: loc.notificationsUndo,
          onPressed: () => _inbox.restore(item),
        ),
      ),
    );
  }

  Future<void> _confirmClear() async {
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.notificationsClearTitle),
        content: Text(loc.notificationsClearBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(loc.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(loc.notificationsClearAll),
          ),
        ],
      ),
    );
    if (confirmed == true) await _inbox.clear();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = theme.amica;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.notificationsTitle),
        actions: [
          ValueListenableBuilder<List<AppNotification>>(
            valueListenable: _inbox.items,
            builder: (context, items, _) {
              if (items.isEmpty) return const SizedBox.shrink();
              final hasUnread = items.any((n) => !n.read);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: loc.notificationsMarkAllRead,
                    icon: const Icon(Icons.done_all_rounded),
                    color: c.accentInk,
                    onPressed: hasUnread ? _inbox.markAllRead : null,
                  ),
                  IconButton(
                    tooltip: loc.notificationsClearAll,
                    icon: const Icon(Icons.delete_sweep_outlined),
                    color: c.accentInk,
                    onPressed: _confirmClear,
                  ),
                  const SizedBox(width: 4),
                ],
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ValueListenableBuilder<List<AppNotification>>(
          valueListenable: _inbox.items,
          builder: (context, all, _) {
            if (all.isEmpty) {
              return AmicaEmptyState(
                icon: Icons.notifications_none_rounded,
                title: loc.notificationsEmptyTitle,
                message: loc.notificationsEmptyMessage,
              );
            }

            final shown =
                _unreadOnly ? all.where((n) => !n.read).toList() : all;
            final localeName = Localizations.localeOf(context).toString();
            final groups = _groupByDay(shown, loc, localeName);

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              children: [
                Row(
                  children: [
                    _FilterPill(
                      label: loc.notificationsFilterAll,
                      selected: !_unreadOnly,
                      onTap: () => setState(() => _unreadOnly = false),
                    ),
                    const SizedBox(width: 8),
                    _FilterPill(
                      label: loc.notificationsFilterUnread,
                      selected: _unreadOnly,
                      onTap: () => setState(() => _unreadOnly = true),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (shown.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 48),
                    child: Center(
                      child: Text(
                        loc.notificationsUnreadEmpty,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                for (final group in groups) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 10),
                    child: SectionLabel(group.label),
                  ),
                  for (final item in group.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Dismissible(
                        key: ValueKey(item.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _remove(item),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 22),
                          decoration: BoxDecoration(
                            color: c.accentSoft,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            color: c.accentInk,
                          ),
                        ),
                        child: _NotificationCard(
                          item: item,
                          localeName: localeName,
                          onTap: () => _open(item),
                        ),
                      ),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  static List<_DayGroup> _groupByDay(
    List<AppNotification> items,
    AppLocalizations loc,
    String localeName,
  ) {
    final today = DateUtils.dateOnly(DateTime.now());
    final groups = <_DayGroup>[];
    for (final item in items) {
      final day = DateUtils.dateOnly(item.receivedAt);
      final age = today.difference(day).inDays;
      final label = age <= 0
          ? loc.commonToday
          : age == 1
              ? loc.commonYesterday
              : DateFormat.yMMMd(localeName).format(day);
      if (groups.isEmpty || groups.last.label != label) {
        groups.add(_DayGroup(label, []));
      }
      groups.last.items.add(item);
    }
    return groups;
  }
}

class _DayGroup {
  _DayGroup(this.label, this.items);

  final String label;
  final List<AppNotification> items;
}

/// Icon and tint per kind of notification. Rose is reserved for SOS.
(IconData, Color, Color) _look(AmicaColors c, String type) => switch (type) {
      'sos' => (Icons.warning_amber_rounded, c.blush, c.terracottaDeep),
      'journey_started' => (Icons.route_rounded, c.accentSoft, c.accentInk),
      'journey_arrived' => (Icons.check_circle_outline_rounded, c.sageSoft, c.sageInk),
      'guardian_response' => (Icons.reply_rounded, c.sky, c.skyInk),
      'guardian_linked' => (Icons.link_rounded, c.orchidSoft, c.orchidInk),
      _ => (Icons.notifications_none_rounded, c.accentSoft, c.accentInk),
    };

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.localeName,
    required this.onTap,
  });

  final AppNotification item;
  final String localeName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.amica;
    final (icon, tint, ink) = _look(c, item.type);
    final time = DateFormat.jm(localeName).format(item.receivedAt);

    return AmicaCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
      borderColor: item.read ? null : c.accent.withValues(alpha: 0.35),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: item.read ? FontWeight.w600 : FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: c.plum45,
                      ),
                    ),
                  ],
                ),
                if (item.body.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(item.body, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
          if (!item.read) ...[
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  gradient: c.accentGradient,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? null : c.card,
            gradient: selected ? c.accentGradient : null,
            borderRadius: BorderRadius.circular(999),
            border: selected ? null : Border.all(color: c.lineSoft),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.onAccent : c.plum70,
            ),
          ),
        ),
      ),
    );
  }
}
