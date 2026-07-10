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

  @override
  State<AmicaMapView> createState() => _AmicaMapViewState();
}

class _AmicaMapViewState extends State<AmicaMapView> {
  GoogleMapController? _controller;

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
      _moveCameraToMarkers();
    }
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
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _destinationPosition ?? _centerPosition,
          zoom: 15,
        ),
        markers: _markers(),
        onMapCreated: (controller) {
          _controller = controller;
          _moveCameraToMarkers();
        },
        onTap: widget.onTap == null
            ? null
            : (position) => widget.onTap!(
                  position.latitude,
                  position.longitude,
                ),
        myLocationButtonEnabled: false,
        myLocationEnabled: false,
        zoomControlsEnabled: true,
        mapToolbarEnabled: false,
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
