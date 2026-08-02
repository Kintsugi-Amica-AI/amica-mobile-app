import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/amica_background.dart';
import '../../../core/widgets/amica_map_view.dart';
import '../../../core/widgets/glass_card.dart';
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

  String _triggerLabel(String? triggerType) {
    return switch (triggerType) {
      'voice' => 'Voice SOS triggered using your secret phrase.',
      'timer' => 'Journey timer expired without a safety response.',
      _ => 'Your manual SOS alert is active.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final args = arguments;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('SOS Active')),
      extendBodyBehindAppBar: true,
      body: AmicaBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.sosGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.alert.withValues(alpha: 0.55),
                        blurRadius: 32,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.sos_rounded,
                      color: Colors.white, size: 48),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _triggerLabel(args?.triggerType),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              GlassCard(
                borderColor: AppColors.alert,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(label: 'Alert ID', value: args?.alertId ?? 'Not available'),
                    _InfoRow(label: 'Trigger type', value: args?.triggerType ?? 'manual'),
                    _InfoRow(label: 'Status', value: args?.status ?? 'active'),
                    _InfoRow(
                      label: 'Message',
                      value: args?.message ??
                          'I need help. This is my live location.',
                    ),
                  ],
                ),
              ),
              if (args?.location != null) ...[
                const SizedBox(height: 20),
                AmicaMapView(
                  latitude: args!.location.latitude,
                  longitude: args.location.longitude,
                  markerTitle: 'SOS location',
                ),
                const SizedBox(height: 10),
                Text(
                  'Location: ${args.location.latitude.toStringAsFixed(5)}, '
                  '${args.location.longitude.toStringAsFixed(5)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'Back to Home',
                icon: Icons.home_rounded,
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.home,
                  (_) => false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
