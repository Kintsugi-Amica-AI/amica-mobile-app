import 'package:flutter/material.dart';

import '../../../core/widgets/loading_view.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../models/journey.dart';
import '../services/journey_service.dart';
import 'journey_timer_screen.dart';
import 'start_journey_screen.dart';

/// The Journeys tab.
///
/// One tab, two states, decided by the data rather than by the user: if a
/// journey is running you land on its timer, otherwise you land on the form
/// to start one. Previously both were pushes off the home screen, which
/// meant a woman mid-journey had no persistent way back to her own timer.
class JourneysScreen extends StatelessWidget {
  const JourneysScreen({
    super.key,
    this.journeyService = const JourneyService(),
  });

  final JourneyService journeyService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Journey?>(
      stream: journeyService.watchActiveJourney(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: LoadingView(
              message:
                  AppLocalizations.of(context)!.journeysScreenCheckingJourneys,
            ),
          );
        }

        final active = snapshot.data;
        if (active != null) {
          return JourneyTimerScreen(journeyId: active.id, isTab: true);
        }
        return const StartJourneyScreen(isTab: true);
      },
    );
  }
}
