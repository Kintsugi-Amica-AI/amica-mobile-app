import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../l10n/generated/app_localizations.dart';
import '../constants/app_colors.dart';
import 'glass_card.dart';

/// Amica's map.
///
/// Restyled for Blossom: a soft pastel basemap by day and a deep aubergine
/// one at night (following the app theme, not the old always-dark violet),
/// hand-drawn markers instead of Google's default pins, a route drawn in
/// the brand colour with a white casing, and frosted-glass zoom / recentre
/// buttons in place of Google's grey +/- controls.
class AmicaMapView extends StatefulWidget {
  const AmicaMapView({
    required this.latitude,
    required this.longitude,
    super.key,
    this.height = 240,
    this.borderRadius = 20,
    this.markerTitle = 'Current location',
    this.destinationLatitude,
    this.destinationLongitude,
    this.destinationTitle = 'Destination',
    this.showStartMarker = true,
    this.routePoints = const [],
    this.routeColor,
    this.mapPadding = EdgeInsets.zero,
    this.showMyLocation = false,
    this.onTap,
    this.onDestinationDragged,
    this.captureGestures = false,
    this.showControls = true,
    this.routeLegs = const [],
    this.transitStops = const [],
    this.onTransitStopTap,
  });

  final double latitude;
  final double longitude;

  /// Fixed height, or null to fill the space the parent gives it.
  final double? height;
  final double borderRadius;
  final String markerTitle;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final String destinationTitle;
  final bool showStartMarker;

  /// Suggested route drawn as a line between start and destination.
  final List<LatLng> routePoints;

  /// Defaults to the theme's brand accent.
  final Color? routeColor;

  /// Space covered by overlays (for example a bottom sheet), so markers,
  /// the route and Google's own buttons are kept out from under them.
  final EdgeInsets mapPadding;

  /// Shows the live blue location dot and Google's re-centre button.
  /// Needs location permission, which the journey flows already ask for.
  final bool showMyLocation;
  final void Function(double latitude, double longitude)? onTap;

  /// When set, the destination marker becomes draggable and this is called
  /// with its new position once the drag ends.
  final void Function(double latitude, double longitude)? onDestinationDragged;

  /// When true the map claims all touch gestures (pan, pinch, rotate) so it
  /// stays movable even when placed inside a scrolling parent like ListView.
  final bool captureGestures;

  /// Shows the frosted zoom / recentre / fit-route buttons.
  final bool showControls;

  /// A multi-part trip (walk → bus/train → walk). Walks are drawn dotted,
  /// rides solid. Used instead of [routePoints] for bus and train trips.
  final List<MapRouteLeg> routeLegs;

  /// Bus stops / stations: the chosen get-on and get-off stops, plus nearby
  /// alternatives the rider can tap to choose instead.
  final List<MapTransitStop> transitStops;
  final void Function(MapTransitStop stop)? onTransitStopTap;

  @override
  State<AmicaMapView> createState() => _AmicaMapViewState();
}

class _AmicaMapViewState extends State<AmicaMapView> {
  GoogleMapController? _controller;

  BitmapDescriptor? _startIcon;
  BitmapDescriptor? _destinationIcon;

  /// [chosen bus, candidate bus, chosen train, candidate train]
  List<BitmapDescriptor>? _stopIcons;
  String? _iconsKey;

  /// The last destination the user picked directly on the map (tap or drag).
  /// The camera is not re-fitted for these, so the view stays where the
  /// user was looking instead of jumping away mid-selection.
  LatLng? _userPickedDestination;

  static final Set<Factory<OneSequenceGestureRecognizer>> _eagerGestures = {
    Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
  };

  LatLng get _centerPosition => LatLng(widget.latitude, widget.longitude);

  LatLng? get _destinationPosition {
    final latitude = widget.destinationLatitude;
    final longitude = widget.destinationLongitude;
    if (latitude == null || longitude == null) {
      return null;
    }
    return LatLng(latitude, longitude);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadMarkerIcons();
  }

  Future<void> _loadMarkerIcons() async {
    final c = Theme.of(context).amica;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final key = '${c.accent.toARGB32()}-${c.card.toARGB32()}-$dpr';
    if (key == _iconsKey) return;
    _iconsKey = key;
    try {
      final icons = await Future.wait([
        _AmicaMarkerPainter.you(c, dpr),
        _AmicaMarkerPainter.destination(c, dpr),
        _AmicaMarkerPainter.stop(c, dpr,
            icon: Icons.directions_bus_rounded, chosen: true),
        _AmicaMarkerPainter.stop(c, dpr,
            icon: Icons.directions_bus_rounded, chosen: false),
        _AmicaMarkerPainter.stop(c, dpr,
            icon: Icons.train_rounded, chosen: true),
        _AmicaMarkerPainter.stop(c, dpr,
            icon: Icons.train_rounded, chosen: false),
      ]);
      if (!mounted || _iconsKey != key) return;
      setState(() {
        _startIcon = icons[0];
        _destinationIcon = icons[1];
        _stopIcons = icons.sublist(2);
      });
    } catch (_) {
      // Keep Google's default pins if drawing fails for any reason.
    }
  }

  @override
  void didUpdateWidget(covariant AmicaMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final routeChanged =
        !listEquals(oldWidget.routePoints, widget.routePoints) ||
            _legsSignature(oldWidget.routeLegs) !=
                _legsSignature(widget.routeLegs);
    final markersChanged = oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude ||
        oldWidget.destinationLatitude != widget.destinationLatitude ||
        oldWidget.destinationLongitude != widget.destinationLongitude;

    final destination = _destinationPosition;
    final pickedOnMap = destination != null &&
        _userPickedDestination != null &&
        _samePosition(destination, _userPickedDestination!);

    // A fresh route is framed, unless it leads to a spot the user just picked
    // by hand: then they are fine-tuning and the view must stay put.
    final hasRoute =
        widget.routePoints.length > 1 || widget.routeLegs.isNotEmpty;
    if (routeChanged && hasRoute && !pickedOnMap) {
      _moveCameraToMarkers();
      return;
    }

    if (markersChanged) {
      final centerUnchangedOrPicked =
          (oldWidget.latitude == widget.latitude &&
                  oldWidget.longitude == widget.longitude) ||
              (_userPickedDestination != null &&
                  _samePosition(_centerPosition, _userPickedDestination!));
      if (pickedOnMap && centerUnchangedOrPicked) {
        return;
      }
      _moveCameraToMarkers();
    }
  }

  void _handleUserPick(
    LatLng position,
    void Function(double latitude, double longitude) callback,
  ) {
    _userPickedDestination = position;
    callback(position.latitude, position.longitude);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Set<Marker> _markers() {
    final destination = _destinationPosition;
    return {
      if (widget.showStartMarker)
        Marker(
          markerId: const MarkerId('amica-start-location-marker'),
          position: _centerPosition,
          infoWindow: InfoWindow(title: widget.markerTitle),
          icon: _startIcon ??
              BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueViolet,
              ),
          anchor: _startIcon == null
              ? const Offset(0.5, 1)
              : const Offset(0.5, 0.5),
        ),
      if (destination != null)
        Marker(
          markerId: const MarkerId('amica-destination-marker'),
          position: destination,
          infoWindow: InfoWindow(title: widget.destinationTitle),
          draggable: widget.onDestinationDragged != null,
          onDragEnd: widget.onDestinationDragged == null
              ? null
              : (position) =>
                  _handleUserPick(position, widget.onDestinationDragged!),
          icon: _destinationIcon ??
              BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueMagenta,
              ),
          anchor: const Offset(0.5, 1),
        ),
      for (final stop in widget.transitStops)
        Marker(
          markerId: MarkerId('amica-stop-${stop.role.name}-${stop.id}'),
          position: stop.position,
          infoWindow: InfoWindow(title: stop.name),
          icon: _stopIconFor(stop),
          anchor: const Offset(0.5, 0.5),
          onTap: widget.onTransitStopTap == null
              ? null
              : () => widget.onTransitStopTap!(stop),
        ),
    };
  }

  BitmapDescriptor _stopIconFor(MapTransitStop stop) {
    final icons = _stopIcons;
    if (icons == null) {
      return BitmapDescriptor.defaultMarkerWithHue(
        stop.role == MapStopRole.candidate
            ? BitmapDescriptor.hueAzure
            : BitmapDescriptor.hueViolet,
      );
    }
    final chosen = stop.role != MapStopRole.candidate;
    return icons[(stop.train ? 2 : 0) + (chosen ? 0 : 1)];
  }

  static String _legsSignature(List<MapRouteLeg> legs) {
    if (legs.isEmpty) return '';
    final first = legs.first.points;
    final last = legs.last.points;
    return '${legs.length}:${first.isEmpty ? '' : first.first}:'
        '${last.isEmpty ? '' : last.last}:'
        '${legs.fold<int>(0, (n, l) => n + l.points.length)}';
  }

  Set<Polyline> _polylines(AmicaColors c) {
    if (widget.routeLegs.isNotEmpty) {
      return {
        for (var i = 0; i < widget.routeLegs.length; i++)
          if (widget.routeLegs[i].points.length > 1) ...[
            if (widget.routeLegs[i].walking)
              // Walks: dotted, so "you walk this bit" reads at a glance.
              Polyline(
                polylineId: PolylineId('amica-leg-$i'),
                points: widget.routeLegs[i].points,
                color: c.accentInk,
                width: 5,
                zIndex: 2,
                patterns: [PatternItem.dot, PatternItem.gap(10)],
                jointType: JointType.round,
              )
            else ...[
              Polyline(
                polylineId: PolylineId('amica-leg-$i-casing'),
                points: widget.routeLegs[i].points,
                color: c.card.withValues(alpha: 0.95),
                width: 10,
                zIndex: 0,
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
                jointType: JointType.round,
              ),
              Polyline(
                polylineId: PolylineId('amica-leg-$i'),
                points: widget.routeLegs[i].points,
                color: widget.routeColor ?? c.accent,
                width: 6,
                zIndex: 1,
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
                jointType: JointType.round,
              ),
            ],
          ],
      };
    }
    if (widget.routePoints.length < 2) {
      return const {};
    }
    return {
      // White casing under the line, so the route reads on any street.
      Polyline(
        polylineId: const PolylineId('amica-route-casing'),
        points: widget.routePoints,
        color: c.card.withValues(alpha: 0.95),
        width: 10,
        zIndex: 0,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
      Polyline(
        polylineId: const PolylineId('amica-route'),
        points: widget.routePoints,
        color: widget.routeColor ?? c.accent,
        width: 6,
        zIndex: 1,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    };
  }

  Future<void> _zoomBy(double delta) async {
    await _controller?.animateCamera(CameraUpdate.zoomBy(delta));
  }

  Future<void> _recenter() async {
    await _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(_centerPosition, 16),
    );
  }

  /// Every point the camera should keep in view.
  List<LatLng> _pointsToFit() {
    final destination = _destinationPosition;
    return [
      if (widget.showStartMarker || destination == null) _centerPosition,
      if (destination != null) destination,
      ...widget.routePoints,
      for (final leg in widget.routeLegs) ...leg.points,
      for (final stop in widget.transitStops)
        if (stop.role != MapStopRole.candidate) stop.position,
    ];
  }

  void _moveCameraToMarkers() {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      final points = _pointsToFit();
      final fallbackTarget = _destinationPosition ?? _centerPosition;
      try {
        final bounds = _boundsOf(points);
        if (bounds == null) {
          await controller.animateCamera(
            CameraUpdate.newLatLngZoom(fallbackTarget, 15),
          );
          return;
        }
        await controller.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 64),
        );
      } catch (_) {
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(fallbackTarget, 15),
        );
      }
    });
  }

  /// Bounds around [points], or null when they are all the same spot.
  LatLngBounds? _boundsOf(List<LatLng> points) {
    if (points.isEmpty) {
      return null;
    }
    var south = points.first.latitude;
    var north = points.first.latitude;
    var west = points.first.longitude;
    var east = points.first.longitude;
    for (final point in points.skip(1)) {
      south = point.latitude < south ? point.latitude : south;
      north = point.latitude > north ? point.latitude : north;
      west = point.longitude < west ? point.longitude : west;
      east = point.longitude > east ? point.longitude : east;
    }
    if (south == north && west == east) {
      return null;
    }
    return LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);
    final map = GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _destinationPosition ?? _centerPosition,
        zoom: 15,
      ),
      style: isDark ? _nightMapStyle : _dayMapStyle,
      markers: _markers(),
      polylines: _polylines(c),
      padding: widget.mapPadding,
      onMapCreated: (controller) {
        _controller = controller;
        _moveCameraToMarkers();
      },
      gestureRecognizers: widget.captureGestures
          ? _eagerGestures
          : const <Factory<OneSequenceGestureRecognizer>>{},
      scrollGesturesEnabled: true,
      zoomGesturesEnabled: true,
      rotateGesturesEnabled: true,
      tiltGesturesEnabled: false,
      onTap: widget.onTap == null
          ? null
          : (position) => _handleUserPick(position, widget.onTap!),
      // Google's own buttons are replaced by the frosted ones below.
      myLocationButtonEnabled: false,
      myLocationEnabled: widget.showMyLocation,
      zoomControlsEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
    );

    final small = widget.height != null && widget.height! < 220;
    final controls = !widget.showControls
        ? null
        : Positioned(
            top: widget.mapPadding.top + 12,
            right: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MapButton(
                  icon: Icons.my_location_rounded,
                  tooltip: loc.mapRecenter,
                  onTap: _recenter,
                ),
                if (_destinationPosition != null) ...[
                  const SizedBox(height: 8),
                  _MapButton(
                    icon: Icons.route_rounded,
                    tooltip: loc.mapShowWholeRoute,
                    onTap: _moveCameraToMarkers,
                  ),
                ],
                if (!small) ...[
                  const SizedBox(height: 8),
                  _MapButton(
                    icon: Icons.add_rounded,
                    tooltip: loc.mapZoomIn,
                    onTap: () => _zoomBy(1),
                  ),
                  const SizedBox(height: 8),
                  _MapButton(
                    icon: Icons.remove_rounded,
                    tooltip: loc.mapZoomOut,
                    onTap: () => _zoomBy(-1),
                  ),
                ],
              ],
            ),
          );

    final layered = Stack(
      children: [
        Positioned.fill(child: map),
        if (controls != null) controls,
      ],
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: widget.height == null
          ? layered
          : SizedBox(
              height: widget.height,
              width: double.infinity,
              child: layered,
            ),
    );
  }

  bool _samePosition(LatLng first, LatLng second) {
    return first.latitude == second.latitude &&
        first.longitude == second.longitude;
  }
}

/// One drawn part of a multi-part trip.
class MapRouteLeg {
  const MapRouteLeg({required this.points, this.walking = false});

  final List<LatLng> points;

  /// Walks are drawn dotted; rides solid.
  final bool walking;
}

enum MapStopRole { board, alight, candidate }

/// A bus stop / station marker.
class MapTransitStop {
  const MapTransitStop({
    required this.id,
    required this.name,
    required this.position,
    required this.role,
    this.train = false,
  });

  final String id;
  final String name;
  final LatLng position;
  final MapStopRole role;
  final bool train;
}

/// A frosted-glass round map button.
class _MapButton extends StatelessWidget {
  const _MapButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: AmicaGlass(
          shape: BoxShape.circle,
          strong: true,
          // No blur over the live map (see JourneyGlassSheet).
          blur: 0,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(icon, size: 20, color: c.accentInk),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws Amica's map markers on a canvas, so no image assets are needed and
/// they follow the theme.
class _AmicaMarkerPainter {
  const _AmicaMarkerPainter._();

  static Future<BitmapDescriptor> _render(
    Size logicalSize,
    double dpr,
    void Function(Canvas canvas) paint,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(dpr);
    paint(canvas);
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      (logicalSize.width * dpr).ceil(),
      (logicalSize.height * dpr).ceil(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    picture.dispose();
    image.dispose();
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      imagePixelRatio: dpr,
    );
  }

  /// "You are here": a soft lavender halo, white ring, gradient core.
  static Future<BitmapDescriptor> you(AmicaColors c, double dpr) {
    const size = Size(48, 48);
    const center = Offset(24, 24);
    return _render(size, dpr, (canvas) {
      canvas.drawCircle(
        center,
        22,
        Paint()..color = c.accent.withValues(alpha: 0.22),
      );
      canvas.drawCircle(
        center.translate(0, 1.5),
        12.5,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
      );
      canvas.drawCircle(center, 12.5, Paint()..color = Colors.white);
      canvas.drawCircle(
        center,
        8.5,
        Paint()
          ..shader = ui.Gradient.linear(
            center.translate(-8, -8),
            center.translate(8, 8),
            [c.accent, c.accentEnd],
          ),
      );
    });
  }

  /// A bus stop / station: the chosen ones are gradient discs with a white
  /// icon; alternatives are smaller white discs with an accent ring.
  static Future<BitmapDescriptor> stop(
    AmicaColors c,
    double dpr, {
    required IconData icon,
    required bool chosen,
  }) {
    final size = chosen ? const Size(40, 40) : const Size(30, 30);
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 3;
    return _render(size, dpr, (canvas) {
      canvas.drawCircle(
        center.translate(0, 1.2),
        r,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
      if (chosen) {
        canvas.drawCircle(
          center,
          r,
          Paint()
            ..shader = ui.Gradient.linear(
              center.translate(-r, -r),
              center.translate(r, r),
              [c.accent, c.accentEnd],
            ),
        );
        canvas.drawCircle(
          center,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..color = Colors.white,
        );
      } else {
        canvas.drawCircle(center, r, Paint()..color = Colors.white);
        canvas.drawCircle(
          center,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = c.accent,
        );
      }
      final glyph = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontSize: chosen ? 19 : 14,
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            color: chosen ? Colors.white : c.accent,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      glyph.paint(canvas, center - Offset(glyph.width / 2, glyph.height / 2));
    });
  }

  /// Destination: a gradient teardrop pin with a white heart.
  static Future<BitmapDescriptor> destination(AmicaColors c, double dpr) {
    const size = Size(46, 60);
    return _render(size, dpr, (canvas) {
      const head = Offset(23, 21);
      const r = 17.0;
      // Teardrop: circle head plus two tangents meeting at the tip.
      const tip = Offset(23, 56);
      final path = Path()..addOval(Rect.fromCircle(center: head, radius: r));
      final angle = math.acos(r / (tip.dy - head.dy));
      final left = Offset(
        head.dx - r * math.sin(angle),
        head.dy + r * math.cos(angle),
      );
      final right = Offset(
        head.dx + r * math.sin(angle),
        head.dy + r * math.cos(angle),
      );
      path
        ..moveTo(left.dx, left.dy)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(right.dx, right.dy)
        ..close();

      // Ground shadow.
      canvas.drawOval(
        Rect.fromCenter(center: tip.translate(0, 1), width: 14, height: 5),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
      canvas.drawPath(
        path,
        Paint()
          ..shader = ui.Gradient.linear(
            const Offset(6, 4),
            const Offset(40, 50),
            [c.accent, c.accentEnd],
          ),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white,
      );
      canvas.drawCircle(head, 10.5, Paint()..color = Colors.white);

      final heart = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(Icons.favorite_rounded.codePoint),
          style: TextStyle(
            fontSize: 13,
            fontFamily: Icons.favorite_rounded.fontFamily,
            package: Icons.favorite_rounded.fontPackage,
            color: c.accentEnd,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      heart.paint(
        canvas,
        head - Offset(heart.width / 2, heart.height / 2),
      );
    });
  }
}

/// Soft pastel day basemap: pale roads, lavender-grey land, powder-blue
/// water, quiet labels. Keeps the route and pins as the loudest things.
const String _dayMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#f7f2f7"}]},
  {"elementType": "labels.icon", "stylers": [{"saturation": -60}, {"lightness": 20}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#6f6180"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#ffffff"}]},
  {"featureType": "administrative", "elementType": "geometry.stroke", "stylers": [{"color": "#e3d8e6"}]},
  {"featureType": "landscape.man_made", "elementType": "geometry", "stylers": [{"color": "#f3edf4"}]},
  {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#efe7f1"}]},
  {"featureType": "poi.business", "stylers": [{"visibility": "off"}]},
  {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#dff0e4"}]},
  {"featureType": "poi.park", "elementType": "labels.text.fill", "stylers": [{"color": "#5d8a6b"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#ffffff"}]},
  {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#ece3ee"}]},
  {"featureType": "road.arterial", "elementType": "labels.text.fill", "stylers": [{"color": "#7d6f8c"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#fde7ef"}]},
  {"featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [{"color": "#f6cfdd"}]},
  {"featureType": "transit.line", "elementType": "geometry", "stylers": [{"color": "#e6dcef"}]},
  {"featureType": "transit.station", "elementType": "geometry", "stylers": [{"color": "#efe7f1"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#d7e8f7"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#6d8fb0"}]}
]
''';

/// Deep aubergine night basemap — matte and low-glare, matching the
/// discreet dark theme.
const String _nightMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#120d1d"}]},
  {"elementType": "labels.icon", "stylers": [{"saturation": -60}, {"lightness": -35}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#120d1d"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#a898b8"}]},
  {"featureType": "administrative", "elementType": "geometry", "stylers": [{"color": "#2e2540"}]},
  {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#1a1426"}]},
  {"featureType": "poi.business", "stylers": [{"visibility": "off"}]},
  {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#15271f"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#251d38"}]},
  {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#120d1d"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#bcaecb"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#35284f"}]},
  {"featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [{"color": "#5a2a6e"}, {"weight": 0.4}]},
  {"featureType": "transit", "elementType": "geometry", "stylers": [{"color": "#251d38"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0b1830"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#6f8fb4"}]}
]
''';
