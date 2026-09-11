import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/navigation/amica_route_observer.dart';
import '../../../core/widgets/glass_card.dart';
import '../services/plate_scan_service.dart';

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
  bool _isCapturing = false;
  bool _isPausedByRoute = false;
  _ScanState _state = _ScanState.initializing;
  String? _errorMessage;
  String _statusMessage = 'Starting camera...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initializeCamera());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    if (_state == _ScanState.locked || _state == _ScanState.capturing) {
      setState(() {
        _state = _ScanState.scanning;
        _statusMessage = 'Align the plate in the frame and tap the shutter';
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
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
      _statusMessage = 'Starting camera...';
    });

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _state = _ScanState.error;
          _errorMessage = 'No camera was found on this device.';
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
        _statusMessage = 'Align the plate in the frame and tap the shutter';
      });
    } on CameraException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _state = _ScanState.error;
        _errorMessage = error.code == 'CameraAccessDenied'
            ? 'Camera permission is required to scan a plate. Enable it in system settings.'
            : error.description ?? 'Could not start the camera.';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _state = _ScanState.error;
        _errorMessage = 'Could not start the camera.';
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

  /// Takes a single photo when the shutter button is tapped, crops it to
  /// the guide frame, and looks up whatever plate was recognized.
  Future<void> _captureAndAnalyze() async {
    final controller = _controller;
    if (_isCapturing ||
        _isPausedByRoute ||
        controller == null ||
        !controller.value.isInitialized) {
      return;
    }

    _isCapturing = true;
    setState(() {
      _state = _ScanState.capturing;
      _statusMessage = 'Reading plate...';
    });

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

      final plateText =
          await widget.plateScanService.extractPlateText(analyzedPath);
      final isPlausible = widget.plateScanService.looksLikePlate(plateText);

      if (!mounted) {
        return;
      }

      if (isPlausible) {
        await _lockAndLookUp(plateText);
      } else {
        setState(() {
          _state = _ScanState.scanning;
          _statusMessage =
              'No plate detected. Align it inside the frame and try again.';
        });
      }
    } on PlateScanException catch (error) {
      if (mounted) {
        setState(() {
          _state = _ScanState.scanning;
          _statusMessage = 'Align the plate in the frame and tap the shutter';
          _errorMessage = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _state = _ScanState.scanning;
          _statusMessage = 'Align the plate in the frame and tap the shutter';
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
    }
  }

  Future<void> _lockAndLookUp(String plateText) async {
    setState(() {
      _state = _ScanState.locked;
      _statusMessage = 'Checking $plateText...';
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
        _statusMessage = 'Align the plate in the frame and tap the shutter';
        _errorMessage = error.message;
      });
    }
  }

  Future<void> _scanFromGallery() async {
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
        setState(() => _state = _ScanState.scanning);
        return;
      }

      final plateText =
          await widget.plateScanService.extractPlateText(photo.path);
      final status = await widget.plateScanService.checkVehicle(plateText);

      if (!mounted) {
        return;
      }
      await Navigator.pushNamed(context, AppRoutes.plateResult,
          arguments: status);
    } on PlateScanException catch (error) {
      setState(() {
        _state = _ScanState.scanning;
        _errorMessage = error.message;
      });
    } catch (_) {
      setState(() {
        _state = _ScanState.scanning;
        _errorMessage = 'Could not scan the plate. Please try again.';
      });
    }
  }

  @override
  void dispose() {
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Scan before you ride'),
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
              const Icon(Icons.videocam_off_outlined,
                  color: AppColors.alert, size: 40),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? 'Could not start the camera.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _initializeCamera,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _scanFromGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Choose from gallery instead'),
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
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
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
              style: const TextStyle(color: AppColors.alert),
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
                const SizedBox(width: 48),
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
    const frameHeight = 150.0;
    final color =
        widget.isActive ? AppColors.secondary : AppColors.success;

    return SizedBox(
      width: frameWidth,
      height: frameHeight,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: color.withValues(alpha: 0.85), width: 2),
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
