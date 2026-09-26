import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/amica_primitives.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../models/journey.dart';
import '../services/journey_service.dart';
import '../widgets/journey_visuals.dart';

enum _HistoryFilter { all, safe, sos, other }

/// Her past journeys, newest first: where she went, when, how long it took
/// and how it ended. Tap one for the full details.
///
/// Read-only. A journey that is still running is not listed here — it is on
/// the Journeys tab.
class JourneyHistoryScreen extends StatefulWidget {
  const JourneyHistoryScreen({
    super.key,
    this.journeyService = const JourneyService(),
  });

  final JourneyService journeyService;

  @override
  State<JourneyHistoryScreen> createState() => _JourneyHistoryScreenState();
}

class _JourneyHistoryScreenState extends State<JourneyHistoryScreen> {
  late Stream<List<Journey>> _stream = widget.journeyService.watchJourneyHistory();
  _HistoryFilter _filter = _HistoryFilter.all;

  void _retry() => setState(() {
        _stream = widget.journeyService.watchJourneyHistory();
      });

  bool _matches(Journey journey) => switch (_filter) {
        _HistoryFilter.all => true,
        _HistoryFilter.safe => journey.status == 'safe',
        _HistoryFilter.sos => journey.status == 'sos',
        _HistoryFilter.other =>
          journey.status != 'safe' && journey.status != 'sos',
      };

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc.journeyHistoryTitle)),
      body: SafeArea(
        top: false,
        child: StreamBuilder<List<Journey>>(
          stream: _stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return AmicaEmptyState(
                icon: Icons.cloud_off_rounded,
                title: loc.journeyHistoryTitle,
                message: loc.journeyHistoryLoadFailed,
                action: PrimaryButton(
                  label: loc.journeyHistoryRetry,
                  icon: Icons.refresh_rounded,
                  onPressed: _retry,
                ),
              );
            }
            if (!snapshot.hasData) {
              return LoadingView(message: loc.journeysScreenCheckingJourneys);
            }

            final all = snapshot.data!;
            if (all.isEmpty) {
              return AmicaEmptyState(
                icon: Icons.route_rounded,
                title: loc.journeyHistoryEmptyTitle,
                message: loc.journeyHistoryEmptyMessage,
              );
            }

            final shown = all.where(_matches).toList();
            final localeName = Localizations.localeOf(context).toString();

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              children: [
                _SummaryCard(journeys: all),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final f in _HistoryFilter.values) ...[
                        _FilterPill(
                          label: switch (f) {
                            _HistoryFilter.all => loc.journeyHistoryFilterAll,
                            _HistoryFilter.safe => loc.journeyHistoryFilterSafe,
                            _HistoryFilter.sos => loc.journeyHistoryFilterSos,
                            _HistoryFilter.other => loc.journeyHistoryFilterOther,
                          },
                          selected: _filter == f,
                          onTap: () => setState(() => _filter = f),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (shown.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text(
                        loc.journeyHistoryFilterEmpty,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ..._buildGroups(context, shown, localeName),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildGroups(
    BuildContext context,
    List<Journey> journeys,
    String localeName,
  ) {
    final widgets = <Widget>[];
    String? currentMonth;
    for (final journey in journeys) {
      final month = DateFormat.yMMMM(localeName).format(journey.createdAt);
      if (month != currentMonth) {
        currentMonth = month;
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 10),
          child: SectionLabel(month),
        ));
      }
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _JourneyCard(
          journey: journey,
          localeName: localeName,
          onTap: () => _showDetails(journey, localeName),
        ),
      ));
    }
    return widgets;
  }

  void _showDetails(Journey journey, String localeName) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _JourneyDetailSheet(journey: journey, localeName: localeName),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

String _typeLabel(AppLocalizations loc, String type) => switch (type) {
      'walk' => loc.startJourneyTypeWalk,
      'taxi' => loc.startJourneyTypeTaxi,
      'bus' => loc.startJourneyTypeBus,
      'train' => loc.startJourneyTypeTrain,
      _ => loc.startJourneyTypeOther,
    };

String _statusLabel(AppLocalizations loc, String status) => switch (status) {
      'safe' => loc.journeyStatusSafe,
      'sos' => loc.journeyStatusSos,
      'cancelled' => loc.journeyStatusCancelled,
      'expired' => loc.journeyStatusExpired,
      _ => loc.journeyStatusActive,
    };

/// Rose is for SOS only; a timed-out journey is a caution, not an emergency.
PillTone _statusTone(String status) => switch (status) {
      'safe' => PillTone.sage,
      'sos' => PillTone.blush,
      'expired' => PillTone.gold,
      'cancelled' => PillTone.quiet,
      _ => PillTone.accent,
    };

(Color, Color) _statusChip(AmicaColors c, String status) => switch (status) {
      'safe' => (c.sageSoft, c.sageInk),
      'sos' => (c.blush, c.terracottaDeep),
      'expired' => (c.goldSoft, c.gold),
      _ => (c.accentSoft, c.accentInk),
    };

/// How long the journey actually took, or null when it has no end time.
Duration? _actualDuration(Journey journey) {
  final end = journey.actualEndTime;
  if (end == null) return null;
  final d = end.difference(journey.createdAt);
  return d.isNegative ? null : d;
}

String _formatDuration(AppLocalizations loc, Duration d) {
  final minutes = d.inMinutes < 1 ? 1 : d.inMinutes;
  if (minutes < 60) return loc.journeyHistoryMinutes(minutes);
  return loc.journeyHistoryHoursMinutes(minutes ~/ 60, minutes % 60);
}

// ---------------------------------------------------------------------------
// Widgets
// ---------------------------------------------------------------------------

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.journeys});

  final List<Journey> journeys;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final loc = AppLocalizations.of(context);
    final safe = journeys.where((j) => j.status == 'safe').length;
    final sos = journeys.where((j) => j.status == 'sos').length;

    Widget stat(String value, String label, Color ink) => Expanded(
          child: Column(
            children: [
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: ink, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: c.plum70,
                ),
              ),
            ],
          ),
        );

    return AmicaCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      borderRadius: 28,
      child: Row(
        children: [
          stat('${journeys.length}', loc.journeyHistoryStatJourneys, c.accentInk),
          Container(width: 1, height: 34, color: c.lineSoft),
          stat('$safe', loc.journeyStatusSafe, c.sageInk),
          Container(width: 1, height: 34, color: c.lineSoft),
          stat('$sos', loc.journeyHistoryFilterSos, c.terracottaDeep),
        ],
      ),
    );
  }
}

class _JourneyCard extends StatelessWidget {
  const _JourneyCard({
    required this.journey,
    required this.localeName,
    required this.onTap,
  });

  final Journey journey;
  final String localeName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.amica;
    final loc = AppLocalizations.of(context);
    final (tint, ink) = _statusChip(c, journey.status);
    final when = DateFormat.MMMd(localeName).add_jm().format(journey.createdAt);
    final duration = _actualDuration(journey);

    return AmicaCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            child: Icon(journeyTypeIcon(journey.journeyType), size: 21, color: ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  journey.destinationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  duration == null
                      ? '$when · ${_typeLabel(loc, journey.journeyType)}'
                      : '$when · ${_formatDuration(loc, duration)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                StatusPill(
                  label: _statusLabel(loc, journey.status),
                  tone: _statusTone(journey.status),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 20, color: c.plum45),
        ],
      ),
    );
  }
}

class _JourneyDetailSheet extends StatelessWidget {
  const _JourneyDetailSheet({required this.journey, required this.localeName});

  final Journey journey;
  final String localeName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.amica;
    final loc = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final (tint, ink) = _statusChip(c, journey.status);
    final fmt = DateFormat.yMMMd(localeName).add_jm();
    final duration = _actualDuration(journey);

    final startAddress = journey.startLocation?.address.trim() ?? '';
    final destAddress = (journey.destination['address'] is String
            ? journey.destination['address'] as String
            : '')
        .trim();
    final plate = journey.metadata['vehiclePlate'];

    final rows = <(String, String)>[
      (
        loc.journeyDetailFrom,
        startAddress.isEmpty ? loc.journeyDetailStartFallback : startAddress
      ),
      (
        loc.journeyDetailTo,
        destAddress.isEmpty ? journey.destinationName : destAddress
      ),
      (loc.journeyDetailStarted, fmt.format(journey.createdAt)),
      if (journey.actualEndTime != null)
        (loc.journeyDetailEnded, fmt.format(journey.actualEndTime!)),
      if (duration != null)
        (loc.journeyDetailDuration, _formatDuration(loc, duration)),
      if (!journey.isStopAlertRide && journey.estimatedDurationMinutes > 0)
        (
          loc.journeyDetailPlanned,
          loc.journeyHistoryMinutes(journey.estimatedDurationMinutes)
        ),
      if (plate is String && plate.isNotEmpty) (loc.journeyDetailVehicle, plate),
    ];

    // The same tinted surface as the live journey sheet.
    final sheetColor = Color.alphaBlend(
      c.accentSoft.withValues(alpha: isDark ? 0.7 : 0.8),
      c.card,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: sheetColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: c.glassBorder, width: 1.2),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    gradient: c.accentGradient,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
                    child: Icon(
                      journeyTypeIcon(journey.journeyType),
                      size: 23,
                      color: ink,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          journey.destinationName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            StatusPill(
                              label: _statusLabel(loc, journey.status),
                              tone: _statusTone(journey.status),
                            ),
                            StatusPill(
                              label: _typeLabel(loc, journey.journeyType),
                              tone: PillTone.quiet,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              AmicaCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  children: [
                    for (var i = 0; i < rows.length; i++) ...[
                      if (i > 0) const AmicaDivider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 92,
                              child: Text(
                                rows[i].$1,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: c.plum45,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                rows[i].$2,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
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
