class FakeCallSession {
  const FakeCallSession({
    required this.id,
    required this.callerName,
    required this.callerNumber,
    required this.status,
    required this.startedAt,
    required this.voiceSosTriggered,
    required this.metadata,
    this.endedAt,
    this.sosAlertId,
  });

  final String id;
  final String callerName;
  final String callerNumber;
  final String status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final bool voiceSosTriggered;
  final String? sosAlertId;
  final Map<String, dynamic> metadata;

  factory FakeCallSession.fromMap(Map<String, dynamic> data) {
    return FakeCallSession(
      id: _readString(data['id']),
      callerName: _readString(data['callerName'], 'Amica Friend'),
      callerNumber: _readString(data['callerNumber'], '+94 700 000 000'),
      status: _readString(data['status'], 'incoming'),
      startedAt: _readDateTime(data['startedAt']),
      endedAt: data['endedAt'] == null ? null : _readDateTime(data['endedAt']),
      voiceSosTriggered: data['voiceSosTriggered'] == true,
      sosAlertId: _readString(data['sosAlertId']).isEmpty
          ? null
          : _readString(data['sosAlertId']),
      metadata: _readMap(data['metadata']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'callerName': callerName,
      'callerNumber': callerNumber,
      'status': status,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'voiceSosTriggered': voiceSosTriggered,
      'sosAlertId': sosAlertId,
      'metadata': metadata,
    };
  }

  static String _readString(dynamic value, [String fallback = '']) {
    return value is String ? value : fallback;
  }

  static DateTime _readDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  static Map<String, dynamic> _readMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }
}
