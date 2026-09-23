import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/amica_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../models/vehicle_status.dart';
import '../services/vehicle_journey_service.dart';
import '../../journey/screens/start_journey_screen.dart';
import 'vehicle_rating_screen.dart';
import '../../../l10n/generated/app_localizations.dart';

class PlateResultScreen extends StatefulWidget {
  const PlateResultScreen({super.key});

  @override
  State<PlateResultScreen> createState() => _PlateResultScreenState();
}

class _PlateResultScreenState extends State<PlateResultScreen> {
  bool _boarding = false;
  String? _boardingStatus;
  late AppLocalizations _loc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loc = AppLocalizations.of(context)!;
  }

  Future<void> _board(VehicleStatus vehicle) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(
                  _loc.plateResultDialogTitle(vehicle.plateNumber)),
              content: Text(_loc.plateResultDialogBody),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(_loc.commonCancel)),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(_loc.plateResultConfirmButton)),
              ],
            ));
    if (confirmed != true || !mounted) return;
    setState(() => _boarding = true);
    try {
      final result = await const VehicleJourneyService()
          .notifyBoarding(vehicle.normalizedPlateNumber);
      if (!mounted) return;
      setState(() => _boardingStatus = result);
      await Navigator.push(
          context,
          MaterialPageRoute<void>(
              builder: (_) => StartJourneyScreen(
                  vehiclePlate: vehicle.normalizedPlateNumber,
                  boardingStatus: result)));
    } catch (_) {
      if (mounted) {
        setState(() => _boardingStatus = _loc.plateResultBoardingFailed);
      }
    } finally {
      if (mounted) setState(() => _boarding = false);
    }
  }

  (Color, IconData, String) _presentation(VehicleRiskStatus status) {
    return switch (status) {
      VehicleRiskStatus.safe => (
          Theme.of(context).amica.sage,
          Icons.verified_user_rounded,
          _loc.plateResultStatusSafe,
        ),
      VehicleRiskStatus.reported => (
          Theme.of(context).amica.terracotta,
          Icons.report_gmailerrorred_rounded,
          _loc.plateResultStatusReported,
        ),
      VehicleRiskStatus.unknown => (
          Theme.of(context).amica.gold,
          Icons.help_outline_rounded,
          _loc.plateResultStatusUnknown,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final status = args is VehicleStatus
        ? args
        : const VehicleStatus(
            plateNumber: 'UNKNOWN',
            status: VehicleRiskStatus.unknown,
          );

    final (color, icon, label) = _presentation(status.status);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(_loc.plateResultTitle)),
      extendBodyBehindAppBar: true,
      body: AmicaBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.14),
                    border: Border.all(color: color.withValues(alpha: 0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: color, size: 48),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  status.plateNumber.isEmpty ? 'UNKNOWN' : status.plateNumber,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              GlassCard(
                borderColor: color,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatRow(
                        label: status.isDemo
                            ? _loc.plateResultDemoPassengerRating
                            : _loc.plateResultPassengerRating,
                        value: status.ratingCount == 0
                            ? _loc.plateResultNotRated
                            : _loc.plateResultRatingValue(
                                status.ratingAverage.toStringAsFixed(1),
                                status.ratingCount)),
                    const Divider(height: 24),
                    _StatRow(
                        label: _loc.plateResultUnverifiedChecks,
                        value: '${status.unverifiedSafetyCheckCount}'),
                    const Divider(height: 24),
                    _StatRow(
                      label: _loc.plateResultReportsOnFile,
                      value: '${status.reportsCount}',
                    ),
                    const Divider(height: 24),
                    _StatRow(
                      label: _loc.plateResultRiskLevel,
                      value: status.riskLevel.toUpperCase(),
                    ),
                    if (status.notes != null) ...[
                      const Divider(height: 24),
                      Text(
                        status.notes!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _loc.plateResultDbNote,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              Text(status.isDemo
                  ? _loc.plateResultDemoNote
                  : _loc.plateResultFeedbackNote),
              if (_boardingStatus != null) Text(_boardingStatus!),
              const SizedBox(height: 16),
              PrimaryButton(
                  label: _boarding
                      ? _loc.plateResultNotifying
                      : _loc.plateResultTravelingButton,
                  icon: Icons.directions_car,
                  onPressed: _boarding || status.normalizedPlateNumber.isEmpty
                      ? null
                      : () => _board(status)),
              const SizedBox(height: 16),
              PrimaryButton(
                label: _loc.plateResultScanAnotherButton,
                icon: Icons.document_scanner_outlined,
                onPressed: () => Navigator.pop(context),
              ),
              TextButton.icon(
                icon: const Icon(Icons.star_outline),
                label: Text(_loc.plateResultRateButton),
                onPressed: status.normalizedPlateNumber.isEmpty
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                            builder: (_) => CompletedVehicleJourneysScreen(
                                plate: status.normalizedPlateNumber))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}
