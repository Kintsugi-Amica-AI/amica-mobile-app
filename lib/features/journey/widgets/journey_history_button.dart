import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../l10n/generated/app_localizations.dart';

/// The round "past journeys" button in the Journeys app bar.
///
/// A solid card-coloured circle rather than a bare icon: these app bars sit
/// over a map, and a bare icon would lose contrast on whatever street is
/// underneath.
class JourneyHistoryButton extends StatelessWidget {
  const JourneyHistoryButton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final loc = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Center(
        child: Semantics(
          button: true,
          label: loc.journeyHistoryOpen,
          child: Tooltip(
            message: loc.journeyHistoryOpen,
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, AppRoutes.journeyHistory),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.lineSoft),
                  boxShadow: c.shadow,
                ),
                child: Icon(Icons.history_rounded, size: 21, color: c.accentInk),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
