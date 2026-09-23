import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/amica_map_view.dart';
import '../../../core/widgets/amica_primitives.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../emergency_contacts/models/emergency_contact.dart';
import '../../emergency_contacts/services/emergency_contact_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../services/circle_alert_service.dart';
import '../../journey/models/location_data_model.dart';

class SosActiveArguments {
  const SosActiveArguments({
    required this.alertId,
    required this.triggerType,
    required this.location,
    this.message,
    this.status = 'active',
    this.notifyCircle = true,
    this.liveUrl,
  });

  /// The journey's watch-live link, when the SOS came from a shared journey.
  final String? liveUrl;

  /// Text every active guardian from this screen as soon as it opens.
  final bool notifyCircle;

  final String alertId;
  final String triggerType;
  final LocationDataModel location;
  final String? message;
  final String status;
}

/// What she sees once the alert is out.
///
/// The old screen showed an alert ID, a trigger type and a status string —
/// database fields. None of that answers the question she actually has,
/// which is *did it work, and who knows*. So this screen leads with the
/// live state, then the people reached, then exactly what the phone is
/// doing on her behalf, and finally the one action that ends it.
class SosActiveScreen extends StatefulWidget {
  const SosActiveScreen({
    super.key,
    this.arguments,
    this.contactService = const EmergencyContactService(),
    this.circleAlertService = const CircleAlertService(),
  });

  final SosActiveArguments? arguments;
  final EmergencyContactService contactService;
  final CircleAlertService circleAlertService;

  @override
  State<SosActiveScreen> createState() => _SosActiveScreenState();
}

class _SosActiveScreenState extends State<SosActiveScreen> {
  late final Timer _clock;
  final Stopwatch _elapsed = Stopwatch()..start();
  bool _sirenOn = false;

  // Who the SOS text reached, per guardian — shown honestly, as it happens.
  List<EmergencyContact>? _guardians;
  final Map<String, CircleDeliveryResult> _deliveries = {};
  bool _loadingCircle = false;
  bool _sendingToCircle = false;
  bool _circleLoadFailed = false;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(
      const Duration(seconds: 1),
      (_) => mounted ? setState(() {}) : null,
    );
    if (widget.arguments?.notifyCircle ?? false) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _alertCircle());
    }
  }

  String _composeMessage(AppLocalizations loc) {
    final args = widget.arguments;
    final text = args?.message?.trim().isNotEmpty == true
        ? args!.message!.trim()
        : loc.sosSmsDefaultMessage;
    final link = args == null
        ? ''
        : CircleAlertService.mapsLink(
            args.location.latitude,
            args.location.longitude,
          );
    final name = FirebaseAuth.instance.currentUser?.displayName?.trim() ?? '';
    final base = name.isEmpty
        ? loc.sosSmsNoName(text, link)
        : loc.sosSmsWithName(name, text, link);
    final liveUrl = args?.liveUrl;
    return liveUrl == null ? base : '$base ${loc.liveShareEmergencyLine(liveUrl)}';
  }

  /// Texts every active guardian — or, with [only], just those — and keeps
  /// the per-person status on screen up to date.
  Future<void> _alertCircle({List<EmergencyContact>? only}) async {
    if (_sendingToCircle || !mounted) return;
    final loc = AppLocalizations.of(context);
    final message = _composeMessage(loc);

    var guardians = only ?? _guardians;
    if (guardians == null) {
      setState(() {
        _loadingCircle = true;
        _circleLoadFailed = false;
      });
      try {
        guardians = await widget.circleAlertService.activeGuardians();
      } catch (_) {
        if (mounted) {
          setState(() {
            _loadingCircle = false;
            _circleLoadFailed = true;
          });
        }
        return;
      }
      if (!mounted) return;
      setState(() {
        _guardians = guardians;
        _loadingCircle = false;
      });
    }

    final targets = guardians;
    if (targets.isEmpty) return;
    setState(() {
      _sendingToCircle = true;
      for (final g in targets) {
        _deliveries[g.id] = CircleDeliveryResult(
          contact: g,
          delivery: CircleDelivery.sending,
        );
      }
    });

    await widget.circleAlertService.sendToCircle(
      guardians: targets,
      message: message,
      alertId: widget.arguments?.alertId,
      onUpdate: (result) {
        if (mounted) setState(() => _deliveries[result.contact.id] = result);
      },
    );
    if (mounted) setState(() => _sendingToCircle = false);
  }

  /// If SMS could not be sent from Amica (no permission, no balance), open
  /// the phone's own messages app with everything filled in.
  Future<void> _openSmsApp() async {
    final loc = AppLocalizations.of(context);
    final guardians = _guardians ?? const <EmergencyContact>[];
    final uri = Uri(
      scheme: 'sms',
      path: guardians.map((g) => g.phone.replaceAll(' ', '')).join(','),
      queryParameters: {'body': _composeMessage(loc)},
    );
    try {
      await launchUrl(uri);
    } catch (_) {/* Nothing more we can do from here. */}
  }

  @override
  void dispose() {
    _clock.cancel();
    super.dispose();
  }

  String get _elapsedLabel {
    final total = _elapsed.elapsed;
    final m = total.inMinutes.toString().padLeft(2, '0');
    final s = (total.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _triggerLabel(AppLocalizations loc, String? triggerType) {
    return switch (triggerType) {
      'voice' => loc.sosActiveTriggerVoice,
      'timer' => loc.sosActiveTriggerTimer,
      _ => loc.sosActiveTriggerManual,
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final args = widget.arguments;

    return Scaffold(
      body: Column(
        children: [
          _LiveStrip(elapsed: _elapsedLabel),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (args?.location != null)
                  _LocationBlock(location: args!.location),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _triggerLabel(loc, args?.triggerType),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: c.plum45),
                      ),
                      const SizedBox(height: 18),
                      _CircleStatus(
                        guardians: _guardians,
                        deliveries: _deliveries,
                        loading: _loadingCircle,
                        loadFailed: _circleLoadFailed,
                        sending: _sendingToCircle,
                        onRetry: () => _alertCircle(
                          only: [
                            for (final r in _deliveries.values)
                              if (r.delivery == CircleDelivery.failed ||
                                  r.delivery == CircleDelivery.unconfirmed)
                                r.contact,
                          ],
                        ),
                        onReload: () => _alertCircle(),
                        onOpenSmsApp: _openSmsApp,
                      ),
                      if (args != null && args.alertId.isNotEmpty)
                        _GuardianReplies(alertId: args.alertId),
                      const SizedBox(height: 22),
                      SectionLabel(loc.sosActiveWhatAmicaIsDoing),
                      const SizedBox(height: 10),
                      AmicaCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        child: Column(
                          children: [
                            _DoingRow(
                              icon: Icons.location_on_outlined,
                              label: loc.sosActiveSharingLocation,
                              on: true,
                            ),
                            const AmicaDivider(),
                            _DoingRow(
                              icon: Icons.mic_none_rounded,
                              label: loc.sosActiveRecordingAudio,
                              on: true,
                            ),
                            const AmicaDivider(),
                            _DoingRow(
                              icon: Icons.volume_up_outlined,
                              label: _sirenOn
                                  ? loc.sosActiveSirenSounding
                                  : loc.sosActiveSirenSilent,
                              on: _sirenOn,
                              onTap: () =>
                                  setState(() => _sirenOn = !_sirenOn),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: loc.sosActiveImSafe,
                        icon: Icons.check_circle_outline_rounded,
                        tone: AmicaButtonTone.safe,
                        onPressed: () => _standDown(context),
                      ),
                      const SizedBox(height: 10),
                      PrimaryButton(
                        label: loc.sosActiveCall119,
                        icon: Icons.phone_outlined,
                        tone: AmicaButtonTone.quiet,
                        height: 48,
                        // Opens the dialler with 119 filled in; she presses
                        // call herself.
                        onPressed: () => launchUrl(Uri(scheme: 'tel', path: '119')),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          loc.sosActiveStandDownNote,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: c.plum45,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _standDown(BuildContext context) async {
    final c = Theme.of(context).amica;
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.sosActiveConfirmTitle),
        content: Text(loc.sosActiveConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(loc.sosActiveKeepLive),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: c.sage),
            child: Text(loc.sosActiveYesImSafe),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
    }
  }
}

/// A band that cannot be scrolled away: while an alert is live, the fact
/// that it is live is never more than a glance away.
class _LiveStrip extends StatelessWidget {
  const _LiveStrip({required this.elapsed});

  final String elapsed;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;

    return Container(
      color: c.terracotta,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 44,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.onTerracotta,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 9),
                Text(
                  AppLocalizations.of(context).sosActiveLive,
                  style: const TextStyle(
                    color: AppColors.onTerracotta,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.95,
                  ),
                ),
                const Spacer(),
                Text(
                  elapsed,
                  style: const TextStyle(
                    color: AppColors.onTerracotta,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationBlock extends StatelessWidget {
  const _LocationBlock({required this.location});

  final LocationDataModel location;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;

    return SizedBox(
      height: 248,
      child: Stack(
        children: [
          Positioned.fill(
            child: AmicaMapView(
              latitude: location.latitude,
              longitude: location.longitude,
              markerTitle: AppLocalizations.of(context).sosActiveYourLocation,
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(14),
                boxShadow: c.shadow,
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 17, color: c.terracotta),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          location.address.trim().isNotEmpty
                              ? location.address
                              : '${location.latitude.toStringAsFixed(5)}, '
                                  '${location.longitude.toStringAsFixed(5)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: c.plum,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context).sosActiveUpdatingEvery10s,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: c.plum45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Who the SOS text reached — per guardian, as it happens, never assumed.
class _CircleStatus extends StatelessWidget {
  const _CircleStatus({
    required this.guardians,
    required this.deliveries,
    required this.loading,
    required this.loadFailed,
    required this.sending,
    required this.onRetry,
    required this.onReload,
    required this.onOpenSmsApp,
  });

  final List<EmergencyContact>? guardians;
  final Map<String, CircleDeliveryResult> deliveries;
  final bool loading;
  final bool loadFailed;
  final bool sending;
  final VoidCallback onRetry;
  final VoidCallback onReload;
  final VoidCallback onOpenSmsApp;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final loc = AppLocalizations.of(context);
    final list = guardians;

    if (loading || (list == null && !loadFailed)) {
      return AmicaCard(
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(loc.sosCircleSending)),
          ],
        ),
      );
    }

    if (loadFailed || list == null) {
      return _Notice(
        color: c.gold,
        icon: Icons.cloud_off_rounded,
        text: loc.sosCircleLoadFailed,
        actionLabel: loc.sosCircleTryAgain,
        onAction: onReload,
      );
    }

    if (list.isEmpty) {
      return _Notice(
        color: c.gold,
        icon: Icons.error_outline_rounded,
        text: loc.sosActiveNoOneInCircle,
      );
    }

    final results = [for (final g in list) deliveries[g.id]];
    final reached = results.where((r) => r?.reached ?? false).length;
    final problems = results.any(
      (r) =>
          r != null &&
          (r.delivery == CircleDelivery.failed ||
              r.delivery == CircleDelivery.unconfirmed),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(
          sending
              ? loc.sosCircleSending
              : loc.sosCircleReachedCount(reached, list.length),
        ),
        const SizedBox(height: 10),
        AmicaCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < list.length; i++) ...[
                if (i > 0) const AmicaDivider(),
                _GuardianRow(
                  contact: list[i],
                  result: deliveries[list[i].id],
                ),
              ],
            ],
          ),
        ),
        if (!sending && problems) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: loc.sosCircleTryAgain,
                  icon: Icons.refresh_rounded,
                  tone: AmicaButtonTone.danger,
                  height: 46,
                  onPressed: onRetry,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PrimaryButton(
                  label: loc.sosCircleOpenSmsApp,
                  icon: Icons.sms_outlined,
                  tone: AmicaButtonTone.quiet,
                  height: 46,
                  onPressed: onOpenSmsApp,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _GuardianRow extends StatelessWidget {
  const _GuardianRow({required this.contact, required this.result});

  final EmergencyContact contact;
  final CircleDeliveryResult? result;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final loc = AppLocalizations.of(context);
    final delivery = result?.delivery ?? CircleDelivery.sending;

    final (String label, Color color, IconData icon) = switch (delivery) {
      CircleDelivery.sending => (
          loc.sosCircleStatusSending,
          c.plum45,
          Icons.schedule_rounded,
        ),
      CircleDelivery.sent => (
          loc.sosCircleStatusSent,
          c.sage,
          Icons.check_circle_rounded,
        ),
      CircleDelivery.unconfirmed => (
          loc.sosCircleStatusUnconfirmed,
          c.gold,
          Icons.help_outline_rounded,
        ),
      CircleDelivery.failed => (
          loc.sosCircleStatusFailed,
          c.terracottaDeep,
          Icons.error_outline_rounded,
        ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          AmicaAvatar(initial: contact.name, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: c.plum,
                  ),
                ),
                Text(
                  result?.error ?? contact.phone,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: result?.error != null ? c.terracottaDeep : c.plum45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (delivery == CircleDelivery.sending)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.color,
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final Color color;
  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    return AmicaCard(
      borderColor: color,
      child: Row(
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: c.plum,
                height: 1.4,
              ),
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class _DoingRow extends StatelessWidget {
  const _DoingRow({
    required this.icon,
    required this.label,
    required this.on,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool on;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 18, color: on ? c.sage : c.plum45),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: c.plum70,
                ),
              ),
            ),
            Text(
              on
                  ? AppLocalizations.of(context).sosActiveOn
                  : AppLocalizations.of(context).sosActiveOff,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: on ? c.sage : c.plum45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Replies from guardians who have Amica ("Calling you now", "Alerted
/// others"), live from the alert record, plus how many got the push.
class _GuardianReplies extends StatelessWidget {
  const _GuardianReplies({required this.alertId});

  final String alertId;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final loc = AppLocalizations.of(context);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('sos_alerts')
          .doc(alertId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        if (data == null) return const SizedBox.shrink();

        final push = data['push'];
        final pushed = push is Map ? push['reachedContactIds'] : null;
        final pushedCount = pushed is List ? pushed.length : 0;
        final replies = <Map<String, dynamic>>[
          if (data['guardianResponses'] is Map)
            for (final value in (data['guardianResponses'] as Map).values)
              if (value is Map) Map<String, dynamic>.from(value),
        ]..sort((a, b) => '${b['at']}'.compareTo('${a['at']}'));

        if (pushedCount == 0 && replies.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(top: 14),
          child: AmicaCard(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            borderColor:
                replies.isNotEmpty ? c.sage.withValues(alpha: 0.45) : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pushedCount > 0)
                  Row(
                    children: [
                      Icon(Icons.notifications_active_outlined,
                          size: 17, color: c.accentInk),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          loc.sosActivePushedCount(pushedCount),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: c.plum70,
                          ),
                        ),
                      ),
                    ],
                  ),
                for (final reply in replies) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        reply['response'] == 'calling'
                            ? Icons.phone_in_talk_rounded
                            : Icons.campaign_rounded,
                        size: 18,
                        color: c.sage,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reply['response'] == 'calling'
                              ? loc.pushResponseCallingTitle(
                                  '${reply['name'] ?? ''}'.isEmpty
                                      ? loc.pushYourContact
                                      : '${reply['name']}')
                              : loc.pushResponseAlertedTitle(
                                  '${reply['name'] ?? ''}'.isEmpty
                                      ? loc.pushYourContact
                                      : '${reply['name']}'),
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: c.plum,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
