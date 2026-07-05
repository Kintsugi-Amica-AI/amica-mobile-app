import '../models/journey.dart';

class JourneyService {
  Future<Journey> startJourney({
    required String userId,
    required String destination,
    required Duration expectedDuration,
  }) async {
    final now = DateTime.now();
    // TODO: Persist journey in Firestore and schedule safety checks.
    return Journey(
      id: 'demo-journey',
      userId: userId,
      destination: destination,
      startedAt: now,
      expectedArrivalAt: now.add(expectedDuration),
    );
  }

  Future<void> completeJourney(String journeyId) async {
    // TODO: Mark journey as completed in Firestore.
  }

  Future<void> requestSafetyCheck(String journeyId) async {
    // TODO: Notify the user before escalating to contacts.
  }
}
