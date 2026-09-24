import 'dart:math';

import 'package:amica_mobile_app/features/fake_call/services/fake_call_audio_service.dart';
import 'package:flutter_test/flutter_test.dart';

FakeCallAudioClip _clip(
  String id,
  String language,
  String role, {
  String transcript = 'Hey, where are you right now?',
}) {
  return FakeCallAudioClip(
    id: id,
    language: language,
    role: role,
    gender: FakeCallAudioService.genderForRole(role),
    asset: 'assets/audio/fake_call/$language/$id.m4a',
    transcript: transcript,
  );
}

FakeCallAudioClip _filler(String language, String gender) {
  return FakeCallAudioClip(
    id: 'filler_$gender',
    language: language,
    role: 'filler',
    gender: gender,
    asset: 'assets/audio/fake_call/$language/filler_$gender.m4a',
    transcript: 'Mm-hm. Yeah. Okay.',
  );
}

final _manifest = FakeCallAudioManifest(
  clips: [
    _clip('friend_pickup', 'en', 'friend'),
    _clip('sister_tracking', 'en', 'sister'),
    _clip('mom_checkin', 'en', 'mom'),
    _clip('brother_pickup', 'en', 'brother'),
    _clip('friend_pickup', 'si', 'friend'),
    _clip('mom_checkin', 'si', 'mom'),
  ],
  fillers: [
    _filler('en', 'female'),
    _filler('en', 'male'),
    _filler('si', 'female'),
  ],
);

void main() {
  group('roleForCallerName', () {
    test('reads family roles in English, Sinhala and Tamil', () {
      expect(FakeCallAudioService.roleForCallerName('Mum'), 'mom');
      expect(FakeCallAudioService.roleForCallerName('Amma ❤'), 'mom');
      expect(FakeCallAudioService.roleForCallerName('අම්මා'), 'mom');
      expect(FakeCallAudioService.roleForCallerName('அப்பா'), 'dad');
      expect(FakeCallAudioService.roleForCallerName('Kasun Aiya'), 'brother');
      expect(FakeCallAudioService.roleForCallerName('Akka'), 'sister');
    });

    test('matches Latin hints as whole words only', () {
      expect(FakeCallAudioService.roleForCallerName('Sammy'), isNull);
      expect(FakeCallAudioService.roleForCallerName('Broderick'), isNull);
      expect(FakeCallAudioService.roleForCallerName('Amica Friend'), isNull);
    });
  });

  group('select', () {
    test('uses the app language when clips exist for it', () {
      final selection = FakeCallAudioService.select(
        _manifest,
        languageCode: 'si',
        callerName: 'Amica Friend',
        random: Random(1),
      );
      expect(selection!.clip.language, 'si');
      expect(selection.clip.role, 'friend');
      expect(selection.filler!.asset, contains('si/filler_female'));
    });

    test('falls back to English for a language with no clips', () {
      final selection = FakeCallAudioService.select(
        _manifest,
        languageCode: 'ta',
        callerName: 'Amica Friend',
      );
      expect(selection!.clip.language, 'en');
    });

    test('default caller gets a friend or sister voice', () {
      for (var seed = 0; seed < 20; seed++) {
        final selection = FakeCallAudioService.select(
          _manifest,
          languageCode: 'en',
          callerName: 'Amica Friend',
          random: Random(seed),
        );
        expect(['friend', 'sister'], contains(selection!.clip.role));
      }
    });

    test('a hinted role with no clip falls back to the same gender', () {
      final selection = FakeCallAudioService.select(
        _manifest,
        languageCode: 'en',
        callerName: 'Dad',
      );
      expect(selection!.clip.role, 'brother');
      expect(selection.filler!.gender, 'male');
    });

    test('never plays a clip that says a secret phrase', () {
      final manifest = FakeCallAudioManifest(
        clips: [
          _clip('a', 'en', 'friend', transcript: "Okay. I'm on my way!"),
          _clip('b', 'en', 'friend'),
        ],
        fillers: const [],
      );
      for (var seed = 0; seed < 20; seed++) {
        final selection = FakeCallAudioService.select(
          manifest,
          languageCode: 'en',
          callerName: 'Friend',
          secretPhrases: const ['im on my way'],
          random: Random(seed),
        );
        expect(selection!.clip.id, 'b');
      }
    });

    test('plays nothing when every clip clashes or none exist', () {
      expect(
        FakeCallAudioService.select(
          FakeCallAudioManifest.empty,
          languageCode: 'en',
          callerName: 'Friend',
        ),
        isNull,
      );
      expect(
        FakeCallAudioService.select(
          _manifest,
          languageCode: 'en',
          callerName: 'Friend',
          secretPhrases: const ['where are you'],
        ),
        isNull,
      );
    });
  });

  test('manifest parses the generator output and skips bad entries', () {
    final manifest = FakeCallAudioManifest.fromJson('''
      {"version": 1,
       "clips": [
         {"id": "friend_pickup", "language": "en", "role": "friend",
          "gender": "female", "asset": "assets/audio/fake_call/en/friend_pickup.m4a",
          "transcript": "Hey!"},
         {"id": "broken"}
       ],
       "fillers": [
         {"language": "en", "gender": "female",
          "asset": "assets/audio/fake_call/en/filler_female.m4a"}
       ]}
    ''');
    expect(manifest.clips, hasLength(1));
    expect(manifest.fillers.single.role, 'filler');
    expect(FakeCallAudioManifest.fromJson('[]').clips, isEmpty);
  });
}
