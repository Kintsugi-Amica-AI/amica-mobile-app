import '../models/vehicle_profile.dart';

enum VehicleMatchOutcome {
  /// Everything we could check fits.
  match,

  /// At least one confident reading disagrees with what was expected.
  mismatch,

  /// Nothing could be checked with confidence (too dark, no vehicle in
  /// view, nothing expected). The normal plate result still applies.
  notSure,
}

enum VehicleMatchSource { told, community }

enum VehicleMatchAspect { type, colour }

/// One disagreement, in structured form so the screen can word it.
class VehicleMismatch {
  const VehicleMismatch({
    required this.source,
    required this.aspect,
    this.expectedKind,
    this.seenKind,
    this.expectedColour,
    this.seenColour,
  });

  final VehicleMatchSource source;
  final VehicleMatchAspect aspect;
  final VehicleKind? expectedKind;
  final VehicleKind? seenKind;
  final VehicleColour? expectedColour;
  final VehicleColour? seenColour;
}

enum VehicleNotSureReason { lowLight, colourCast, noVehicle, nothingToCompare }

class VehicleMatchResult {
  const VehicleMatchResult({
    required this.outcome,
    this.mismatches = const [],
    this.notSureReasons = const {},
    this.checkedType = false,
    this.checkedColour = false,
  });

  final VehicleMatchOutcome outcome;
  final List<VehicleMismatch> mismatches;
  final Set<VehicleNotSureReason> notSureReasons;
  final bool checkedType;
  final bool checkedColour;
}

/// Decides match / mismatch / not sure. Warns, never blocks: the result
/// only changes what the result screen says.
///
/// Rules, chosen so a false alarm is rarer than a missed one:
///  * Type readings count only at [minTypeConfidence] or more, and a told
///    type only mismatches when the detector class cannot be that type
///    (a COCO "car" may be a van or a three-wheeler).
///  * Colour readings count only when [VehicleColourReading.isReliable]
///    (not dark, no street-light cast, one colour clearly won) and
///    look-alike colours (white/silver, grey/black, red/maroon...) never
///    mismatch.
///  * The community pattern is compared with what the camera sees, never
///    with what the rider was told, because both come from the same
///    detector.
class VehicleMatcher {
  const VehicleMatcher._();

  static const double minTypeConfidence = 0.5;

  static VehicleMatchResult evaluate({
    required VehicleExpectation told,
    required VehicleTypeReading? type,
    required VehicleColourReading? colour,
    CommunityVehicleProfile community = CommunityVehicleProfile.empty,
  }) {
    final reasons = <VehicleNotSureReason>{};
    final mismatches = <VehicleMismatch>[];

    if (type == null) reasons.add(VehicleNotSureReason.noVehicle);
    if (colour != null && colour.lowLight) {
      reasons.add(VehicleNotSureReason.lowLight);
    } else if (colour != null && colour.colourCast) {
      reasons.add(VehicleNotSureReason.colourCast);
    }

    var checkedType = false;
    var checkedColour = false;

    if (type != null && type.confidence >= minTypeConfidence) {
      final expected = told.kind;
      if (expected != null) {
        checkedType = true;
        if (!type.possibleKinds.contains(expected)) {
          mismatches.add(VehicleMismatch(
            source: VehicleMatchSource.told,
            aspect: VehicleMatchAspect.type,
            expectedKind: expected,
            seenKind: type.bestKind,
          ));
        }
      }
      final usual = community.usualKind;
      if (usual != null) {
        checkedType = true;
        if (!type.possibleKinds.contains(usual)) {
          mismatches.add(VehicleMismatch(
            source: VehicleMatchSource.community,
            aspect: VehicleMatchAspect.type,
            expectedKind: usual,
            seenKind: type.bestKind,
          ));
        }
      }
    }

    final seen = colour != null && colour.isReliable ? colour.colour : null;
    if (seen != null) {
      final expected = told.colour;
      if (expected != null) {
        checkedColour = true;
        if (!seen.compatibleWith(expected)) {
          mismatches.add(VehicleMismatch(
            source: VehicleMatchSource.told,
            aspect: VehicleMatchAspect.colour,
            expectedColour: expected,
            seenColour: seen,
          ));
        }
      }
      final usual = community.usualColour;
      if (usual != null) {
        checkedColour = true;
        if (!seen.compatibleWith(usual)) {
          mismatches.add(VehicleMismatch(
            source: VehicleMatchSource.community,
            aspect: VehicleMatchAspect.colour,
            expectedColour: usual,
            seenColour: seen,
          ));
        }
      }
    }

    if (mismatches.isNotEmpty) {
      return VehicleMatchResult(
        outcome: VehicleMatchOutcome.mismatch,
        mismatches: mismatches,
        notSureReasons: reasons,
        checkedType: checkedType,
        checkedColour: checkedColour,
      );
    }
    if (!checkedType && !checkedColour) {
      if (reasons.isEmpty) reasons.add(VehicleNotSureReason.nothingToCompare);
      return VehicleMatchResult(
        outcome: VehicleMatchOutcome.notSure,
        notSureReasons: reasons,
      );
    }
    return VehicleMatchResult(
      outcome: VehicleMatchOutcome.match,
      notSureReasons: reasons,
      checkedType: checkedType,
      checkedColour: checkedColour,
    );
  }
}
