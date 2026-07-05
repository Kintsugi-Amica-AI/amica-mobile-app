class Journey {
  const Journey({
    required this.id,
    required this.userId,
    required this.destination,
    required this.startedAt,
    required this.expectedArrivalAt,
    this.completedAt,
  });

  final String id;
  final String userId;
  final String destination;
  final DateTime startedAt;
  final DateTime expectedArrivalAt;
  final DateTime? completedAt;

  bool get isActive => completedAt == null;
}
