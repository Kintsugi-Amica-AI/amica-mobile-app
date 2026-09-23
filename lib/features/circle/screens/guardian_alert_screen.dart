import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/amica_map_view.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../services/push_notification_service.dart';
import '../models/guardian_alert.dart';
import '../services/guardian_link_service.dart';

/// What a guardian sees after tapping an SOS push: who, where, and the
/// replies that tell her help is coming.
///
/// Everything comes from the push payload; nothing here reads her data.
class GuardianAlertScreen extends StatefulWidget {
  const GuardianAlertScreen({super.key, required this.alert});

  final GuardianAlert alert;

  @override
  State<GuardianAlertScreen> createState() => _GuardianAlertScreenState();
}

class _GuardianAlertScreenState extends State<GuardianAlertScreen> {
  final Set<GuardianResponse> _sent = {};
  GuardianResponse? _sending;
  late final Timer _clock;

  @override
  void initState() {
    super.initState();
    // Keeps "2 min ago" current.
    _clock = Timer.periodic(
      const Duration(seconds: 30),
      (_) => mounted ? setState(() {}) : null,
    );
  }

  @override
  void dispose() {
    _clock.cancel();
    super.dispose();
  }

  GuardianAlert get _alert => widget.alert;

  Future<void> _reply(GuardianResponse response) async {
    if (_sending != null) return;
    setState(() => _sending = response);
    final bool ok;
    if (response == GuardianResponse.calling) {
      // Marks the reply and opens the dialler in one step.
      await PushNotificationService.instance.callingNow(_alert);
      ok = true;
    } else {
      ok = await PushNotificationService.instance.respond(_alert, response);
    }
    if (!mounted) return;
    setState(() {
      _sending = null;
      if (ok) _sent.add(response);
    });
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).guardianReplyFailed)),
      );
    }
  }

  Future<void> _open(String? url) async {
    if (url == null) return;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  String _ago(AppLocalizations loc, DateTime? at) {
    if (at == null) return '';
    final minutes = DateTime.now().difference(at).inMinutes;
    return minutes < 1 ? loc.guardianAlertJustNow : loc.guardianAlertMinutesAgo(minutes);
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final name =
        _alert.ownerName.isEmpty ? loc.pushSomeone : _alert.ownerName;
    final lat = _alert.latitude;
    final lng = _alert.longitude;

    return Scaffold(
      appBar: AppBar(title: Text(loc.guardianAlertAppBar)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            AmicaCard(
              color: _alert.isSos ? c.blush : null,
              borderColor: _alert.isSos ? c.terracotta.withValues(alpha: 0.4) : null,
              child: Row(
                children: [
                  Icon(
                    _alert.isSos ? Icons.sos_rounded : Icons.route_rounded,
                    color: _alert.isSos ? c.terracottaDeep : c.accentInk,
                    size: 34,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _alert.isSos
                              ? loc.pushSosTitle(name)
                              : loc.pushJourneyStartedTitle(name),
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _ago(loc, _alert.receivedAt),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (lat != null && lng != null) ...[
              const SizedBox(height: 14),
              AmicaMapView(
                latitude: lat,
                longitude: lng,
                height: 220,
                markerTitle: loc.guardianAlertHerLocation(name),
              ),
            ],
            const SizedBox(height: 14),
            if (_alert.liveUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: PrimaryButton(
                  label: loc.guardianAlertWatchLive,
                  icon: Icons.podcasts_rounded,
                  tone: _alert.isSos ? AmicaButtonTone.quiet : AmicaButtonTone.primary,
                  onPressed: () => _open(_alert.liveUrl),
                ),
              ),
            if (_alert.mapsUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: PrimaryButton(
                  label: loc.guardianAlertOpenMaps,
                  icon: Icons.map_outlined,
                  tone: AmicaButtonTone.quiet,
                  height: 48,
                  onPressed: () => _open(_alert.mapsUrl),
                ),
              ),
            if (_alert.isSos) ...[
              const SizedBox(height: 8),
              Text(loc.guardianAlertLetHerKnow, style: theme.textTheme.titleSmall),
              const SizedBox(height: 10),
              PrimaryButton(
                label: _sent.contains(GuardianResponse.calling)
                    ? loc.guardianAlertCallingSent(name)
                    : _alert.ownerPhone.isEmpty
                        ? loc.pushActionCallingNow
                        : loc.guardianAlertCallHer(name),
                icon: Icons.phone_in_talk_rounded,
                tone: AmicaButtonTone.danger,
                isBusy: _sending == GuardianResponse.calling,
                onPressed: () => _reply(GuardianResponse.calling),
              ),
              const SizedBox(height: 10),
              PrimaryButton(
                label: _sent.contains(GuardianResponse.alertedOthers)
                    ? loc.guardianAlertAlertedSent
                    : loc.pushActionAlertedOthers,
                icon: _sent.contains(GuardianResponse.alertedOthers)
                    ? Icons.check_circle_rounded
                    : Icons.campaign_outlined,
                tone: AmicaButtonTone.quiet,
                isBusy: _sending == GuardianResponse.alertedOthers,
                onPressed: _sent.contains(GuardianResponse.alertedOthers)
                    ? null
                    : () => _reply(GuardianResponse.alertedOthers),
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                label: loc.sosActiveCall119,
                icon: Icons.local_police_outlined,
                tone: AmicaButtonTone.quiet,
                height: 48,
                onPressed: () => launchUrl(Uri(scheme: 'tel', path: '119')),
              ),
              const SizedBox(height: 12),
              Text(
                loc.guardianAlertRepliesNote(name),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
