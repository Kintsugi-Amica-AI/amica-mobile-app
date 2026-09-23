import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/navigation/amica_route_observer.dart';
import '../../../core/widgets/glass_card.dart';
import '../services/plate_scan_service.dart';
import '../../../l10n/generated/app_localizations.dart';

class PlateScanScreen extends StatefulWidget {
  PlateScanScreen({
    super.key,
    PlateScanService? plateScanService,
    ImagePicker? imagePicker,
  })  : plateScanService = plateScanService ?? const PlateScanService(),
        imagePicker = imagePicker ?? ImagePicker();

  final PlateScanService plateScanService;
  final ImagePicker imagePicker;

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

  /// Takes a photo, crops it to the guide frame, and reads the plate.
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
    try {
      photo = await controller.takePicture();
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

      // Camera photos are already upright, so rotations only waste time.
      var read = await widget.plateScanService
          .readPlate(analyzedPath, tryRotations: false);
      if (!automatic && !read.found && analyzedPath != photo.path) {
        // The plate may sit partly outside the guide frame.
        final full = await widget.plateScanService
            .readPlate(photo.path, tryRotations: false);
        if (full.found || read.suggestion.isEmpty) read = full;
      }

      if (!mounted) return;

      if (automatic && !_manualRequested) {
        if (read.found) {
          _candidateCount =
              read.plate == _lastCandidate ? _candidateCount + 1 : 1;
          _lastCandidate = read.plate;
          if (_candidateCount >= 2) {
            await _lockAndLookUp(read.plate);
          } else {
            setState(() => _statusMessage = _loc.plateScanDetected(read.plate));
          }
        } else {
          _candidateCount = 0;
          setState(() => _statusMessage = _loc.plateScanNotDetected);
        }
      } else if (read.found) {
        // A shutter tap: one exact read is enough.
        await _lockAndLookUp(read.plate);
      } else if (!automatic) {
        await _confirmAndLookUp(read.suggestion);
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

  Future<void> _lockAndLookUp(String plateText) async {
    _manualRequested = false;
    setState(() {
      _state = _ScanState.locked;
      _statusMessage = _loc.plateScanChecking(plateText);
    });

    try {
      final status = await widget.plateScanService.checkVehicle(plateText);
      if (!mounted) {
        return;
      }
      await Navigator.pushNamed(context, AppRoutes.plateResult,
          arguments: status);
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
  Future<void> _confirmAndLookUp(String suggestion) async {
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
    await _lockAndLookUp(plate);
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

      final read = await widget.plateScanService.readPlate(photo.path);
      if (!mounted) return;
      if (read.found) {
        await _lockAndLookUp(read.plate);
      } else {
        await _confirmAndLookUp(read.suggestion);
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
  /// officer cancels or types something that is not a registration.
  Future<String?> _promptForPlate({
    required String title,
    String? message,
    String initialText = '',
  }) async {
    _isPausedByRoute = true;
    final controller = TextEditingController(text: initialText);
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message != null) ...[
              Text(message),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(hintText: 'CAB-1234'),
              onSubmitted: (value) => Navigator.pop(context, value),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_loc.commonCancel)),
          TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(_loc.plateScanCheckButton)),
        ],
      ),
    );
    controller.dispose();
    _isPausedByRoute = false;
    if (text == null || !mounted) return null;
    final plate = widget.plateScanService.canonicalPlate(text);
    if (plate.isEmpty) {
      setState(() {
        _state = _ScanState.scanning;
        _statusMessage = _loc.plateScanAlignPrompt;
        _errorMessage = _loc.plateScanInvalidPlate;
      });
      return null;
    }
    return plate;
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
      // the Warm Dawn chrome and stays light-on-dark.
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
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.videocam_off_outlined,
                  color: Theme.of(context).amica.terracotta, size: 40),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? _loc.plateScanCameraStartFailed,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _initializeCamera,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(_loc.plateScanRetry),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _scanFromGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(_loc.plateScanChooseGallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanOverlay(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const Spacer(),
          Container(
            key: _frameBoxKey,
            child: _ScanFrame(isActive: _state == _ScanState.scanning),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_state == _ScanState.capturing ||
                      _state == _ScanState.locked) ...[
                    // Camera chrome sits on the black viewfinder, so it
                    // stays white regardless of day or night mode.
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).amica.plum,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_errorMessage != null && _state == _ScanState.scanning) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).amica.terracotta),
            ),
          ],
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _RoundIconButton(
                  icon: Icons.photo_library_outlined,
                  onPressed:
                      _state == _ScanState.scanning ? _scanFromGallery : null,
                ),
                _ShutterButton(
                  onPressed: _state == _ScanState.scanning
                      ? () => unawaited(_captureAndAnalyze())
                      : null,
                ),
                _RoundIconButton(
                    icon: Icons.keyboard,
                    onPressed:
                        _state == _ScanState.scanning ? _enterPlate : null),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A classic camera shutter button for manual plate capture.
class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 72,
        height: 72,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: enabled ? 0.9 : 0.35),
            width: 3,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: enabled ? 1 : 0.35),
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Material(
        color: Colors.white.withValues(alpha: 0.12),
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(
              icon,
              color: onPressed == null
                  ? Colors.white.withValues(alpha: 0.35)
                  : Colors.white,
            ),
          ),
        ),
      ),
    );
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
    final color = widget.isActive ? Theme.of(context).amica.sage : Theme.of(context).amica.sage;

    return SizedBox(
      width: frameWidth,
      height: frameHeight,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              border:
                  Border.all(color: color.withValues(alpha: 0.85), width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          if (widget.isActive)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Positioned(
                  top: 8 + _controller.value * (frameHeight - 16),
                  left: 8,
                  right: 8,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.8),
                          blurRadius: 8,
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
