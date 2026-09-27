import '../models/fake_call_session.dart';

class FakeCallService {
  const FakeCallService();

  /// Delays offered when arming a deterrent call, short enough to cover
  /// "I am about to get into this vehicle" and long enough to cover a walk to
  /// a pickup point.
  static const List<Duration> scheduleDelayOptions = [
    Duration(seconds: 15),
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 2),
    Duration(minutes: 5),
  ];

  String getDefaultCallerName() {
    return 'Amica Friend';
  }

  String getDefaultCallerNumber() {
    return '+94 700 000 000';
  }

  FakeCallSession buildFakeCallSession({
    String? callerName,
    String? callerNumber,
    String status = 'incoming',
  }) {
    final now = DateTime.now();
    return FakeCallSession(
      id: 'fake-call-${now.millisecondsSinceEpoch}',
      callerName: callerName?.trim().isNotEmpty == true
          ? callerName!.trim()
          : getDefaultCallerName(),
      callerNumber: callerNumber?.trim().isNotEmpty == true
          ? callerNumber!.trim()
          : getDefaultCallerNumber(),
      status: status,
      startedAt: now,
      voiceSosTriggered: false,
      metadata: const {},
    );
  }

  String formatCallDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  /// Short label for a schedule choice, e.g. `15s`, `1 min`, `2 min`.
  String formatScheduleDelay(Duration delay) {
    if (delay.inSeconds < 60) {
      return '${delay.inSeconds}s';
    }
    return '${delay.inMinutes} min';
  }
}
