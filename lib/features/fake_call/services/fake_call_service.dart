import '../models/fake_call_session.dart';

class FakeCallService {
  const FakeCallService();

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
}
