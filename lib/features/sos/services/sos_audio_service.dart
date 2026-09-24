import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where the SOS audio clip is in its life, for the SOS screen.
enum SosAudioPhase {
  /// No clip for this SOS (e.g. a journey-timer SOS).
  idle,

  /// Turned off in Settings.
  disabled,

  /// The microphone permission was never granted. Amica does not ask in the
  /// middle of an emergency.
  noPermission,

  /// The microphone is on.
  recording,

  /// The clip is finished and going to Cloud Storage.
  uploading,

  /// Stored in the cloud; linked to the alert as `evidence.audioClip`.
  saved,

  /// Recorded, but not uploaded yet (no signal). Kept on the phone and
  /// retried, including on the next app start.
  pending,

  /// The phone could not record.
  failed,
}

/// A finished clip waiting to reach Cloud Storage.
@immutable
class PendingSosClip {
  const PendingSosClip({
    required this.path,
    required this.durationMillis,
    required this.recordedAtMillis,
    required this.triggerType,
    this.alertId,
  });

  final String path;
  final int durationMillis;
  final int recordedAtMillis;
  final String triggerType;

  /// The alert it belongs to; null while the alert is still being created.
  final String? alertId;

  PendingSosClip withAlert(String id) => PendingSosClip(
        path: path,
        durationMillis: durationMillis,
        recordedAtMillis: recordedAtMillis,
        triggerType: triggerType,
        alertId: id,
      );

  Map<String, Object?> toJson() => {
        'path': path,
        'durationMillis': durationMillis,
        'recordedAtMillis': recordedAtMillis,
        'triggerType': triggerType,
        if (alertId != null) 'alertId': alertId,
      };

  static PendingSosClip? fromJson(Object? value) {
    if (value is! Map) return null;
    final path = value['path'];
    if (path is! String || path.isEmpty) return null;
    final alertId = value['alertId'];
    return PendingSosClip(
      path: path,
      durationMillis: _int(value['durationMillis']),
      recordedAtMillis: _int(value['recordedAtMillis']),
      triggerType: value['triggerType'] is String
          ? value['triggerType'] as String
          : 'manual',
      alertId: alertId is String && alertId.isNotEmpty ? alertId : null,
    );
  }

  static int _int(Object? v) => v is num ? v.toInt() : 0;
}

/// Records a short audio clip the moment an SOS fires and saves it to the
/// cloud as evidence.
///
/// 1. [startForSos] is called at the trigger — the end of the SOS countdown,
///    or right after Voice SOS hears the phrase — before location and the
///    alert are ready, so the first seconds are not lost.
/// 2. The native `SosAudioRecorderService` records [clipLength] of AAC audio
///    in a microphone foreground service, so it keeps going with the screen
///    locked.
/// 3. Once the alert exists, [attachAlert] links the clip to it. The finished
///    clip is uploaded to `sos_audio/{uid}/{alertId}.m4a` (Storage rules: only
///    she can create or read it; it can never be replaced or deleted from the
///    app).
/// 4. The `onSosAudioUploaded` Cloud Function records it on the alert as
///    `evidence.audioClip`. Clients cannot write `evidence` themselves.
///
/// With no signal the clip stays on the phone (app-private storage) and is
/// retried, including by [resumePendingUploads] on the next app start. It is
/// deleted from the phone once it is in the cloud.
class SosAudioService {
  SosAudioService({
    MethodChannel? channel,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
    Future<SharedPreferences> Function()? preferences,
    Duration pollInterval = const Duration(seconds: 1),
  })  : _channel = channel ?? const MethodChannel(_channelName),
        _storage = storage,
        _auth = auth,
        _preferences = preferences ?? SharedPreferences.getInstance,
        _pollInterval = pollInterval;

  static final SosAudioService instance = SosAudioService();

  static const String _channelName = 'com.kintsugi.amica/emergency_actions';

  /// Length of the clip. Short on purpose: enough to capture what was said
  /// and done in the first moments, small enough (≈240 KB) to upload on a
  /// weak connection.
  static const Duration clipLength = Duration(seconds: 30);

  static const String enabledKey = 'sosAudioRecordingEnabled';
  static const String _askedKey = 'sosAudioPermissionAsked';
  static const String _pendingKey = 'sosAudioPendingClips';

  static String storagePath(String uid, String alertId) =>
      'sos_audio/$uid/$alertId.m4a';

  final MethodChannel _channel;
  final FirebaseStorage? _storage;
  final FirebaseAuth? _auth;
  final Future<SharedPreferences> Function() _preferences;
  final Duration _pollInterval;

  /// Live phase of the current SOS's clip.
  final ValueNotifier<SosAudioPhase> phase =
      ValueNotifier<SosAudioPhase>(SosAudioPhase.idle);

  Timer? _poll;
  String? _recordingPath;
  String _triggerType = 'manual';
  String? _alertId;
  int _startAttempts = 0;
  DateTime? _startedAt;
  bool _uploading = false;

  // ---------------------------------------------------------------- settings

  /// Whether SOS audio is on for this phone. On by default.
  Future<bool> isEnabled() async {
    try {
      return (await _preferences()).getBool(enabledKey) ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    try {
      await (await _preferences()).setBool(enabledKey, enabled);
    } catch (_) {}
  }

  Future<bool> hasPermission() async {
    try {
      return await _channel.invokeMethod<bool>('hasMicrophonePermission') ??
          false;
    } catch (_) {
      return false;
    }
  }

  /// Shows the system microphone prompt if needed. True when granted.
  Future<bool> requestPermission() async {
    try {
      return await _channel.invokeMethod<bool>('prepareMicrophonePermission') ??
          false;
    } catch (_) {
      return false;
    }
  }

  /// Asks for the microphone once, ahead of any emergency, so that an SOS
  /// can record. Never asks again after she has answered.
  Future<void> askPermissionOnce() async {
    try {
      final prefs = await _preferences();
      if (prefs.getBool(_askedKey) == true) return;
      if (!await isEnabled() || await hasPermission()) return;
      await prefs.setBool(_askedKey, true);
      await requestPermission();
    } catch (_) {}
  }

  // --------------------------------------------------------------- recording

  /// Starts the clip for an SOS that has just fired. Returns at once; never
  /// throws, never delays the alert.
  Future<void> startForSos({required String triggerType}) async {
    // One clip per SOS: a retry after a failed send reuses the recording.
    if (phase.value == SosAudioPhase.recording) return;

    _triggerType = triggerType;
    _alertId = null;
    _recordingPath = null;
    _startAttempts = 0;
    _retries = 0;

    if (!await isEnabled()) {
      phase.value = SosAudioPhase.disabled;
      return;
    }
    phase.value = SosAudioPhase.recording;
    _startedAt = DateTime.now();
    await _startNative();
  }

  Future<void> _startNative() async {
    _startAttempts++;
    try {
      final result = await _channel.invokeMethod<Object?>(
        'startSosAudioRecording',
        {'maxSeconds': clipLength.inSeconds},
      );
      final map = result is Map ? result : const {};
      if (map['started'] != true) {
        phase.value = map['reason'] == 'permission'
            ? SosAudioPhase.noPermission
            : SosAudioPhase.failed;
        return;
      }
      _recordingPath = map['path'] as String?;
      _watchNative();
    } on MissingPluginException {
      phase.value = SosAudioPhase.failed; // Not Android.
    } catch (_) {
      phase.value = SosAudioPhase.failed;
    }
  }

  void _watchNative() {
    _poll?.cancel();
    _poll = Timer.periodic(_pollInterval, (_) => _checkNative());
  }

  bool _checking = false;

  Future<void> _checkNative() async {
    // Ticks can overlap while the channel answers; handle one at a time.
    if (_checking) return;
    _checking = true;
    try {
      await _checkNativeOnce();
    } finally {
      _checking = false;
    }
  }

  Future<void> _checkNativeOnce() async {
    Map<Object?, Object?> status;
    try {
      final result =
          await _channel.invokeMethod<Object?>('sosAudioRecordingStatus');
      status = result is Map ? result : const {};
    } catch (_) {
      return;
    }
    if (status['path'] != _recordingPath) return; // Not our clip yet.

    switch (status['state']) {
      case 'recording':
        // The service died without reporting back: stop waiting.
        final startedAt = _startedAt;
        if (startedAt != null &&
            DateTime.now().difference(startedAt) >
                clipLength + const Duration(seconds: 30)) {
          _poll?.cancel();
          phase.value = SosAudioPhase.failed;
        }
      case 'finished':
        _poll?.cancel();
        final durationMillis = status['durationMillis'];
        await _onClipFinished(
          PendingSosClip(
            path: _recordingPath!,
            durationMillis: durationMillis is num ? durationMillis.toInt() : 0,
            recordedAtMillis: (_startedAt ?? DateTime.now())
                .millisecondsSinceEpoch,
            triggerType: _triggerType,
            alertId: _alertId,
          ),
        );
      case 'failed':
        _poll?.cancel();
        // Voice SOS: speech recognition can hold the microphone for a moment
        // after it stops. Try once more before giving up.
        if (_startAttempts < 2) {
          await Future<void>.delayed(const Duration(milliseconds: 700));
          await _startNative();
        } else {
          phase.value = SosAudioPhase.failed;
        }
    }
  }

  /// For an SOS that records no clip (a journey timer SOS): clears what the
  /// SOS screen would otherwise show from an earlier SOS.
  void markNoClip() {
    if (phase.value != SosAudioPhase.recording &&
        phase.value != SosAudioPhase.uploading) {
      phase.value = SosAudioPhase.idle;
    }
  }

  /// Links the clip to the alert once the alert exists. Safe to call before
  /// or after the clip has finished.
  Future<void> attachAlert(String alertId) async {
    if (alertId.isEmpty) return;
    _alertId = alertId;
    final clips = await _readPending();
    var changed = false;
    for (var i = 0; i < clips.length; i++) {
      if (clips[i].path == _recordingPath && clips[i].alertId == null) {
        clips[i] = clips[i].withAlert(alertId);
        changed = true;
      }
    }
    if (changed) {
      await _writePending(clips);
      unawaited(_uploadAll());
    }
  }

  Future<void> _onClipFinished(PendingSosClip clip) async {
    final clips = await _readPending()
      ..removeWhere((c) => c.path == clip.path)
      ..add(clip);
    await _writePending(clips);
    if (clip.alertId == null) {
      // attachAlert() may have run while the clip was being saved.
      final alertId = _alertId;
      if (alertId != null) {
        await attachAlert(alertId);
        return;
      }
      // Uploads once attachAlert() runs.
      phase.value = SosAudioPhase.pending;
      return;
    }
    await _uploadAll();
  }

  // ----------------------------------------------------------------- uploads

  /// Uploads clips left on the phone by an earlier SOS (no signal, or the
  /// app was closed). Call once at app start; waits for sign-in.
  Future<void> resumePendingUploads() async {
    try {
      final auth = _auth ?? FirebaseAuth.instance;
      if (auth.currentUser == null) {
        await auth
            .authStateChanges()
            .firstWhere((user) => user != null)
            .timeout(const Duration(seconds: 30));
      }
    } catch (_) {
      return;
    }
    // A clip that never got an alert (the alert itself failed) cannot be
    // linked to anything; drop it rather than keep audio around forever.
    final clips = await _readPending();
    final orphans = clips
        .where((c) => c.alertId == null && c.path != _recordingPath)
        .toList();
    for (final orphan in orphans) {
      await _deleteFile(orphan.path);
    }
    if (orphans.isNotEmpty) {
      await _writePending(
        clips.where((c) => !orphans.contains(c)).toList(),
      );
    }
    await _uploadAll();
  }

  bool _uploadAgain = false;

  Future<void> _uploadAll() async {
    if (_uploading) {
      _uploadAgain = true; // New work arrived mid-run; go round once more.
      return;
    }
    _uploading = true;
    try {
      do {
        _uploadAgain = false;
        await _uploadOnce();
      } while (_uploadAgain);
    } finally {
      _uploading = false;
    }
  }

  Future<void> _uploadOnce() async {
    final user = (_auth ?? FirebaseAuth.instance).currentUser;
    if (user == null) {
      _markCurrent(SosAudioPhase.pending);
      return;
    }
    for (final clip in await _readPending()) {
      if (clip.alertId == null) continue;
      _markCurrent(SosAudioPhase.uploading, clip: clip);
      final ok = await _upload(user.uid, clip);
      if (ok) {
        await _deleteFile(clip.path);
        final rest = await _readPending()
          ..removeWhere((c) => c.path == clip.path);
        await _writePending(rest);
        _markCurrent(SosAudioPhase.saved, clip: clip);
      } else {
        _markCurrent(SosAudioPhase.pending, clip: clip);
        _scheduleRetry();
      }
    }
  }

  int _retries = 0;
  void _scheduleRetry() {
    if (_retries >= 3) return; // The next app start tries again.
    _retries++;
    Timer(Duration(seconds: 20 * _retries), () => unawaited(_uploadAll()));
  }

  Future<bool> _upload(String uid, PendingSosClip clip) async {
    final file = File(clip.path);
    if (!await file.exists()) return true; // Nothing left to send.
    final ref = (_storage ?? FirebaseStorage.instance)
        .ref(storagePath(uid, clip.alertId!));
    try {
      await ref.putFile(
        file,
        SettableMetadata(
          contentType: 'audio/mp4',
          cacheControl: 'private, max-age=0, no-store',
          customMetadata: {
            'alertId': clip.alertId!,
            'durationMillis': '${clip.durationMillis}',
            'recordedAtMillis': '${clip.recordedAtMillis}',
            'triggerType': clip.triggerType,
          },
        ),
      );
      return true;
    } on FirebaseException catch (error) {
      // The object is create-once. "unauthorized" after an earlier attempt
      // that did reach the server means it is already saved.
      if (error.code == 'unauthorized') {
        try {
          await ref.getMetadata();
          return true;
        } catch (_) {}
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Only the current SOS's clip drives the on-screen phase.
  void _markCurrent(SosAudioPhase value, {PendingSosClip? clip}) {
    if (clip == null || clip.path == _recordingPath) phase.value = value;
  }

  Future<void> _deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  Future<List<PendingSosClip>> _readPending() async {
    try {
      final raw = (await _preferences()).getString(_pendingKey);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .map(PendingSosClip.fromJson)
          .whereType<PendingSosClip>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writePending(List<PendingSosClip> clips) async {
    try {
      await (await _preferences()).setString(
        _pendingKey,
        jsonEncode(clips.map((c) => c.toJson()).toList()),
      );
    } catch (_) {}
  }
}
