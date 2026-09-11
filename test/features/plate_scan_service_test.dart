import 'package:amica_mobile_app/features/plate_scan/models/vehicle_status.dart';
import 'package:amica_mobile_app/features/plate_scan/services/plate_scan_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = PlateScanService();

  group('cleanPlateText', () {
    test('strips separators and uppercases, matching plate_text_cleaner.py',
        () {
      expect(service.cleanPlateText('wp ca-1234'), 'WPCA1234');
      expect(service.cleanPlateText('NW TI-9982'), 'NWTI9982');
      expect(service.cleanPlateText(' ka.05/ab 1234 '), 'KA05AB1234');
    });

    test('drops characters OCR picks up around the plate face', () {
      expect(service.cleanPlateText('★ WP CA 1234 ★'), 'WPCA1234');
      expect(service.cleanPlateText('WP\nCA\n1234'), 'WPCA1234');
    });

    test('returns empty for text with no letters or digits', () {
      expect(service.cleanPlateText(''), '');
      expect(service.cleanPlateText('--- ///'), '');
    });
  });

  group('looksLikePlate', () {
    test('accepts plates that mix letters and digits', () {
      expect(service.looksLikePlate('WPCA1234'), isTrue);
      expect(service.looksLikePlate('NWTI9982'), isTrue);
      expect(service.looksLikePlate('CAB1234'), isTrue);
    });

    test('rejects letters-only and digits-only text', () {
      // A badge or dealer sticker ML Kit also read in the frame.
      expect(service.looksLikePlate('TOYOTA'), isFalse);
      expect(service.looksLikePlate('9982'), isFalse);
    });

    test('rejects text that is too short or too long to be a plate', () {
      expect(service.looksLikePlate('A1'), isFalse);
      expect(service.looksLikePlate('WPCA1234567890'), isFalse);
    });
  });

  group('VehicleStatus.fromFirestore', () {
    test('reports unknown with guidance when no record exists', () {
      final status = VehicleStatus.fromFirestore('WPCA1234', null);

      expect(status.plateNumber, 'WPCA1234');
      expect(status.status, VehicleRiskStatus.unknown);
      expect(status.reportsCount, 0);
      expect(status.notes, isNotNull);
    });

    test('maps a reported vehicle record', () {
      final status = VehicleStatus.fromFirestore('WPCA9876', {
        'plateNumber': 'WP CA 9876',
        'status': 'reported',
        'reportsCount': 3,
        'riskLevel': 'high',
        'notes': 'Multiple rider reports.',
      });

      expect(status.plateNumber, 'WP CA 9876');
      expect(status.status, VehicleRiskStatus.reported);
      expect(status.reportsCount, 3);
      expect(status.riskLevel, 'high');
      expect(status.notes, 'Multiple rider reports.');
    });

    test('falls back to unknown for an unrecognized status value', () {
      final status = VehicleStatus.fromFirestore('WPCA1111', {
        'status': 'under-review',
        'reportsCount': 2.0,
      });

      expect(status.status, VehicleRiskStatus.unknown);
      expect(status.reportsCount, 2);
      expect(status.notes, isNull);
    });
  });
}
