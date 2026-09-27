import 'package:amica_mobile_app/features/sos/services/sos_audio_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.kintsugi.amica/emergency_actions');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<String> calls;

  void mockNative({
    bool started = true,
    String reason = '',
    String state = 'finished',
  }) {
    calls = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      switch (call.method) {
        case 'startSosAudioRecording':
          return started
              ? {'started': true, 'path': '/data/clip.m4a'}
              : {'started': false, 'reason': reason};
        case 'sosAudioRecordingStatus':
          return {
            'state': state,
            'path': '/data/clip.m4a',
            'durationMillis': 30000,
          };
      }
      return null;
    });
  }

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  SosAudioService service() => SosAudioService(
        pollInterval: const Duration(milliseconds: 5),
      );

  test('storage path is per user and per alert', () {
    expect(SosAudioService.storagePath('u1', 'a1'), 'sos_audio/u1/a1.m4a');
  });

  test('pending clip survives a JSON round trip', () {
    const clip = PendingSosClip(
      path: '/data/clip.m4a',
      durationMillis: 30000,
      recordedAtMillis: 1700000000000,
      triggerType: 'voice',
      alertId: 'a1',
    );
    final back = PendingSosClip.fromJson(clip.toJson())!;
    expect(back.path, clip.path);
    expect(back.durationMillis, 30000);
    expect(back.triggerType, 'voice');
    expect(back.alertId, 'a1');
    expect(PendingSosClip.fromJson({'path': ''}), isNull);
    expect(PendingSosClip.fromJson('nope'), isNull);
  });

  test('turned off in settings: nothing is recorded', () async {
    SharedPreferences.setMockInitialValues({
      SosAudioService.enabledKey: false,
    });
    mockNative();
    final audio = service();
    await audio.startForSos(triggerType: 'manual');
    expect(audio.phase.value, SosAudioPhase.disabled);
    expect(calls, isNot(contains('startSosAudioRecording')));
  });

  test('no microphone permission: SOS goes on without audio', () async {
    SharedPreferences.setMockInitialValues({});
    mockNative(started: false, reason: 'permission');
    final audio = service();
    await audio.startForSos(triggerType: 'manual');
    expect(audio.phase.value, SosAudioPhase.noPermission);
  });

  test('a clip finished before the alert exists waits on the phone',
      () async {
    SharedPreferences.setMockInitialValues({});
    mockNative();
    final audio = service();
    await audio.startForSos(triggerType: 'voice');
    expect(audio.phase.value, SosAudioPhase.recording);

    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(audio.phase.value, SosAudioPhase.pending);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('sosAudioPendingClips'), contains('clip.m4a'));
  });

  test('a recorder that cannot start is retried once, then reported',
      () async {
    SharedPreferences.setMockInitialValues({});
    mockNative(state: 'failed');
    final audio = service();
    await audio.startForSos(triggerType: 'voice');
    await Future<void>.delayed(const Duration(milliseconds: 900));
    expect(
      calls.where((c) => c == 'startSosAudioRecording').length,
      2,
    );
    expect(audio.phase.value, SosAudioPhase.failed);
  });
}
