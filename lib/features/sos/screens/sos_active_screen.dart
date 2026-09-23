import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/amica_map_view.dart';
import '../../../core/widgets/amica_primitives.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../emergency_contacts/models/emergency_contact.dart';
import '../../emergency_contacts/services/emergency_contact_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../journey/models/location_data_model.dart';

class SosActiveArguments {
  const SosActiveArguments({
    required this.alertId,
    required this.triggerType,
    required this.location,
    this.message,
    this.status = 'active',
  });

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
  });

  final SosActiveArguments? arguments;
  final EmergencyContactService contactService;

  @override
  State<SosActiveScreen> createState() => _SosActiveScreenState();
}

class _SosActiveScreenState extends State<SosActiveScreen> {
  late final Timer _clock;
  final Stopwatch _elapsed = Stopwatch()..start();
  bool _sirenOn = false;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(
      const Duration(seconds: 1),
      (_) => mounted ? setState(() {}) : null,
    );
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
      backgroundColor: c.ivory,
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
                      _CircleReached(service: widget.contactService),
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
                        onPressed: () {},
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
                  style: TextStyle(
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

class _CircleReached extends StatelessWidget {
  const _CircleReached({required this.service});

  final EmergencyContactService service;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final loc = AppLocalizations.of(context);

    return StreamBuilder<List<EmergencyContact>>(
      stream: service.watchEmergencyContacts(),
      builder: (context, snapshot) {
        final guardians =
            (snapshot.data ?? []).where((g) => g.isActive).toList();

        if (guardians.isEmpty) {
          return AmicaCard(
            borderColor: c.gold,
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, size: 19, color: c.gold),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    loc.sosActiveNoOneInCircle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: c.plum,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionLabel(loc.sosActiveCircleReachedHeader(guardians.length)),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final g in guardians.take(4)) ...[
                  Expanded(
                    child: Column(
                      children: [
                        AmicaAvatar(
                          initial: g.name,
                          size: 42,
                          background: c.blush,
                          foreground: c.terracottaDeep,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          g.name.split(RegExp(r'\s+')).first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: c.plum,
                          ),
                        ),
                        Text(
                          loc.sosActiveNotified,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                            color: c.sage,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      },
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
