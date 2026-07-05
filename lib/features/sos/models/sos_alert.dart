class SosAlert {
  const SosAlert({
    required this.id,
    required this.userId,
    required this.triggerType,
    required this.createdAt,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String userId;
  final String triggerType;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;
}
