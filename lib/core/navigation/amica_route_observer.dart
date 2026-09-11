import 'package:flutter/material.dart';

/// Shared route observer so screens (like the live plate scanner) can pause
/// expensive work such as the camera when another screen is pushed on top,
/// and resume it when they become visible again.
final RouteObserver<PageRoute<dynamic>> amicaRouteObserver =
    RouteObserver<PageRoute<dynamic>>();
