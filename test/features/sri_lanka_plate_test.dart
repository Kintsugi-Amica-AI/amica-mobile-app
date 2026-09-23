import 'package:amica_mobile_app/features/plate_scan/utils/sri_lanka_plate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SriLankaPlate.parse', () {
    test('reads modern three-letter and older two-letter series', () {
      expect(SriLankaPlate.parse('CAB-1234'), 'CAB1234');
      expect(SriLankaPlate.parse('CAB–1234'), 'CAB1234');
      expect(SriLankaPlate.parse('KA 1234'), 'KA1234');
    });

    test('drops the province code from 2000-2022 provincial plates', () {
      expect(SriLankaPlate.parse('WP CAB-1234'), 'CAB1234');
      expect(SriLankaPlate.parse('WP KA-1234'), 'KA1234');
      expect(SriLankaPlate.parse('NW TI-9982'), 'TI9982');
      expect(SriLankaPlate.parse('WPCAB1234'), 'CAB1234');
      expect(SriLankaPlate.parse('SRI LANKA\nWP\nQA\n1234'), 'QA1234');
    });

    test('reads old numeric plates only when a dash separates the groups',
        () {
      expect(SriLankaPlate.parse('65-1234'), '651234');
      expect(SriLankaPlate.parse('301 - 4567'), '3014567');
      expect(SriLankaPlate.parse('2026 1234'), '');
      expect(SriLankaPlate.parse('Call 0771234567'), '');
    });

    test('treats a clipped read as the same plate, not a second one', () {
      expect(SriLankaPlate.parseFragments(['CAB 1234', 'AB 1234']),
          'CAB1234');
      expect(SriLankaPlate.parseFragments(['CAB 1234', 'CBR 6797']), '');
    });
  });

  group('SriLankaPlate.canonical', () {
    test('normalizes typed plates', () {
      expect(SriLankaPlate.canonical('wp cab-1234'), 'CAB1234');
      expect(SriLankaPlate.canonical('SPA1234'), 'SPA1234');
      expect(SriLankaPlate.canonical('65-1234'), '651234');
      expect(SriLankaPlate.canonical('TOYOTA'), '');
    });
  });

  group('SriLankaPlate.suggest', () {
    test('fixes OCR look-alikes by position for the officer to confirm', () {
      expect(SriLankaPlate.suggest(['CBR 67O7']), 'CBR6707');
      expect(SriLankaPlate.suggest(['C8R 6797']), 'CBR6797');
      expect(SriLankaPlate.suggest(['WP CB0-3286']), 'CBO3286');
    });

    test('does not invent plates from unrelated text', () {
      expect(SriLankaPlate.suggest(['TOYOTA 2026']), '');
      expect(SriLankaPlate.suggest(['hello world']), '');
    });
  });
}
