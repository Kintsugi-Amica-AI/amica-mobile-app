import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../models/vehicle_profile.dart';
import 'vehicle_labels.dart';

/// Swatches for the colour chips. Only for display.
const Map<VehicleColour, Color> vehicleColourSwatches = {
  VehicleColour.white: Color(0xFFF7F7F5),
  VehicleColour.silver: Color(0xFFC4C8CC),
  VehicleColour.grey: Color(0xFF7D8288),
  VehicleColour.black: Color(0xFF1F1F22),
  VehicleColour.red: Color(0xFFD32F2F),
  VehicleColour.maroon: Color(0xFF7B1F2A),
  VehicleColour.orange: Color(0xFFF57C00),
  VehicleColour.yellow: Color(0xFFFBC02D),
  VehicleColour.green: Color(0xFF2E7D32),
  VehicleColour.blue: Color(0xFF1E5AA8),
  VehicleColour.brown: Color(0xFF6D4C41),
};

/// "What was I told?": two taps to say which type and colour the ride
/// app promised. Returns the new expectation, or null when dismissed.
Future<VehicleExpectation?> showVehicleToldSheet(
  BuildContext context,
  VehicleExpectation current,
) {
  return showModalBottomSheet<VehicleExpectation>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _VehicleToldSheet(initial: current),
  );
}

class _VehicleToldSheet extends StatefulWidget {
  const _VehicleToldSheet({required this.initial});

  final VehicleExpectation initial;

  @override
  State<_VehicleToldSheet> createState() => _VehicleToldSheetState();
}

class _VehicleToldSheetState extends State<_VehicleToldSheet> {
  late VehicleExpectation _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final c = Theme.of(context).amica;
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(loc.vehicleToldSheetTitle, style: text.titleLarge),
            const SizedBox(height: 6),
            Text(loc.vehicleToldSheetBody, style: text.bodyMedium),
            const SizedBox(height: 18),
            Text(loc.vehicleToldTypeLabel, style: text.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final kind in VehicleKind.values)
                  ChoiceChip(
                    label: Text(loc.vehicleKindName(kind)),
                    selected: _value.kind == kind,
                    onSelected: (selected) => setState(() {
                      _value = selected
                          ? _value.copyWith(kind: kind)
                          : _value.copyWith(clearKind: true);
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text(loc.vehicleToldColourLabel, style: text.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final colour in VehicleColour.values)
                  ChoiceChip(
                    avatar: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: vehicleColourSwatches[colour],
                        border: Border.all(color: c.line),
                      ),
                    ),
                    label: Text(loc.vehicleColourName(colour)),
                    selected: _value.colour == colour,
                    onSelected: (selected) => setState(() {
                      _value = selected
                          ? _value.copyWith(colour: colour)
                          : _value.copyWith(clearColour: true);
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, const VehicleExpectation()),
                  child: Text(loc.vehicleToldClear),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => Navigator.pop(context, _value),
                  child: Text(loc.vehicleToldDone),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
