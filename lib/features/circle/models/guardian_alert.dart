/// An alert pushed to a guardian, as carried in the notification payload.
///
/// Everything the guardian screen shows comes from the push itself, so a
/// guardian never needs read access to her Firestore documents.
class GuardianAlert {
  const GuardianAlert({
    required this.type,
    this.alertId,
    this.journeyId,
    this.ownerName = '',
    this.ownerPhone = '',
    this.triggerType = '',
    this.latitude,
    this.longitude,
    this.mapsUrl,
    this.liveUrl,
    this.destinationName = '',
    this.guardianName = '',
    this.response,
    this.receivedAt,
  });

  /// `sos`, `journey_started`, `journey_arrived`, `guardian_response` or
  /// `guardian_linked` — see the backend's pushService.
  final String type;
  final String? alertId;
  final String? journeyId;
  final String ownerName;
  final String ownerPhone;
  final String triggerType;
  final double? latitude;
  final double? longitude;
  final String? mapsUrl;
  final String? liveUrl;
  final String destinationName;
  final String guardianName;
  final String? response;
  final DateTime? receivedAt;

  bool get isSos => type == 'sos';

  factory GuardianAlert.fromData(Map<String, dynamic> data) {
    String read(String key) {
      final value = data[key];
      return value is String ? value.trim() : '';
    }

    String? optional(String key) {
      final value = read(key);
      return value.isEmpty ? null : value;
    }

    return GuardianAlert(
      type: read('type'),
      alertId: optional('alertId'),
      journeyId: optional('journeyId'),
      ownerName: read('ownerName'),
      ownerPhone: read('ownerPhone'),
      triggerType: read('triggerType'),
      latitude: double.tryParse(read('latitude')),
      longitude: double.tryParse(read('longitude')),
      mapsUrl: _httpsOnly(optional('mapsUrl')),
      liveUrl: _httpsOnly(optional('liveUrl')),
      destinationName: read('destinationName'),
      guardianName: read('guardianName'),
      response: optional('response'),
      receivedAt: DateTime.tryParse(read('receivedAt')),
    );
  }

  Map<String, String> toData() => {
        'type': type,
        if (alertId != null) 'alertId': alertId!,
        if (journeyId != null) 'journeyId': journeyId!,
        'ownerName': ownerName,
        'ownerPhone': ownerPhone,
        'triggerType': triggerType,
        if (latitude != null) 'latitude': '$latitude',
        if (longitude != null) 'longitude': '$longitude',
        if (mapsUrl != null) 'mapsUrl': mapsUrl!,
        if (liveUrl != null) 'liveUrl': liveUrl!,
        'destinationName': destinationName,
        'guardianName': guardianName,
        if (response != null) 'response': response!,
        if (receivedAt != null) 'receivedAt': receivedAt!.toIso8601String(),
      };

  /// Links from a push are opened in the browser, so only https is allowed.
  static String? _httpsOnly(String? url) {
    if (url == null) return null;
    final uri = Uri.tryParse(url);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty
        ? url
        : null;
  }
}
