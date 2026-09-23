import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/feature_flags.dart';
import '../../../core/navigation/amica_route_observer.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../journey/widgets/journey_visuals.dart';
import '../models/detection.dart';
import '../models/plate_scan_outcome.dart';
import '../models/vehicle_profile.dart';
import '../services/plate_scan_service.dart';
import '../services/vehicle_inspector.dart';
import '../services/vehicle_observation_service.dart';
import '../widgets/vehicle_labels.dart';
import '../widgets/vehicle_told_sheet.dart';
import '../utils/vision_log.dart';
import '../../../l10n/generated/app_localizations.dart';

class PlateScanScreen extends StatefulWidget {
  PlateScanScreen({
    super.key,
    PlateScanService? plateScanService,
    ImagePicker? imagePicker,
    VehicleInspector? vehicleInspector,
    VehicleObservationService? observationService,
  })  : plateScanService = plateScanService ?? const PlateScanService(),
        imagePicker = imagePicker ?? ImagePicker(),
        vehicleInspector = vehicleInspector ?? const VehicleInspector(),
        observationService =
            observationService ?? const VehicleObservationService();

  final PlateScanService plateScanService;
  final ImagePicker imagePicker;
  final VehicleInspector vehicleInspector;
  final VehicleObservationService observationService;

  @override
  State<PlateScanScreen> createState() => _PlateScanScreenState();
}

enum _ScanState { initializing, scanning, capturing, locked, error }

class _PlateScanScreenState extends State<PlateScanScreen>
    with WidgetsBindingObserver, RouteAware {
  final GlobalKey _previewBoxKey = GlobalKey();
  final GlobalKey _frameBoxKey = GlobalKey();

  CameraController? _controller;
  Timer? _autoScanTimer;
  String _lastCandidate = '';
  int _candidateCount = 0;
  bool _appActive = true;
  bool _isCapturing = false;
  bool _manualRequested = false;
  bool _isPausedByRoute = false;
  _ScanState _state = _ScanState.initializing;
  String? _errorMessage;
  String _statusMessage = '';
  late AppLocalizations _loc;
  bool _didInitCamera = false;

  /// What the ride app said the vehicle looks like ("What was I told?").
  VehicleExpectation _told = const VehicleExpectation();

  /// Whether a photo needs decoding for the on-device vision features.
  /// Both are off until their models are trained (see [FeatureFlags]).
  static const bool _visionEnabled =
      FeatureFlags.plateFinder || FeatureFlags.vehicleCheck;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loc = AppLocalizations.of(context);
    if (!_didInitCamera) {
      _didInitCamera = true;
      _statusMessage = _loc.plateScanStartingCamera;
      unawaited(_initializeCamera());
    }
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      amicaRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPushNext() {
    // Another screen (e.g. the result screen) was pushed on top of us.
    _isPausedByRoute = true;
  }

  @override
  void didPopNext() {
    // We're visible again after the screen above us was popped.
    _isPausedByRoute = false;
    _candidateCount = 0;
    _lastCandidate = '';
    if (_state == _ScanState.locked || _state == _ScanState.capturing) {
      setState(() {
        _state = _ScanState.scanning;
        _statusMessage = _loc.plateScanAlignPrompt;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    if (state == AppLifecycleState.resumed) {
      if (!(_controller?.value.isInitialized ?? false)) {
        unawaited(_initializeCamera());
      }
    }
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _state = _ScanState.initializing;
      _errorMessage = null;
      _statusMessage = _loc.plateScanStartingCamera;
    });

    try {
      final cameras = await availableCameras();
      if (!mounted) return;
      if (cameras.isEmpty) {
        setState(() {
          _state = _ScanState.error;
          _errorMessage = _loc.plateScanNoCamera;
        });
        return;
      }

      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _state = _ScanState.scanning;
        _statusMessage = _loc.plateScanAlignPrompt;
      });
      _autoScanTimer?.cancel();
      _autoScanTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        if (mounted && _appActive && _state == _ScanState.scanning) {
          unawaited(_captureAndAnalyze(automatic: true));
        }
      });
    } on CameraException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _state = _ScanState.error;
        _errorMessage = error.code == 'CameraAccessDenied'
            ? _loc.plateScanPermissionRequired
            : error.description ?? _loc.plateScanCameraStartFailed;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _state = _ScanState.error;
        _errorMessage = _loc.plateScanCameraStartFailed;
      });
    }
  }

  /// Measures where the scan frame overlay sits on top of the live camera
  /// preview, as fractions (0.0-1.0) of the preview's own bounds, so a
  /// captured photo can be cropped to just that region before OCR.
  ({double left, double top, double width, double height})?
      _computeCropFraction() {
    final previewBox =
        _previewBoxKey.currentContext?.findRenderObject() as RenderBox?;
    final frameBox =
        _frameBoxKey.currentContext?.findRenderObject() as RenderBox?;
    if (previewBox == null ||
        frameBox == null ||
        !previewBox.hasSize ||
        !frameBox.hasSize) {
      return null;
    }

    final previewSize = previewBox.size;
    if (previewSize.width <= 0 || previewSize.height <= 0) {
      return null;
    }

    final previewOrigin = previewBox.localToGlobal(Offset.zero);
    final frameOrigin = frameBox.localToGlobal(Offset.zero);
    final frameSize = frameBox.size;

    return (
      left: ((frameOrigin.dx - previewOrigin.dx) / previewSize.width)
          .clamp(0.0, 1.0),
      top: ((frameOrigin.dy - previewOrigin.dy) / previewSize.height)
          .clamp(0.0, 1.0),
      width: (frameSize.width / previewSize.width).clamp(0.05, 1.0),
      height: (frameSize.height / previewSize.height).clamp(0.05, 1.0),
    );
  }

  /// Takes a photo, finds the plate in it (or falls back to the guide
  /// frame crop), and reads the plate.
  ///
  /// Automatic scans run quietly in the background and never block the
  /// shutter. A shutter tap always ends with a lookup or a confirmation
  /// box, even when OCR could not read the plate exactly.
  Future<void> _captureAndAnalyze({bool automatic = false}) async {
    final controller = _controller;
    if (_isPausedByRoute ||
        controller == null ||
        !controller.value.isInitialized) {
      return;
    }
    if (_isCapturing) {
      // The camera is busy with a background scan. Queue the tap and run
      // it as soon as that scan finishes.
      if (!automatic) {
        _manualRequested = true;
        setState(() {
          _state = _ScanState.capturing;
          _statusMessage = _loc.plateScanReading;
          _errorMessage = null;
        });
      }
      return;
    }

    _isCapturing = true;
    if (!automatic) {
      setState(() {
        _state = _ScanState.capturing;
        _statusMessage = _loc.plateScanReading;
        _errorMessage = null;
      });
    }

    XFile? photo;
    String? analyzedPath;
    String? plateCropPath;
    try {
      photo = await controller.takePicture();
      final image = _visionEnabled
          ? await widget.vehicleInspector.loadUpright(photo.path)
          : null;

      // 1. The plate finder looks at the whole photo, so the plate does
      //    not have to sit inside the guide frame.
      final plateBox = image == null || !FeatureFlags.plateFinder
          ? null
          : await widget.vehicleInspector.findPlate(image);
      var read = const PlateRead();
      if (image != null && plateBox != null) {
        plateCropPath = await widget.vehicleInspector
            .writeCrop(image, plateBox, photo.path);
        if (plateCropPath != null) {
          // Camera photos are already upright, so rotations only waste time.
          read = await widget.plateScanService
              .readPlate(plateCropPath, tryRotations: false);
          visionLog('OCR on plate-finder crop: '
              '${read.found ? read.plate : 'no exact read (suggestion "${read.suggestion}")'}');
        }
      }

      // 2. No plate found, or it did not read: the guide-frame crop, as
      //    before the plate finder existed.
      if (!read.found) {
        final cropFraction = _computeCropFraction();
        analyzedPath = cropFraction == null
            ? photo.path
            : await widget.plateScanService.cropToFractionalRegion(
                photo.path,
                left: cropFraction.left,
                top: cropFraction.top,
                width: cropFraction.width,
                height: cropFraction.height,
              );
        final framed = await widget.plateScanService
            .readPlate(analyzedPath, tryRotations: false);
        visionLog('OCR on scan-frame crop: '
            '${framed.found ? framed.plate : 'no exact read (suggestion "${framed.suggestion}")'}');
        if (framed.found || read.suggestion.isEmpty) read = framed;
        if (!automatic && !read.found && analyzedPath != photo.path) {
          // The plate may sit partly outside the guide frame.
          final full = await widget.plateScanService
              .readPlate(photo.path, tryRotations: false);
          if (full.found || read.suggestion.isEmpty) read = full;
        }
      }

      if (!mounted) return;

      if (automatic && !_manualRequested) {
        if (read.found) {
          _candidateCount =
              read.plate == _lastCandidate ? _candidateCount + 1 : 1;
          _lastCandidate = read.plate;
          if (_candidateCount >= 2) {
            await _lockAndLookUp(read.plate, image: image, plateBox: plateBox);
          } else {
            setState(() => _statusMessage = _loc.plateScanDetected(read.plate));
          }
        } else {
          _candidateCount = 0;
          setState(() => _statusMessage = _loc.plateScanNotDetected);
        }
      } else if (read.found) {
        // A shutter tap: one exact read is enough.
        await _lockAndLookUp(read.plate, image: image, plateBox: plateBox);
      } else if (!automatic) {
        await _confirmAndLookUp(read.suggestion,
            image: image, plateBox: plateBox);
      }
      // automatic && _manualRequested && nothing found: the queued tap
      // takes its own photo in `finally`.
    } on PlateScanException catch (error) {
      if (mounted) {
        setState(() {
          _state = _ScanState.scanning;
          _statusMessage = _loc.plateScanAlignPrompt;
          _errorMessage = error.message;
        });
      }
    } catch (_) {
      if (mounted && !automatic) {
        setState(() {
          _state = _ScanState.scanning;
          _statusMessage = _loc.plateScanAlignPrompt;
        });
      }
    } finally {
      _isCapturing = false;
      final capturedPath = photo?.path;
      if (capturedPath != null) {
        unawaited(
          File(capturedPath).delete().catchError((_) => File(capturedPath)),
        );
      }
      if (analyzedPath != null && analyzedPath != capturedPath) {
        unawaited(
          File(analyzedPath).delete().catchError((_) => File(analyzedPath!)),
        );
      }
      if (plateCropPath != null) {
        unawaited(
          File(plateCropPath).delete().catchError((_) => File(plateCropPath!)),
        );
      }
      if (mounted && _manualRequested && !_isPausedByRoute) {
        _manualRequested = false;
        unawaited(_captureAndAnalyze());
      } else if (mounted && _state == _ScanState.capturing) {
        setState(() {
          _state = _ScanState.scanning;
          _statusMessage = _loc.plateScanAlignPrompt;
        });
      }
    }
  }

  /// Looks the plate up and, when the photo is at hand, checks the
  /// vehicle's type and colour against what she was told and what the
  /// community has seen. Typed plates have no photo: the result screen
  /// then shows the plate result alone.
  Future<void> _lockAndLookUp(
    String plateText, {
    img.Image? image,
    PixelBox? plateBox,
  }) async {
    // Without the vehicle check the photo is not needed past OCR.
    if (!FeatureFlags.vehicleCheck) image = null;
    _manualRequested = false;
    setState(() {
      _state = _ScanState.locked;
      _statusMessage = _loc.plateScanChecking(plateText);
    });

    try {
      final inspectionFuture = image == null
          ? Future.value(VehicleInspection.empty)
          : widget.vehicleInspector
              .inspect(image, plate: plateBox)
              .catchError((Object _) => VehicleInspection.empty);
      final status = await widget.plateScanService.checkVehicle(plateText);
      final inspection = await inspectionFuture;
      if (!mounted) {
        return;
      }
      Object arguments = status;
      if (image != null) {
        arguments = PlateScanOutcome.evaluate(
          status: status,
          told: _told,
          inspection: inspection,
        );
        unawaited(widget.observationService
            .record(status.normalizedPlateNumber, inspection));
      }
      await Navigator.pushNamed(context, AppRoutes.plateResult,
          arguments: arguments);
    } on PlateScanException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _state = _ScanState.scanning;
        _statusMessage = _loc.plateScanAlignPrompt;
        _errorMessage = error.message;
      });
    }
  }

  /// Shows what OCR could make out (possibly nothing) so the officer can
  /// confirm or type the plate, then looks it up.
  Future<void> _confirmAndLookUp(
    String suggestion, {
    img.Image? image,
    PixelBox? plateBox,
  }) async {
    final plate = await _promptForPlate(
      title: _loc.plateScanConfirmTitle,
      message: suggestion.isEmpty
          ? _loc.plateScanUnreadMessage
          : _loc.plateScanConfirmMessage,
      initialText: suggestion,
    );
    if (!mounted) return;
    if (plate == null) {
      setState(() {
        _state = _ScanState.scanning;
        _statusMessage = _loc.plateScanAlignPrompt;
      });
      return;
    }
    await _lockAndLookUp(plate, image: image, plateBox: plateBox);
  }

  Future<void> _scanFromGallery() async {
    if (_isCapturing) return;
    _isCapturing = true;
    setState(() {
      _state = _ScanState.capturing;
      _errorMessage = null;
    });

    try {
      final photo = await widget.imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 90,
      );

      if (photo == null) {
        if (!mounted) return;
        setState(() => _state = _ScanState.scanning);
        return;
      }

      final image = _visionEnabled
          ? await widget.vehicleInspector.loadUpright(photo.path)
          : null;
      final plateBox = image == null || !FeatureFlags.plateFinder
          ? null
          : await widget.vehicleInspector.findPlate(image);
      var read = const PlateRead();
      if (image != null && plateBox != null) {
        final cropPath = await widget.vehicleInspector
            .writeCrop(image, plateBox, photo.path);
        if (cropPath != null) {
          try {
            read = await widget.plateScanService
                .readPlate(cropPath, tryRotations: false);
          } finally {
            unawaited(
                File(cropPath).delete().catchError((_) => File(cropPath)));
          }
        }
      }
      if (!read.found) {
        final whole = await widget.plateScanService.readPlate(photo.path);
        if (whole.found || read.suggestion.isEmpty) read = whole;
      }
      if (!mounted) return;
      if (read.found) {
        await _lockAndLookUp(read.plate, image: image, plateBox: plateBox);
      } else {
        await _confirmAndLookUp(read.suggestion,
            image: image, plateBox: plateBox);
      }
    } on PlateScanException catch (error) {
      if (!mounted) return;
      setState(() {
        _state = _ScanState.scanning;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = _ScanState.scanning;
        _errorMessage = _loc.plateScanGalleryFailed;
      });
    } finally {
      _isCapturing = false;
    }
  }

  Future<void> _enterPlate() async {
    final plate = await _promptForPlate(title: _loc.plateScanEnterTitle);
    if (plate == null || !mounted) return;
    await _lockAndLookUp(plate);
  }

  /// Plate entry dialog. Returns the canonical plate, or null when the
  /// officer cancels. Empty or unreadable input is handled inside the dialog
  /// (it says why and stays open), so it only ever closes with a plate the
  /// lookup can use.
  Future<String?> _promptForPlate({
    required String title,
    String? message,
    String initialText = '',
  }) async {
    _isPausedByRoute = true;
    // The dialog owns (and disposes) its TextEditingController. Disposing it
    // here, as soon as showDialog returned, left the still-animating TextField
    // holding a dead controller, which crashed with
    // "'_dependents.isEmpty': is not true" when Check was tapped on an empty
    // field.
    final plate = await showDialog<String>(
      context: context,
      builder: (_) => _PlateEntryDialog(
        title: title,
        message: message,
        initialText: initialText,
        canonicalPlate: widget.plateScanService.canonicalPlate,
      ),
    );
    _isPausedByRoute = false;
    if (plate == null || plate.isEmpty || !mounted) return null;
    return plate;
  }

  Future<void> _editTold() async {
    _isPausedByRoute = true;
    final told = await showVehicleToldSheet(context, _told);
    _isPausedByRoute = false;
    if (told != null && mounted) setState(() => _told = told);
  }

  @override
  void dispose() {
    _autoScanTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    amicaRouteObserver.unsubscribe(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      // The viewfinder is black in both modes, so this app bar opts out of
      // the app chrome and stays light-on-dark.
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: Text(
          _loc.plateScanTitle,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildCameraLayer(),
          if (_state != _ScanState.error) _buildScanOverlay(context),
          if (_state == _ScanState.error) _buildErrorState(context),
        ],
      ),
    );
  }

  Widget _buildCameraLayer() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const ColoredBox(color: Colors.black);
    }
    return Center(
      child: Container(
        key: _previewBoxKey,
        child: CameraPreview(controller),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AmicaGlass(
          strong: true,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const GradientIconBadge(
                icon: Icons.videocam_off_outlined,
                size: 56,
              ),
              const SizedBox(height: 14),
              Text(
                _errorMessage ?? _loc.plateScanCameraStartFailed,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).amica.plum,
                    ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: _loc.plateScanRetry,
                icon: Icons.refresh_rounded,
                onPressed: _initializeCamera,
              ),
              const SizedBox(height: 10),
              PrimaryButton(
                tone: AmicaButtonTone.quiet,
                label: _loc.plateScanChooseGallery,
                icon: Icons.photo_library_outlined,
                onPressed: _scanFromGallery,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanOverlay(BuildContext context) {
    final c = Theme.of(context).amica;
    return SafeArea(
      child: Column(
        children: [
          if (FeatureFlags.vehicleCheck) ...[
            const SizedBox(height: kToolbarHeight + 8),
            _ToldChip(
              label: _told.isEmpty
                  ? _loc.vehicleToldButton
                  : _loc.vehicleToldButtonSet(
                      _loc.describeVehicle(_told.kind, _told.colour)),
              isSet: !_told.isEmpty,
              onPressed: _state == _ScanState.scanning ? _editTold : null,
            ),
          ],
          const Spacer(),
          Container(
            key: _frameBoxKey,
            child: _ScanFrame(isActive: _state == _ScanState.scanning),
          ),
          const SizedBox(height: 20),
          // Frosted status pill over the live camera.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: AmicaGlass(
              strong: true,
              blur: 16,
              borderRadius: BorderRadius.circular(999),
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 12,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_state == _ScanState.capturing ||
                      _state == _ScanState.locked) ...[
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: c.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ] else ...[
                    Icon(Icons.center_focus_strong_rounded,
                        size: 18, color: c.accentInk),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: c.plum,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_errorMessage != null && _state == _ScanState.scanning) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: AmicaGlass(
                strong: true,
                blur: 16,
                borderRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.all(10),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.terracottaDeep, fontSize: 13),
                ),
              ),
            ),
          ],
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _RoundIconButton(
                  icon: Icons.photo_library_outlined,
                  tooltip: _loc.plateScanChooseGallery,
                  onPressed:
                      _state == _ScanState.scanning ? _scanFromGallery : null,
                ),
                _ShutterButton(
                  onPressed: _state == _ScanState.scanning
                      ? () => unawaited(_captureAndAnalyze())
                      : null,
                ),
                _RoundIconButton(
                  icon: Icons.keyboard_alt_outlined,
                  onPressed:
                      _state == _ScanState.scanning ? _enterPlate : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Frosted "What was I told?" pill at the top of the viewfinder.
class _ToldChip extends StatelessWidget {
  const _ToldChip({
    required this.label,
    required this.isSet,
    required this.onPressed,
  });

  final String label;
  final bool isSet;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    return AmicaGlass(
      strong: true,
      blur: 16,
      borderRadius: BorderRadius.circular(999),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSet
                      ? Icons.directions_car_filled_rounded
                      : Icons.help_outline_rounded,
                  size: 18,
                  color: c.accentInk,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: c.plum,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                if (isSet) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.edit_rounded, size: 14, color: c.plum45),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shutter: a white ring around a brand-gradient core.
class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        onTap: onPressed,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: enabled ? 1 : 0.45,
          child: Container(
            width: 78,
            height: 78,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3.5),
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: c.accentGradient,
                boxShadow: [
                  BoxShadow(
                    color: c.accent.withValues(alpha: 0.5),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: const Icon(
                Icons.document_scanner_outlined,
                color: AppColors.onAccent,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Frosted round button over the camera.
class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final button = AmicaGlass(
      shape: BoxShape.circle,
      strong: true,
      blur: 14,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Icon(
              icon,
              color: onPressed == null
                  ? c.plum45.withValues(alpha: 0.6)
                  : c.accentInk,
            ),
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

class _ScanFrame extends StatefulWidget {
  const _ScanFrame({required this.isActive});

  final bool isActive;

  @override
  State<_ScanFrame> createState() => _ScanFrameState();
}

class _ScanFrameState extends State<_ScanFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const frameWidth = 280.0;
    const frameHeight = 230.0;
    final c = Theme.of(context).amica;

    return SizedBox(
      width: frameWidth,
      height: frameHeight,
      child: Stack(
        children: [
          // Soft rounded frame with bright gradient corners.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _CornerPainter(
                start: c.accent,
                end: c.accentEnd,
              ),
            ),
          ),
          if (widget.isActive)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Positioned(
                  top: 14 + _controller.value * (frameHeight - 28),
                  left: 18,
                  right: 18,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          c.accent.withValues(alpha: 0),
                          c.accent,
                          c.accentEnd,
                          c.accentEnd.withValues(alpha: 0),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: c.accentEnd.withValues(alpha: 0.7),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Four rounded corner brackets in the brand gradient.
class _CornerPainter extends CustomPainter {
  const _CornerPainter({required this.start, required this.end});

  final Color start;
  final Color end;

  @override
  void paint(Canvas canvas, Size size) {
    const len = 34.0;
    const r = 26.0;
    final paint = Paint()
      ..shader = LinearGradient(colors: [start, end])
          .createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final path = Path()
      // top-left
      ..moveTo(0, r + len)
      ..lineTo(0, r)
      ..arcToPoint(const Offset(r, 0), radius: const Radius.circular(r))
      ..lineTo(r + len, 0)
      // top-right
      ..moveTo(w - r - len, 0)
      ..lineTo(w - r, 0)
      ..arcToPoint(Offset(w, r), radius: const Radius.circular(r))
      ..lineTo(w, r + len)
      // bottom-right
      ..moveTo(w, h - r - len)
      ..lineTo(w, h - r)
      ..arcToPoint(Offset(w - r, h), radius: const Radius.circular(r))
      ..lineTo(w - r - len, h)
      // bottom-left
      ..moveTo(r + len, h)
      ..lineTo(r, h)
      ..arcToPoint(Offset(0, h - r), radius: const Radius.circular(r))
      ..lineTo(0, h - r - len);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) =>
      old.start != start || old.end != end;
}

/// Type-a-plate dialog. Keeps its own controller so the field is never left
/// with a disposed one while the dialog animates out, and validates in place:
/// Check stays disabled until something is typed, and an empty or unreadable
/// plate shows the reason under the field instead of closing the dialog.
class _PlateEntryDialog extends StatefulWidget {
  const _PlateEntryDialog({
    required this.title,
    required this.canonicalPlate,
    this.message,
    this.initialText = '',
  });

  final String title;
  final String? message;
  final String initialText;

  /// Returns the canonical plate for the typed text, or '' if it is not one.
  final String Function(String text) canonicalPlate;

  @override
  State<_PlateEntryDialog> createState() => _PlateEntryDialogState();
}

class _PlateEntryDialogState extends State<_PlateEntryDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialText);
  String? _error;

  bool get _hasText => _controller.text.trim().isNotEmpty;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final loc = AppLocalizations.of(context);
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = loc.plateScanEmptyPlate);
      return;
    }
    final plate = widget.canonicalPlate(text);
    if (plate.isEmpty) {
      setState(() => _error = loc.plateScanInvalidPlate);
      return;
    }
    Navigator.of(context).pop(plate);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.message != null) ...[
            Text(widget.message!),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'CAB-1234',
              errorText: _error,
              errorMaxLines: 3,
            ),
            onChanged: (_) => setState(() => _error = null),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.commonCancel),
        ),
        TextButton(
          onPressed: _hasText ? _submit : null,
          child: Text(loc.plateScanCheckButton),
        ),
      ],
    );
  }
}
