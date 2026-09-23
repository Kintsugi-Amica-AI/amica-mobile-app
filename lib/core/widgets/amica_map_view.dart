import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
    this.routeColor = const Color(0xFF22D3EE),
    this.mapPadding = EdgeInsets.zero,
    this.showMyLocation = false,
    this.onTap,
    this.onDestinationDragged,
    this.captureGestures = false,
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
  final Color routeColor;

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

  @override
  State<AmicaMapView> createState() => _AmicaMapViewState();
}

class _AmicaMapViewState extends State<AmicaMapView> {
  GoogleMapController? _controller;

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
  void didUpdateWidget(covariant AmicaMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final routeChanged = !listEquals(oldWidget.routePoints, widget.routePoints);
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
    if (routeChanged && widget.routePoints.length > 1 && !pickedOnMap) {
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
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRose,
          ),
        ),
    };
  }

  Set<Polyline> _polylines() {
    if (widget.routePoints.length < 2) {
      return const {};
    }
    return {
      Polyline(
        polylineId: const PolylineId('amica-route'),
        points: widget.routePoints,
        color: widget.routeColor,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    };
  }

  /// Every point the camera should keep in view.
  List<LatLng> _pointsToFit() {
    final destination = _destinationPosition;
    return [
      if (widget.showStartMarker || destination == null) _centerPosition,
      if (destination != null) destination,
      ...widget.routePoints,
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
    final map = GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _destinationPosition ?? _centerPosition,
        zoom: 15,
      ),
      style: _nightMapStyle,
      markers: _markers(),
      polylines: _polylines(),
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
      myLocationButtonEnabled: widget.showMyLocation,
      myLocationEnabled: widget.showMyLocation,
      zoomControlsEnabled: true,
      mapToolbarEnabled: false,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: widget.height == null
          ? map
          : SizedBox(
              height: widget.height,
              width: double.infinity,
              child: map,
            ),
    );
  }

  bool _samePosition(LatLng first, LatLng second) {
    return first.latitude == second.latitude &&
        first.longitude == second.longitude;
  }
}

/// A violet-tinted night map style so the map blends into Amica's
/// futuristic dark theme instead of showing the default light basemap.
const String _nightMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#170b2e"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#170b2e"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#7b7299"}]},
  {"featureType": "administrative", "elementType": "geometry", "stylers": [{"color": "#3d2c66"}]},
  {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#8f86ad"}]},
  {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#1c2b28"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#241640"}]},
  {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#1b1030"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#b2a8d6"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#2c1f52"}]},
  {"featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [{"color": "#22d3ee"}, {"weight": 0.2}]},
  {"featureType": "transit", "elementType": "geometry", "stylers": [{"color": "#241640"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0a0417"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#5b21b6"}]}
]
''';
