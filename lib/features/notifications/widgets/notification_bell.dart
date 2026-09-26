import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../services/notification_inbox_service.dart';

/// The bell in Home's header: opens the Notifications screen, and carries a
/// small dot while anything in it is unread.
///
/// The dot is the brand accent, never rose — rose-red means emergency only.
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell>
    with WidgetsBindingObserver {
  final NotificationInboxService _inbox = NotificationInboxService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _inbox.load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // A push may have been recorded by the background isolate meanwhile.
    if (state == AppLifecycleState.resumed) _inbox.load();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final loc = AppLocalizations.of(context);

    return ValueListenableBuilder<int>(
      valueListenable: _inbox.unreadCount,
      builder: (context, unread, _) => Semantics(
        button: true,
        label: loc.notificationsOpen,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
          borderRadius: BorderRadius.circular(999),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.lineSoft),
                  boxShadow: c.shadow,
                ),
                child: Icon(
                  unread > 0
                      ? Icons.notifications_rounded
                      : Icons.notifications_none_rounded,
                  size: 20,
                  color: c.accentInk,
                ),
              ),
              if (unread > 0)
                Positioned(
                  top: 1,
                  right: 1,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      gradient: c.accentGradient,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.card, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
