import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/amica_map_view.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../services/journey_route_service.dart';
import '../../../services/transit_plan_service.dart';
import 'journey_visuals.dart';

/// Map drawing for a trip: dotted walks, solid ride.
List<MapRouteLeg> mapLegsFor(TransitPlan plan) => [
      for (final leg in plan.legs)
        MapRouteLeg(points: leg.points, walking: leg.isWalk),
    ];

/// Stop markers for a trip. With [withCandidates], nearby alternatives are
/// shown too so the rider can tap one to choose it instead.
List<MapTransitStop> mapStopsFor(
  TransitPlan plan, {
  bool withCandidates = false,
}) {
  final chosen = {plan.boardStop.id, plan.alightStop.id};
  return [
    MapTransitStop(
      id: plan.boardStop.id,
      name: plan.boardStop.name,
      position: plan.boardStop.position,
      role: MapStopRole.board,
      train: plan.isTrain,
    ),
    MapTransitStop(
      id: plan.alightStop.id,
      name: plan.alightStop.name,
      position: plan.alightStop.position,
      role: MapStopRole.alight,
      train: plan.isTrain,
    ),
    if (withCandidates)
      for (final stop in {
        for (final s in [...plan.boardCandidates, ...plan.alightCandidates])
          s.id: s,
      }.values)
        if (!chosen.contains(stop.id))
          MapTransitStop(
            id: stop.id,
            name: stop.name,
            position: stop.position,
            role: MapStopRole.candidate,
            train: plan.isTrain,
          ),
  ];
}

String _minutes(AppLocalizations loc, int seconds) =>
    loc.tripMinutes((seconds / 60).ceil().clamp(1, 999).toInt());

/// "Your bus trip": walk to the stop → get on → get off → walk on, as a
/// small timeline, with chips to pick a different stop at either end.
class TransitTripCard extends StatelessWidget {
  const TransitTripCard({
    required this.mode,
    super.key,
    this.plan,
    this.isLoading = false,
    this.unavailable,
    this.onChooseBoard,
    this.onChooseAlight,
  });

  /// `bus` or `train`.
  final String mode;
  final TransitPlan? plan;
  final bool isLoading;
  final TransitPlanUnavailable? unavailable;

  /// Null hides the "choose a different stop" chips (e.g. on a live trip).
  final ValueChanged<TransitStop>? onChooseBoard;
  final ValueChanged<TransitStop>? onChooseAlight;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = theme.amica;
    final plan = this.plan;
    final train = mode == 'train';

    Widget body;
    if (plan == null) {
      body = Row(
        children: [
          if (isLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(Icons.info_outline_rounded, size: 18, color: c.plum45),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isLoading
                  ? loc.tripPlanning
                  : switch (unavailable) {
                      TransitPlanUnavailable.tooClose => loc.tripTooClose,
                      TransitPlanUnavailable.noStops => loc.tripNoStops,
                      _ => loc.tripOffline,
                    },
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      );
    } else {
      final ride = plan.legs.firstWhere(
        (l) => !l.isWalk,
        orElse: () => plan.legs.first,
      );
      final lineLabel = ride.lineName.isEmpty
          ? null
          : (train ? loc.tripTrainLine(ride.lineName) : loc.tripBusLine(ride.lineName));
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (plan.walkToStopMeters > 0)
            _Step(
              icon: Icons.directions_walk_rounded,
              title: loc.tripWalkToStop(
                formatDistance(plan.walkToStopMeters),
                plan.boardStop.name,
              ),
              trailing: _minutes(loc, plan.legs.first.durationSeconds),
              dotted: true,
            ),
          _Step(
            icon: train ? Icons.train_rounded : Icons.directions_bus_rounded,
            title: loc.tripGetOnAt(plan.boardStop.name),
            subtitle: lineLabel,
            highlight: true,
          ),
          _Step(
            icon: Icons.flag_rounded,
            title: loc.tripGetOffAt(plan.alightStop.name),
            subtitle: loc.tripRideSummary(
              formatDistance(ride.distanceMeters),
              (ride.durationSeconds / 60).ceil(),
            ),
            highlight: true,
            dotted: plan.walkFromStopMeters > 0,
          ),
          if (plan.walkFromStopMeters > 0)
            _Step(
              icon: Icons.directions_walk_rounded,
              title: loc.tripWalkToDestination(
                formatDistance(plan.walkFromStopMeters),
              ),
              trailing: _minutes(loc, plan.legs.last.durationSeconds),
              last: true,
            ),
          if (plan.isEstimated) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome_rounded, size: 14, color: c.gold),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    loc.tripEstimated,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ],
          if (onChooseBoard != null && plan.boardCandidates.length > 1) ...[
            const SizedBox(height: 12),
            _StopChoices(
              label: loc.tripChooseBoard,
              stops: plan.boardCandidates,
              selectedId: plan.boardStop.id,
              onSelected: onChooseBoard!,
            ),
          ],
          if (onChooseAlight != null && plan.alightCandidates.length > 1) ...[
            const SizedBox(height: 10),
            _StopChoices(
              label: loc.tripChooseAlight,
              stops: plan.alightCandidates,
              selectedId: plan.alightStop.id,
              onSelected: onChooseAlight!,
            ),
          ],
        ],
      );
    }

    return AmicaCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GradientIconBadge(
                icon: train ? Icons.train_rounded : Icons.directions_bus_rounded,
                size: 34,
                soft: true,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  train ? loc.tripTitleTrain : loc.tripTitleBus,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              if (plan != null)
                InfoPill(
                  icon: Icons.schedule_rounded,
                  label: _minutes(loc, plan.durationSeconds),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // The timeline grows smoothly out of the "finding stops…" line
          // instead of popping in.
          AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: KeyedSubtree(
                key: ValueKey(plan == null
                    ? 'status-$isLoading-$unavailable'
                    : '${plan.boardStop.id}-${plan.alightStop.id}'),
                child: body,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One timeline row: icon on the rail, text beside it.
class _Step extends StatelessWidget {
  const _Step({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.highlight = false,
    this.dotted = false,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailing;
  final bool highlight;

  /// Whether the rail below this step is dotted (a walk follows).
  final bool dotted;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.amica;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: highlight ? c.accentGradient : null,
                    color: highlight ? null : c.accentSoft,
                  ),
                  child: Icon(
                    icon,
                    size: 15,
                    color: highlight ? AppColors.onAccent : c.accentInk,
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: dotted
                          ? CustomPaint(
                              painter: _DotsPainter(color: c.accentInk),
                              child: const SizedBox(width: 3),
                            )
                          : Container(
                              width: 3,
                              decoration: BoxDecoration(
                                gradient: c.accentGradient,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 4, bottom: last ? 0 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: highlight
                        ? theme.textTheme.titleSmall
                        : theme.textTheme.bodyMedium?.copyWith(color: c.plum),
                  ),
                  if (subtitle != null)
                    Text(subtitle!, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
          if (trailing != null)
            Padding(
              padding: const EdgeInsets.only(top: 5, left: 8),
              child: Text(
                trailing!,
                style: theme.textTheme.bodySmall?.copyWith(color: c.plum45),
              ),
            ),
        ],
      ),
    );
  }
}

class _StopChoices extends StatelessWidget {
  const _StopChoices({
    required this.label,
    required this.stops,
    required this.selectedId,
    required this.onSelected,
  });

  final String label;
  final List<TransitStop> stops;
  final String selectedId;
  final ValueChanged<TransitStop> onSelected;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final c = Theme.of(context).amica;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: c.plum70,
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final stop in stops) ...[
                ChoiceChip(
                  selected: stop.id == selectedId,
                  showCheckmark: false,
                  onSelected: (_) => onSelected(stop),
                  label: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        stop.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: stop.id == selectedId
                              ? AppColors.onAccent
                              : c.accentInk,
                        ),
                      ),
                      Text(
                        loc.tripStopAway(formatDistance(stop.distanceMeters)),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: stop.id == selectedId
                              ? AppColors.onAccent.withValues(alpha: 0.9)
                              : c.plum45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// A dotted rail segment — "you walk this part".
class _DotsPainter extends CustomPainter {
  const _DotsPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final x = size.width / 2;
    for (var y = 2.0; y < size.height - 1; y += 7) {
      canvas.drawCircle(Offset(x, y), 1.5, paint);
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => old.color != color;
}
