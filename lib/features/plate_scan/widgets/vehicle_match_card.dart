import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../models/plate_scan_outcome.dart';
import '../utils/vehicle_match.dart';
import 'vehicle_labels.dart';

/// Match / mismatch / not sure, with the reasons in plain words. It only
/// warns: nothing here stops the rider from continuing.
class VehicleMatchCard extends StatelessWidget {
  const VehicleMatchCard({super.key, required this.outcome});

  final PlateScanOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final c = Theme.of(context).amica;
    final text = Theme.of(context).textTheme;
    final match = outcome.match;

    final (Color colour, IconData icon, String title) = switch (match.outcome) {
      VehicleMatchOutcome.match => (
          c.sage,
          Icons.check_circle_rounded,
          loc.vehicleMatchTitleMatch,
        ),
      VehicleMatchOutcome.mismatch => (
          c.terracottaDeep,
          Icons.warning_amber_rounded,
          loc.vehicleMatchTitleMismatch,
        ),
      VehicleMatchOutcome.notSure => (
          c.gold,
          Icons.help_outline_rounded,
          loc.vehicleMatchTitleNotSure,
        ),
    };

    final inspection = outcome.inspection;
    final seenColour = inspection.colour?.isReliable == true
        ? inspection.colour!.colour
        : null;
    final seenKind = (inspection.type?.confidence ?? 0) >=
            VehicleMatcher.minTypeConfidence
        ? inspection.type!.bestKind
        : null;
    final seen = loc.describeVehicle(seenKind, seenColour);
    final community = outcome.status.community;

    final lines = <String>[
      if (match.outcome == VehicleMatchOutcome.match) loc.vehicleMatchBodyMatch,
      for (final m in match.mismatches) _mismatchLine(loc, m),
      if (match.outcome == VehicleMatchOutcome.mismatch) loc.vehicleMatchAdvice,
      for (final reason in match.notSureReasons) _reasonLine(loc, reason),
    ];

    return GlassCard(
      borderColor: colour.withValues(alpha: 0.55),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colour),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: text.titleMedium?.copyWith(color: colour),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(line, style: text.bodyMedium),
            ),
          const SizedBox(height: 4),
          Text(
            seen.isEmpty
                ? loc.vehicleMatchSeenNothing
                : loc.vehicleMatchSeen(seen),
            style: text.bodySmall,
          ),
          if (community.hasPattern)
            Text(
              loc.vehicleMatchCommunity(
                loc.describeVehicle(community.usualKind, community.usualColour),
                community.observationCount,
              ),
              style: text.bodySmall,
            ),
          const SizedBox(height: 4),
          Text(
            loc.vehicleMatchPrivacy,
            style: text.bodySmall?.copyWith(color: c.plum45),
          ),
        ],
      ),
    );
  }

  String _mismatchLine(AppLocalizations loc, VehicleMismatch m) {
    final expected = m.aspect == VehicleMatchAspect.type
        ? loc.describeVehicle(m.expectedKind, null)
        : loc.describeVehicle(null, m.expectedColour);
    final seen = m.aspect == VehicleMatchAspect.type
        ? loc.describeVehicle(m.seenKind, null)
        : loc.describeVehicle(null, m.seenColour);
    return m.source == VehicleMatchSource.told
        ? loc.vehicleMatchMismatchTold(expected, seen)
        : loc.vehicleMatchMismatchCommunity(expected, seen);
  }

  String _reasonLine(AppLocalizations loc, VehicleNotSureReason reason) =>
      switch (reason) {
        VehicleNotSureReason.lowLight => loc.vehicleMatchNotSureLowLight,
        VehicleNotSureReason.colourCast => loc.vehicleMatchNotSureColourCast,
        VehicleNotSureReason.noVehicle => loc.vehicleMatchNotSureNoVehicle,
        VehicleNotSureReason.nothingToCompare => loc.vehicleMatchNotSureNothing,
      };
}
