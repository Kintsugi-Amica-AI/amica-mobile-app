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
    _loc = AppLocalizations.of(context);
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
          Theme.of(context).amica.terracottaDeep,
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
              // Status: soft concentric rings in the status colour.
              Center(
                child: Container(
                  width: 124,
                  height: 124,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.10),
                  ),
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.18),
                      border: Border.all(color: color.withValues(alpha: 0.45)),
                    ),
                    child: Icon(icon, color: color, size: 44),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // The plate itself, drawn like a number plate.
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF2B1B3A),
                      width: 2.5,
                    ),
                    boxShadow: Theme.of(context).amica.shadow,
                  ),
                  child: Text(
                    status.plateNumber.isEmpty ? 'UNKNOWN' : status.plateNumber,
                    style: const TextStyle(
                      color: Color(0xFF2B1B3A),
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 15, color: color),
                      const SizedBox(width: 6),
                      Text(
                        label.toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Four figures as a 2 × 2 grid of soft tiles.
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      icon: Icons.star_rounded,
                      label: status.isDemo
                          ? _loc.plateResultDemoPassengerRating
                          : _loc.plateResultPassengerRating,
                      value: status.ratingCount == 0
                          ? _loc.plateResultNotRated
                          : _loc.plateResultRatingValue(
                              status.ratingAverage.toStringAsFixed(1),
                              status.ratingCount),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.shield_outlined,
                      label: _loc.plateResultRiskLevel,
                      value: status.riskLevel.toUpperCase(),
                      valueColor: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      icon: Icons.help_outline_rounded,
                      label: _loc.plateResultUnverifiedChecks,
                      value: '${status.unverifiedSafetyCheckCount}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.report_outlined,
                      label: _loc.plateResultReportsOnFile,
                      value: '${status.reportsCount}',
                    ),
                  ),
                ],
              ),
              if (status.notes != null) ...[
                const SizedBox(height: 10),
                GlassCard(
                  borderColor: color.withValues(alpha: 0.5),
                  child: Text(
                    status.notes!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
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
                  icon: Icons.local_taxi_rounded,
                  onPressed: _boarding || status.normalizedPlateNumber.isEmpty
                      ? null
                      : () => _board(status)),
              const SizedBox(height: 16),
              PrimaryButton(
                tone: AmicaButtonTone.quiet,
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

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    return AmicaCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.accentSoft,
            ),
            child: Icon(icon, size: 16, color: c.accentInk),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: valueColor,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
