import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/amica_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/primary_button.dart';
import '../services/plate_scan_service.dart';

class PlateScanScreen extends StatefulWidget {
  PlateScanScreen({
    super.key,
    PlateScanService? plateScanService,
    ImagePicker? imagePicker,
  })  : plateScanService = plateScanService ?? PlateScanService(),
        imagePicker = imagePicker ?? ImagePicker();

  final PlateScanService plateScanService;
  final ImagePicker imagePicker;

  @override
  State<PlateScanScreen> createState() => _PlateScanScreenState();
}

class _PlateScanScreenState extends State<PlateScanScreen> {
  bool _isProcessing = false;
  String? _errorMessage;

  Future<void> _scan(ImageSource source) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final photo = await widget.imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 90,
      );

      if (photo == null) {
        setState(() => _isProcessing = false);
        return;
      }

      final plateText = await widget.plateScanService.extractPlateText(
        photo.path,
      );
      final status = await widget.plateScanService.checkVehicle(plateText);

      if (!mounted) {
        return;
      }
      await Navigator.pushNamed(
        context,
        AppRoutes.plateResult,
        arguments: status,
      );
    } on PlateScanException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(
        () => _errorMessage = 'Could not scan the plate. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Scan before you ride')),
      extendBodyBehindAppBar: true,
      body: AmicaBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _isProcessing
                ? const LoadingView(message: 'Reading plate and checking status')
                : ListView(
                    children: [
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.success.withValues(alpha: 0.14),
                            border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Icon(
                            Icons.document_scanner_outlined,
                            color: AppColors.success,
                            size: 44,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Capture a vehicle number plate before boarding a taxi or three-wheeler.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Amica reads the plate on-device with ML Kit OCR and checks it against the shared safety database.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      GlassCard(
                        child: Column(
                          children: [
                            PrimaryButton(
                              label: 'Take a photo',
                              icon: Icons.camera_alt_outlined,
                              onPressed: () => _scan(ImageSource.camera),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () => _scan(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Choose from gallery'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
