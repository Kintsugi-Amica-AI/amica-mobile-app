/// What a vehicle looks like: its body type and main colour.
///
/// Pure Dart (no Flutter / Firebase imports) so the matching rules can be
/// unit tested on their own. The string [VehicleKind.id] / [VehicleColour.id]
/// values are what Firestore stores, and amica-cloud-backend validates the
/// same lists (see `vehicleObservationService.ts`).
library;

enum VehicleKind {
  car('car'),
  van('van'),
  bus('bus'),
  lorry('lorry'),
  motorbike('motorbike'),
  threeWheeler('three_wheeler');

  const VehicleKind(this.id);

  final String id;

  static VehicleKind? fromId(Object? id) {
    for (final kind in values) {
      if (kind.id == id) return kind;
    }
    return null;
  }
}

enum VehicleColour {
  white('white'),
  silver('silver'),
  grey('grey'),
  black('black'),
  red('red'),
  maroon('maroon'),
  orange('orange'),
  yellow('yellow'),
  green('green'),
  blue('blue'),
  brown('brown');

  const VehicleColour(this.id);

  final String id;

  static VehicleColour? fromId(Object? id) {
    for (final colour in values) {
      if (colour.id == id) return colour;
    }
    return null;
  }

  /// Colours a camera easily mixes up, so a difference between two of them
  /// is never reported as a mismatch. Silver sits between white and grey,
  /// grey between silver and black; warm colours drift into each other in
  /// shade and under street lights.
  static const Map<VehicleColour, Set<VehicleColour>> _lookAlikes = {
    white: {silver},
    silver: {white, grey},
    grey: {silver, black},
    black: {grey},
    red: {maroon, orange},
    maroon: {red, brown},
    orange: {red, yellow, brown},
    yellow: {orange},
    green: {},
    blue: {},
    brown: {maroon, orange},
  };

  /// Whether this colour and [other] could be the same paint.
  bool compatibleWith(VehicleColour other) =>
      other == this || (_lookAlikes[this]?.contains(other) ?? false);
}

/// What the rider was told about the vehicle (for example by PickMe or
/// Uber: "White Toyota Axio, CAB-1234"). Either part may be left out.
class VehicleExpectation {
  const VehicleExpectation({this.kind, this.colour});

  final VehicleKind? kind;
  final VehicleColour? colour;

  bool get isEmpty => kind == null && colour == null;

  VehicleExpectation copyWith({
    VehicleKind? kind,
    VehicleColour? colour,
    bool clearKind = false,
    bool clearColour = false,
  }) =>
      VehicleExpectation(
        kind: clearKind ? null : (kind ?? this.kind),
        colour: clearColour ? null : (colour ?? this.colour),
      );
}

/// A vehicle type read from the camera.
///
/// A general-purpose detector (COCO) only knows "car", "motorcycle",
/// "bus" and "truck", and a COCO "car" can be a van or even a
/// three-wheeler. So a reading carries every [VehicleKind] it could be,
/// and a told type only counts as a mismatch when it is outside that set.
class VehicleTypeReading {
  const VehicleTypeReading({
    required this.label,
    required this.possibleKinds,
    required this.confidence,
  });

  /// The detector's own class name, e.g. `car` or `three_wheeler`.
  final String label;

  /// Every kind this detection could honestly be.
  final Set<VehicleKind> possibleKinds;

  /// Detector score, 0.0-1.0.
  final double confidence;

  /// The kind to show and save: the detector class's primary meaning
  /// (a COCO "truck" is shown as a lorry). [possibleKinds] lists it first.
  VehicleKind? get bestKind =>
      possibleKinds.isEmpty ? null : possibleKinds.first;

  /// Maps a detector class name to the kinds it could be. Returns null for
  /// classes that are not vehicles.
  static Set<VehicleKind>? kindsForLabel(String label) =>
      switch (label.toLowerCase().replaceAll(' ', '_')) {
        // COCO classes.
        'car' => {VehicleKind.car, VehicleKind.van, VehicleKind.threeWheeler},
        'motorcycle' => {VehicleKind.motorbike, VehicleKind.threeWheeler},
        'bus' => {VehicleKind.bus, VehicleKind.van},
        'truck' => {VehicleKind.lorry, VehicleKind.van},
        // Classes a model fine-tuned on Sri Lankan roads can add
        // (see amica-ai-core/plate_ocr/training).
        'van' => {VehicleKind.van},
        'lorry' => {VehicleKind.lorry},
        'motorbike' => {VehicleKind.motorbike},
        'three_wheeler' || 'threewheeler' || 'tuk_tuk' || 'tuktuk' => {
            VehicleKind.threeWheeler
          },
        _ => null,
      };
}

/// A colour read from the camera.
class VehicleColourReading {
  const VehicleColourReading({
    required this.colour,
    required this.share,
    this.lowLight = false,
    this.colourCast = false,
  });

  /// The main body colour, or null when no colour clearly won.
  final VehicleColour? colour;

  /// Fraction (0.0-1.0) of body pixels that voted for [colour].
  final double share;

  /// The photo is too dark to trust colours.
  final bool lowLight;

  /// Street lights or dusk tint the whole photo (e.g. sodium-orange), so
  /// a white car can look orange.
  final bool colourCast;

  bool get isReliable =>
      colour != null && !lowLight && !colourCast && share >= 0.35;
}

/// What the Amica community has seen on this plate before.
class CommunityVehicleProfile {
  const CommunityVehicleProfile({
    this.usualKind,
    this.usualColour,
    this.observationCount = 0,
  });

  final VehicleKind? usualKind;
  final VehicleColour? usualColour;
  final int observationCount;

  static const empty = CommunityVehicleProfile();

  bool get hasPattern => usualKind != null || usualColour != null;

  /// Reads `vehicles/{plate}.observedProfile`, written only by the
  /// `onVehicleObservationCreated` Cloud Function.
  factory CommunityVehicleProfile.fromMap(Object? data) {
    if (data is! Map) return empty;
    final count = data['observationCount'];
    return CommunityVehicleProfile(
      usualKind: VehicleKind.fromId(data['usualType']),
      usualColour: VehicleColour.fromId(data['usualColour']),
      observationCount: count is num ? count.toInt() : 0,
    );
  }
}
