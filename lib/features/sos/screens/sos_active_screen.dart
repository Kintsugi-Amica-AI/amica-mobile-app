import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/amica_map_view.dart';
import '../../../core/widgets/primary_button.dart';
import '../../journey/models/location_data_model.dart';

class SosActiveArguments {
  const SosActiveArguments({
    required this.alertId,
    required this.triggerType,
    required this.location,
    this.message,
    this.status = 'active',
  });

  final String alertId;
  final String triggerType;
  final LocationDataModel location;
  final String? message;
  final String status;
}

class SosActiveScreen extends StatelessWidget {
  const SosActiveScreen({
    super.key,
    this.arguments,
  });

  final SosActiveArguments? arguments;

  @override
  Widget build(BuildContext context) {
    final args = arguments;

    return Scaffold(
      appBar: AppBar(title: const Text('SOS Active')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.sos, color: AppColors.alert, size: 72),
          const SizedBox(height: 16),
          Text(
            args?.triggerType == 'voice'
                ? 'Voice SOS triggered using secret phrase.'
                : 'Your SOS alert is active.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text('Alert ID: ${args?.alertId ?? 'Not available'}'),
          Text('Trigger type: ${args?.triggerType ?? 'manual'}'),
          Text('Status: ${args?.status ?? 'active'}'),
          Text(
            'Message: ${args?.message ?? 'I need help. This is my live location.'}',
          ),
          if (args?.location != null) ...[
            const SizedBox(height: 20),
            AmicaMapView(
              latitude: args!.location.latitude,
              longitude: args.location.longitude,
              markerTitle: 'SOS location',
            ),
            const SizedBox(height: 8),
            Text(
              'Location: ${args.location.latitude.toStringAsFixed(5)}, '
              '${args.location.longitude.toStringAsFixed(5)}',
            ),
          ],
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Back to Home',
            icon: Icons.home,
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.home,
              (_) => false,
            ),
          ),
        ],
      ),
    );
  }
}
