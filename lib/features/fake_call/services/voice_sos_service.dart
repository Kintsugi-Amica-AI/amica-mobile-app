import 'package:speech_to_text/speech_to_text.dart';

class VoiceSosService {
  VoiceSosService({SpeechToText? speechToText})
      : _speechToText = speechToText ?? SpeechToText();

  final SpeechToText _speechToText;

  bool get isListening => _speechToText.isListening;

  Future<bool> initialize() {
    return _speechToText.initialize();
  }

  Future<void> startListening({
    required String expectedPhrase,
    List<String>? expectedPhrases,
    void Function(String phrase)? onMatchedPhrase,
    required void Function(String detectedText) onTextDetected,
    required void Function() onSecretPhraseDetected,
    required void Function(String error) onError,
  }) async {
    final available = await initialize();
    if (!available) {
      onError('Voice recognition is not available on this device.');
      return;
    }

    final phrases = expectedPhrases ?? [expectedPhrase];
    if (phrases.every((phrase) => normalizePhrase(phrase).isEmpty)) {
      onError('Secret phrase is not configured.');
      return;
    }

    try {
      await _speechToText.listen(
        listenOptions: SpeechListenOptions(
          partialResults: true,
          listenFor: const Duration(minutes: 2),
          pauseFor: const Duration(seconds: 6),
        ),
        onResult: (result) {
          final detectedText = result.recognizedWords;
          onTextDetected(detectedText);
          final matched = matchingPhrase(detectedText, phrases);
          if (matched != null) {
            onMatchedPhrase?.call(matched);
            onSecretPhraseDetected();
          }
        },
      );
    } catch (_) {
      onError('Could not start voice recognition. Use the test button.');
    }
  }

  Future<void> stopListening() async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
  }

  bool phraseMatches(String detectedText, String expectedPhrase) {
    final detected = normalizePhrase(detectedText);
    final expected = normalizePhrase(expectedPhrase);
    return expected.isNotEmpty && detected.contains(expected);
  }

  String? matchingPhrase(String detectedText, Iterable<String> phrases) {
    for (final phrase in phrases) {
      if (phraseMatches(detectedText, phrase)) return normalizePhrase(phrase);
    }
    return null;
  }

  String normalizePhrase(String phrase) {
    return phrase.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  // TODO: Improve noisy environment handling and confidence scoring later.
  // TODO: Consider offline Vosk integration if the MVP becomes production work.
}
