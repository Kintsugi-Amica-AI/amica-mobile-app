import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;

import 'package:amica_mobile_app/features/journey/services/route_change_monitor.dart';

void main() {
  // A straight road running east along latitude 6.9, about 2.2 km long.
  const road = [LatLng(6.9, 79.85), LatLng(6.9, 79.87)];

  group('RouteGeometry.distanceToRouteMeters', () {
    test('a point on the road is about zero metres away', () {
      final d = RouteGeometry.distanceToRouteMeters(6.9, 79.86, road);
      expect(d, lessThan(1));
    });

    test('a point north of the road is measured straight to the road', () {
      // 0.001 degrees of latitude is roughly 110 m.
      final d = RouteGeometry.distanceToRouteMeters(6.901, 79.86, road);
      expect(d, inInclusiveRange(105, 115));
    });

    test('past the end of the road it is measured to the end point', () {
      // 0.01 degrees of longitude beyond the end, roughly 1.1 km.
      final d = RouteGeometry.distanceToRouteMeters(6.9, 79.88, road);
      expect(d, inInclusiveRange(1050, 1150));
    });

    test('a route with fewer than two points is never near', () {
      expect(
        RouteGeometry.distanceToRouteMeters(6.9, 79.86, const [LatLng(6.9, 79.86)]),
        double.infinity,
      );
    });
  });

  test('metresBetween matches a known short distance', () {
    final d = RouteGeometry.metresBetween(6.9, 79.86, 6.901, 79.86);
    expect(d, inInclusiveRange(105, 115));
  });
}
