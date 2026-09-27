import 'package:amica_mobile_app/features/fake_call/services/voice_sos_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = VoiceSosService();

  group('normalizePhrase', () {
    test('lowercases and collapses whitespace', () {
      expect(service.normalizePhrase('  Amica   HELP  Me '), 'amica help me');
      expect(service.normalizePhrase('Amica\nhelp\tme'), 'amica help me');
    });

    test('returns empty for blank input', () {
      expect(service.normalizePhrase(''), '');
      expect(service.normalizePhrase('    '), '');
    });
  });

  group('phraseMatches', () {
    test('matches regardless of case and spacing', () {
      expect(service.phraseMatches('Amica Help Me', 'amica help me'), isTrue);
      expect(service.phraseMatches('amica  help   me', 'amica help me'), isTrue);
    });

    test('matches the phrase inside longer speech', () {
      // Speech recognition returns whole utterances, not just the phrase.
      expect(
        service.phraseMatches(
          'no really amica help me I am nearly there',
          'amica help me',
        ),
        isTrue,
      );
    });

    test('does not match unrelated speech', () {
      expect(service.phraseMatches('I am on my way home', 'amica help me'),
          isFalse);
      expect(service.phraseMatches('amica help', 'amica help me'), isFalse);
    });

    test('never matches when the secret phrase is not configured', () {
      // Guards against an empty phrase matching every utterance, which would
      // fire a false SOS on any speech at all.
      expect(service.phraseMatches('anything at all', ''), isFalse);
      expect(service.phraseMatches('', ''), isFalse);
    });
  });
}
