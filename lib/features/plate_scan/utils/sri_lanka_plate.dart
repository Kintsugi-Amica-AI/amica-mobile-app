/// Sri Lankan vehicle registration formats, and how to pull them out of
/// raw OCR text.
///
/// Pure Dart (no Flutter / Firebase imports) so it can be unit tested on
/// its own. Every canonical value is uppercase alphanumerics only, the
/// same shape amica-cloud-backend's `normalizePlateNumber` produces.
///
/// Formats recognised:
///  * Modern national series (c. 2013 onward): 3 letters + 4 digits,
///    e.g. `CAB-1234` -> `CAB1234`.
///  * Earlier letter series: 2 letters + 4 digits, e.g. `KA-1234`.
///  * Provincial plates (2000–2022): a province code (WP, CP, SP, NP, EP,
///    NW, NC, SG, UP) in front of the series, e.g. `WP CAB-1234`. The
///    province is not part of the nationally unique registration, so it
///    is dropped: `WP CAB-1234` -> `CAB1234`.
///  * Old numeric series: 1–3 digits + 4 digits, e.g. `65-1234` ->
///    `651234`. OCR only accepts these when a dash is visible between the
///    two groups, so years, prices and phone numbers are not read as
///    plates.
///
/// Numbers are issued sequentially (`AAA-9999` is followed by `AAB-0001`)
/// and owners can pay to take a number ahead of the active batch, so any
/// series/number combination can be real. The parser checks shape only,
/// never ranges.
class SriLankaPlate {
  const SriLankaPlate._();

  static const List<String> provinceCodes = [
    'WP', 'CP', 'SP', 'NP', 'EP', 'NW', 'NC', 'SG', 'UP', //
  ];

  static final String _prov = provinceCodes.join('|');

  /// Characters that appear between plate groups: spaces, line breaks,
  /// hyphen / en dash / em dash, and dots or colons OCR reads from bolts
  /// and the embossed separator.
  static const String _sep = r'[\s\-–—.·:_]';
  static const String _dash = r'[\-–—]';

  static final RegExp _canonicalLetterSeries =
      RegExp('^(?:$_prov)?([A-Z]{2,3})([0-9]{4})\$');
  static final RegExp _canonicalNumeric = RegExp(r'^[0-9]{5,7}$');

  static final RegExp _letterSeriesInText = RegExp(
    '(?<![A-Z0-9])(?:(?:$_prov)$_sep+)?([A-Z]{2,3})$_sep*([0-9]{4})(?![A-Z0-9])',
  );
  static final RegExp _numericSeriesInText = RegExp(
    '(?<![A-Z0-9])([0-9]{1,3})\\s*$_dash\\s*([0-9]{4})(?![A-Z0-9])',
  );

  /// Older NC plates carry a small "D" security mark between the series
  /// and the number. It is not part of the registration.
  static final RegExp _ncSecurityMark =
      RegExp(r'\bNC[\s\-]+D[\s\-]+(\d{4})\b');

  static final RegExp _letter = RegExp(r'[A-Z]');
  static final RegExp _digit = RegExp(r'[0-9]');
  static final RegExp _tokenSplit = RegExp(r'[^A-Z0-9]+');

  /// Uppercase alphanumerics only.
  static String clean(String text) =>
      text.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();

  /// Whether [text], once cleaned, is shaped like a registration
  /// (optionally still carrying its province code).
  static bool isPlateShaped(String text) {
    final cleaned = clean(text);
    return _canonicalLetterSeries.hasMatch(cleaned) ||
        _canonicalNumeric.hasMatch(cleaned);
  }

  /// Normalizes typed or already-parsed text to the canonical plate, or
  /// returns '' when it is not a valid registration. Never changes
  /// letters into digits or back: a silent guess could identify a
  /// different vehicle.
  static String canonical(String text) {
    final cleaned = clean(text);
    final letters = _canonicalLetterSeries.firstMatch(cleaned);
    if (letters != null) return '${letters[1]}${letters[2]}';
    if (_canonicalNumeric.hasMatch(cleaned)) return cleaned;
    return '';
  }

  /// Every plate read exactly (no character guessing) in one piece of
  /// OCR text.
  static Set<String> exactMatches(String text) {
    final upper = text
        .toUpperCase()
        .replaceAllMapped(_ncSecurityMark, (m) => 'NC ${m[1]}');
    final found = <String>{
      for (final m in _letterSeriesInText.allMatches(upper)) '${m[1]}${m[2]}',
      for (final m in _numericSeriesInText.allMatches(upper)) '${m[1]}${m[2]}',
    };
    if (found.isEmpty) {
      // Letters and digits glued together with no separator, e.g.
      // "WPCAB1234". Bare digit runs are not accepted here.
      final glued = canonical(upper);
      if (glued.isNotEmpty && !_canonicalNumeric.hasMatch(glued)) {
        found.add(glued);
      }
    }
    return dropPartialReads(found);
  }

  /// The single plate read exactly from [text], or '' when there is none
  /// or more than one (two plates in frame need a tighter shot).
  static String parse(String text) {
    final found = exactMatches(text);
    return found.length == 1 ? found.single : '';
  }

  /// The single plate read exactly across several OCR fragments (whole
  /// image, blocks, lines), or '' when none or several different plates.
  static String parseFragments(Iterable<String> fragments) {
    final found = dropPartialReads({
      for (final fragment in fragments) ...exactMatches(fragment),
    });
    return found.length == 1 ? found.single : '';
  }

  /// A read that clipped the first letter (`AB1234` out of `CAB-1234`) is
  /// the same plate, not a second one, so drop any candidate that is the
  /// tail of a longer candidate.
  static Set<String> dropPartialReads(Set<String> candidates) {
    return candidates
        .where((c) => !candidates.any((o) => o != c && o.endsWith(c)))
        .toSet();
  }

  static const Map<String, String> _digitToLetter = {
    '0': 'O', '1': 'I', '2': 'Z', '4': 'A', '5': 'S', '6': 'G', '7': 'T',
    '8': 'B', //
  };
  static const Map<String, String> _letterToDigit = {
    'O': '0', 'D': '0', 'Q': '0', 'U': '0', 'I': '1', 'L': '1', 'J': '1',
    'Z': '2', 'S': '5', 'G': '6', 'T': '7', 'B': '8', 'A': '4', //
  };

  /// Best guess at a plate when no exact read was found, fixing the usual
  /// OCR look-alikes by position (series letters first, then four digits):
  /// `CBR 67O7` -> `CBR6707`, `C8R 6797` -> `CBR6797`. At most two
  /// characters are changed; returns '' when nothing is close enough.
  ///
  /// Only ever used to pre-fill the confirmation box the officer checks
  /// before a lookup, never to look a vehicle up on its own.
  static String suggest(Iterable<String> fragments) {
    var best = '';
    var bestFixes = 3;
    for (final fragment in fragments) {
      final tokens = fragment
          .toUpperCase()
          .split(_tokenSplit)
          .where((t) => t.isNotEmpty)
          .toList();
      for (var start = 0; start < tokens.length; start++) {
        var joined = '';
        for (var end = start; end < tokens.length && end < start + 4; end++) {
          joined += tokens[end];
          if (joined.length > 9) break;
          final guess = _fixLookAlikes(joined);
          if (guess != null && guess.fixes < bestFixes) {
            best = guess.plate;
            bestFixes = guess.fixes;
          }
        }
      }
    }
    return best;
  }

  static ({String plate, int fixes})? _fixLookAlikes(String joined) {
    var s = joined;
    if ((s.length == 8 || s.length == 9) &&
        provinceCodes.contains(s.substring(0, 2))) {
      s = s.substring(2);
    }
    if (s.length != 6 && s.length != 7) return null;
    final seriesLength = s.length - 4;

    // Needs at least one real letter and two real digits in the right
    // places to be a plate rather than arbitrary text.
    final realLetters =
        _letter.allMatches(s.substring(0, seriesLength)).length;
    final realDigits = _digit.allMatches(s.substring(seriesLength)).length;
    if (realLetters < 1 || realDigits < 2) return null;

    var fixes = 0;
    final out = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final ch = s[i];
      final wantLetter = i < seriesLength;
      if (wantLetter == _letter.hasMatch(ch)) {
        out.write(ch);
        continue;
      }
      final swapped = wantLetter ? _digitToLetter[ch] : _letterToDigit[ch];
      if (swapped == null) return null;
      out.write(swapped);
      fixes++;
    }
    return (plate: out.toString(), fixes: fixes);
  }
}
