import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

/// One pre-recorded caller clip, as listed in the generated manifest.
///
/// Clips are made once with Gemini TTS by `tool/fake_call_audio/generate.py`
/// and bundled as assets, so Fake Call plays them with no network.
class FakeCallAudioClip {
  const FakeCallAudioClip({
    required this.id,
    required this.language,
    required this.role,
    required this.gender,
    required this.asset,
    required this.transcript,
  });

  final String id;
  final String language;

  /// `friend`, `mom`, `sister`, `brother`, `dad`, or `filler`.
  final String role;

  /// `female` or `male`.
  final String gender;
  final String asset;

  /// Everything the caller says, used to keep a clip from saying the user's
  /// Voice SOS secret phrase.
  final String transcript;

  factory FakeCallAudioClip.fromMap(
    Map<String, dynamic> data, {
    String defaultRole = '',
  }) {
    String read(String key, [String fallback = '']) {
      final value = data[key];
      return value is String ? value : fallback;
    }

    return FakeCallAudioClip(
      id: read('id', read('asset')),
      language: read('language', 'en'),
      role: read('role', defaultRole),
      gender: read('gender', 'female'),
      asset: read('asset'),
      transcript: read('transcript'),
    );
  }
}

class FakeCallAudioManifest {
  const FakeCallAudioManifest({required this.clips, required this.fillers});

  static const empty = FakeCallAudioManifest(clips: [], fillers: []);

  final List<FakeCallAudioClip> clips;
  final List<FakeCallAudioClip> fillers;

  factory FakeCallAudioManifest.fromJson(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      return empty;
    }

    List<FakeCallAudioClip> readList(String key, String defaultRole) {
      final raw = decoded[key];
      if (raw is! List) {
        return const [];
      }
      return raw
          .whereType<Map>()
          .map((item) => FakeCallAudioClip.fromMap(
                Map<String, dynamic>.from(item),
                defaultRole: defaultRole,
              ))
          .where((clip) => clip.asset.isNotEmpty)
          .toList(growable: false);
    }

    return FakeCallAudioManifest(
      clips: readList('clips', ''),
      fillers: readList('fillers', 'filler'),
    );
  }
}

class FakeCallAudioSelection {
  const FakeCallAudioSelection({required this.clip, this.filler});

  final FakeCallAudioClip clip;
  final FakeCallAudioClip? filler;
}

/// Plays a short pre-recorded conversation during a fake call, so the call
/// sounds real to people nearby instead of being silent.
///
/// Audio is a bonus, never a requirement: every failure (no clips generated
/// yet, a missing asset, a platform error) leaves the call running silently.
class FakeCallAudioService {
  FakeCallAudioService({
    MethodChannel? channel,
    AssetBundle? bundle,
    Random? random,
  })  : _channel = channel ?? defaultChannel,
        _bundle = bundle ?? rootBundle,
        _random = random ?? Random();

  static const MethodChannel defaultChannel = MethodChannel(
    'com.kintsugi.amica/fake_call_audio',
  );
  static const String manifestAsset = 'assets/audio/fake_call/manifest.json';
  static const String fallbackLanguage = 'en';

  /// Words in the caller's name that say who is calling. Latin-script entries
  /// match whole words only, so a friend called "Sammy" is not "mum".
  static const Map<String, List<String>> roleHints = {
    'mom': ['mom', 'mum', 'mother', 'mommy', 'mummy', 'ammi', 'amma',
      'අම්මා', 'අම්මි', 'அம்மா'],
    'dad': ['dad', 'daddy', 'father', 'papa', 'thaththa', 'thatha', 'appa',
      'තාත්තා', 'අප්පච්චි', 'அப்பா'],
    'brother': ['brother', 'bro', 'aiya', 'ayya', 'malli', 'thambi',
      'අයියා', 'මල්ලි', 'அண்ணா', 'தம்பி'],
    'sister': ['sister', 'sis', 'akka', 'akki', 'nangi', 'thangachi',
      'අක්කා', 'නංගි', 'அக்கா', 'தங்கச்சி'],
  };

  /// Roles used when the caller's name gives no hint. Both are female, which
  /// suits the default "Amica Friend" caller.
  static const List<String> defaultRoles = ['friend', 'sister'];

  final MethodChannel _channel;
  final AssetBundle _bundle;
  final Random _random;
  FakeCallAudioManifest? _manifest;

  Future<FakeCallAudioManifest> loadManifest() async {
    final cached = _manifest;
    if (cached != null) {
      return cached;
    }
    try {
      final source = await _bundle.loadString(manifestAsset);
      return _manifest = FakeCallAudioManifest.fromJson(source);
    } catch (_) {
      return _manifest = FakeCallAudioManifest.empty;
    }
  }

  /// Picks a clip and starts it. Returns what is playing, or null when there
  /// is nothing suitable to play.
  Future<FakeCallAudioSelection?> start({
    required String languageCode,
    required String callerName,
    List<String> secretPhrases = const [],
    bool speakerOn = false,
  }) async {
    try {
      final selection = select(
        await loadManifest(),
        languageCode: languageCode,
        callerName: callerName,
        secretPhrases: secretPhrases,
        random: _random,
      );
      if (selection == null) {
        return null;
      }
      await _channel.invokeMethod<bool>('start', {
        'clip': selection.clip.asset,
        'filler': selection.filler?.asset,
        'speakerOn': speakerOn,
      });
      return selection;
    } catch (_) {
      return null;
    }
  }

  Future<void> setSpeaker({required bool enabled}) async {
    try {
      await _channel.invokeMethod<bool>('setSpeaker', {'enabled': enabled});
    } catch (_) {
      // Routing is cosmetic; the call UI keeps working.
    }
  }

  Future<void> stop() async {
    try {
      await _channel.invokeMethod<bool>('stop');
    } catch (_) {
      // Nothing playing, or the platform side is gone.
    }
  }

  /// Chooses the clip for a call. Pure, so it can be unit tested.
  ///
  /// 1. Language: the app's language if clips exist for it, else English.
  /// 2. Role: from the caller's name ("Amma" → mom, "Aiya" → brother), else
  ///    friend or sister. If that role has no clip, any clip of the same
  ///    voice gender is used.
  /// 3. Safety: a clip that says one of the user's Voice SOS secret phrases
  ///    is never played, because the speech recognizer could hear it through
  ///    the speaker and send a false SOS.
  static FakeCallAudioSelection? select(
    FakeCallAudioManifest manifest, {
    required String languageCode,
    required String callerName,
    List<String> secretPhrases = const [],
    Random? random,
  }) {
    final rng = random ?? Random();
    bool safe(FakeCallAudioClip clip) =>
        !containsSecretPhrase(clip.transcript, secretPhrases);

    final language =
        manifest.clips.any((clip) => clip.language == languageCode)
            ? languageCode
            : fallbackLanguage;
    final pool = manifest.clips
        .where((clip) => clip.language == language && safe(clip))
        .toList();
    if (pool.isEmpty) {
      return null;
    }

    final hintedRole = roleForCallerName(callerName);
    var candidates = <FakeCallAudioClip>[];
    if (hintedRole != null) {
      candidates = pool.where((clip) => clip.role == hintedRole).toList();
      if (candidates.isEmpty) {
        final gender = genderForRole(hintedRole);
        candidates = pool.where((clip) => clip.gender == gender).toList();
      }
    } else {
      candidates =
          pool.where((clip) => defaultRoles.contains(clip.role)).toList();
    }
    if (candidates.isEmpty) {
      candidates = pool;
    }

    final clip = candidates[rng.nextInt(candidates.length)];
    final fillers = manifest.fillers
        .where((filler) =>
            filler.language == clip.language &&
            filler.gender == clip.gender &&
            safe(filler))
        .toList();
    return FakeCallAudioSelection(
      clip: clip,
      filler: fillers.isEmpty ? null : fillers.first,
    );
  }

  static String? roleForCallerName(String callerName) {
    final name = callerName.toLowerCase();
    final words = name
        .split(RegExp(r'[^\p{L}\p{M}]+', unicode: true))
        .where((word) => word.isNotEmpty)
        .toSet();
    for (final entry in roleHints.entries) {
      for (final hint in entry.value) {
        final isLatin = RegExp(r'^[a-z]+$').hasMatch(hint);
        if (isLatin ? words.contains(hint) : name.contains(hint)) {
          return entry.key;
        }
      }
    }
    return null;
  }

  static String genderForRole(String role) =>
      role == 'dad' || role == 'brother' ? 'male' : 'female';

  static bool containsSecretPhrase(String transcript, List<String> phrases) {
    final text = _normalize(transcript);
    return phrases
        .map(_normalize)
        .any((phrase) => phrase.isNotEmpty && text.contains(phrase));
  }

  /// Lower case, punctuation dropped, spaces collapsed — the same shape the
  /// speech recognizer produces, so "I'm on my way." matches "im on my way".
  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r"[^\p{L}\p{M}\p{N}\s]", unicode: true), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
