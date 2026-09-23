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
    this.markerTitle = 'Current location',
    this.destinationLatitude,
    this.destinationLongitude,
    this.destinationTitle = 'Destination',
    this.showStartMarker = true,
    this.onTap,
    this.onDestinationDragged,
    this.captureGestures = false,
  });

  final double latitude;
  final double longitude;
  final double height;
  final String markerTitle;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final String destinationTitle;
  final bool showStartMarker;
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
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude ||
        oldWidget.destinationLatitude != widget.destinationLatitude ||
        oldWidget.destinationLongitude != widget.destinationLongitude) {
      final destination = _destinationPosition;
      final pickedOnMap = destination != null &&
          _userPickedDestination != null &&
          _samePosition(destination, _userPickedDestination!);
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

  void _moveCameraToMarkers() {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      final destination = _destinationPosition;
      try {
        if (!widget.showStartMarker ||
            destination == null ||
            _samePosition(destination, _centerPosition)) {
          await controller.animateCamera(
            CameraUpdate.newLatLngZoom(destination ?? _centerPosition, 15),
          );
          return;
        }

        await controller.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(
                _smaller(_centerPosition.latitude, destination.latitude),
                _smaller(_centerPosition.longitude, destination.longitude),
              ),
              northeast: LatLng(
                _larger(_centerPosition.latitude, destination.latitude),
                _larger(_centerPosition.longitude, destination.longitude),
              ),
            ),
            64,
          ),
        );
      } catch (_) {
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(destination ?? _centerPosition, 15),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _destinationPosition ?? _centerPosition,
            zoom: 15,
          ),
          style: _nightMapStyle,
          markers: _markers(),
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
          myLocationButtonEnabled: false,
          myLocationEnabled: false,
          zoomControlsEnabled: true,
          mapToolbarEnabled: false,
        ),
      ),
    );
  }

  bool _samePosition(LatLng first, LatLng second) {
    return first.latitude == second.latitude &&
        first.longitude == second.longitude;
  }

  double _smaller(double first, double second) {
    return first < second ? first : second;
  }

  double _larger(double first, double second) {
    return first > second ? first : second;
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
