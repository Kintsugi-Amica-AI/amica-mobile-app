import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/amica_primitives.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/primary_button.dart';
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

/// Icon for each vehicle type on the picker tiles and the preview.
const Map<VehicleKind, IconData> vehicleKindIcons = {
  VehicleKind.car: Icons.directions_car_filled_rounded,
  VehicleKind.van: Icons.airport_shuttle_rounded,
  VehicleKind.bus: Icons.directions_bus_filled_rounded,
  VehicleKind.lorry: Icons.local_shipping_rounded,
  VehicleKind.motorbike: Icons.two_wheeler_rounded,
  VehicleKind.threeWheeler: Icons.electric_rickshaw,
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
    useSafeArea: true,
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

  void _pickKind(VehicleKind kind) {
    HapticFeedback.selectionClick();
    setState(() {
      _value = _value.kind == kind
          ? _value.copyWith(clearKind: true)
          : _value.copyWith(kind: kind);
    });
  }

  void _pickColour(VehicleColour colour) {
    HapticFeedback.selectionClick();
    setState(() {
      _value = _value.colour == colour
          ? _value.copyWith(clearColour: true)
          : _value.copyWith(colour: colour);
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final c = Theme.of(context).amica;
    final text = Theme.of(context).textTheme;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header: icon chip, title and a one-line why.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.accentSoft,
                        ),
                        child: Icon(Icons.fact_check_outlined,
                            color: c.accentInk, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(loc.vehicleToldSheetTitle,
                                style: text.titleLarge),
                            const SizedBox(height: 4),
                            Text(
                              loc.vehicleToldSheetBody,
                              style: text.bodyMedium
                                  ?.copyWith(color: c.plum70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _ToldPreview(value: _value),
                  const SizedBox(height: 22),
                  SectionLabel(loc.vehicleToldTypeLabel),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const gap = 10.0;
                      final width = (constraints.maxWidth - gap * 2) / 3;
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          for (final kind in VehicleKind.values)
                            SizedBox(
                              width: width,
                              child: _KindTile(
                                kind: kind,
                                label: loc.vehicleKindName(kind),
                                selected: _value.kind == kind,
                                onTap: () => _pickKind(kind),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  SectionLabel(loc.vehicleToldColourLabel),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 4,
                    runSpacing: 12,
                    children: [
                      for (final colour in VehicleColour.values)
                        _ColourSwatch(
                          colour: colour,
                          label: loc.vehicleColourName(colour),
                          selected: _value.colour == colour,
                          onTap: () => _pickColour(colour),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          // Actions stay pinned under the scrolling choices, clear of the
          // gesture bar.
          SafeArea(
            top: false,
            child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 16),
            child: Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    tone: AmicaButtonTone.quiet,
                    label: loc.vehicleToldClear,
                    onPressed: _value.isEmpty
                        ? null
                        : () => Navigator.pop(
                            context, const VehicleExpectation()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: PrimaryButton(
                    label: loc.vehicleToldDone,
                    icon: Icons.check_rounded,
                    onPressed: () => Navigator.pop(context, _value),
                  ),
                ),
              ],
            ),
          ),
          ),
        ],
      ),
    );
  }
}

/// Live summary of what she has picked, drawn in the picked colour.
class _ToldPreview extends StatelessWidget {
  const _ToldPreview({required this.value});

  final VehicleExpectation value;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final c = Theme.of(context).amica;
    final text = Theme.of(context).textTheme;
    final kind = value.kind;
    final colour = value.colour;
    final swatch = colour == null ? null : vehicleColourSwatches[colour];
    final description = loc.describeVehicle(kind, colour);
    final isEmpty = description.isEmpty;

    return AnimatedContainer(
      duration: AmicaMotion.medium,
      curve: AmicaMotion.enter,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isEmpty ? c.shell : c.accentSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEmpty ? c.line : c.accent.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: AmicaMotion.medium,
            curve: AmicaMotion.enter,
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.line),
            ),
            child: Icon(
              kind == null
                  ? Icons.directions_car_outlined
                  : vehicleKindIcons[kind],
              size: 30,
              // The icon wears the picked colour; very light paints get an
              // outline-ish grey so they still show on the white tile.
              color: swatch == null
                  ? c.plum45
                  : swatch.computeLuminance() > 0.8
                      ? const Color(0xFFB9BDC2)
                      : swatch,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.vehicleToldCardSetTitle.toUpperCase(),
                  style: text.labelSmall,
                ),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: AmicaMotion.quick,
                  child: Text(
                    isEmpty
                        ? loc.vehicleToldPreviewEmpty
                        : _capitalised(description),
                    key: ValueKey(description),
                    style: isEmpty
                        ? text.bodyMedium?.copyWith(color: c.plum70)
                        : text.titleMedium?.copyWith(
                            color: c.plum,
                            fontWeight: FontWeight.w700,
                          ),
                  ),
                ),
              ],
            ),
          ),
          if (!isEmpty)
            Icon(Icons.check_circle_rounded, color: c.accent, size: 22),
        ],
      ),
    );
  }

  static String _capitalised(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}

/// One vehicle type: icon over its name in a rounded tile.
class _KindTile extends StatelessWidget {
  const _KindTile({
    required this.kind,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final VehicleKind kind;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final radius = BorderRadius.circular(18);
    return Semantics(
      button: true,
      selected: selected,
      child: PressableScale(
        child: AnimatedContainer(
          duration: AmicaMotion.quick,
          curve: AmicaMotion.enter,
          decoration: BoxDecoration(
            color: selected ? c.accentSoft : c.shell,
            borderRadius: radius,
            border: Border.all(
              color: selected ? c.accent : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: radius,
            child: InkWell(
              borderRadius: radius,
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 14, 6, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      vehicleKindIcons[kind],
                      size: 28,
                      color: selected ? c.accentInk : c.plum70,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.2,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? c.accentInk : c.plum70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One paint colour: a round swatch with its name, ringed when picked.
class _ColourSwatch extends StatelessWidget {
  const _ColourSwatch({
    required this.colour,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final VehicleColour colour;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final swatch = vehicleColourSwatches[colour]!;
    final checkColour =
        swatch.computeLuminance() > 0.5 ? const Color(0xFF2B1B3A) : Colors.white;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: SizedBox(
        width: 58,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: AmicaMotion.quick,
                curve: AmicaMotion.enter,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? c.accent : Colors.transparent,
                    width: 2.5,
                  ),
                ),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: swatch,
                    border: Border.all(color: c.line),
                  ),
                  child: AnimatedScale(
                    duration: AmicaMotion.quick,
                    curve: AmicaMotion.pop,
                    scale: selected ? 1 : 0,
                    child: Icon(Icons.check_rounded,
                        size: 20, color: checkColour),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? c.accentInk : c.plum70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
