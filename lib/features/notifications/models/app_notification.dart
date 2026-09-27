/// One entry in the in-app notification list.
///
/// Notifications arrive as data-only pushes that Amica draws itself (see
/// `PushNotificationService`). Each one is also kept here, already worded in
/// the language it arrived in, so it can be looked at again after the system
/// notification has been swiped away.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.read = false,
    this.data = const {},
  });

  final String id;

  /// `sos`, `journey_started`, `journey_arrived`, `guardian_response` or
  /// `guardian_linked` — the same values as `GuardianAlert.type`.
  final String type;
  final String title;
  final String body;
  final DateTime receivedAt;
  final bool read;

  /// The push payload (`GuardianAlert.toData()`), so a tap can reopen the
  /// alert exactly as the system notification would.
  final Map<String, String> data;

  bool get isSos => type == 'sos';

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        receivedAt: receivedAt,
        read: read ?? this.read,
        data: data,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'body': body,
        'receivedAt': receivedAt.toIso8601String(),
        'read': read,
        'data': data,
      };

  static AppNotification? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final type = json['type'];
    final title = json['title'];
    final received = DateTime.tryParse('${json['receivedAt']}');
    if (id is! String || type is! String || title is! String || received == null) {
      return null;
    }
    final rawData = json['data'];
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: json['body'] is String ? json['body'] as String : '',
      receivedAt: received,
      read: json['read'] == true,
      data: rawData is Map
          ? {for (final e in rawData.entries) '${e.key}': '${e.value}'}
          : const {},
    );
  }
}
