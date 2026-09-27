import '../../../l10n/generated/app_localizations.dart';
import '../models/vehicle_profile.dart';

/// Localised words for vehicle types and colours.
extension VehicleLabels on AppLocalizations {
  String vehicleKindName(VehicleKind kind) => switch (kind) {
        VehicleKind.car => vehicleKindCar,
        VehicleKind.van => vehicleKindVan,
        VehicleKind.bus => vehicleKindBus,
        VehicleKind.lorry => vehicleKindLorry,
        VehicleKind.motorbike => vehicleKindMotorbike,
        VehicleKind.threeWheeler => vehicleKindThreeWheeler,
      };

  String vehicleColourName(VehicleColour colour) => switch (colour) {
        VehicleColour.white => vehicleColourWhite,
        VehicleColour.silver => vehicleColourSilver,
        VehicleColour.grey => vehicleColourGrey,
        VehicleColour.black => vehicleColourBlack,
        VehicleColour.red => vehicleColourRed,
        VehicleColour.maroon => vehicleColourMaroon,
        VehicleColour.orange => vehicleColourOrange,
        VehicleColour.yellow => vehicleColourYellow,
        VehicleColour.green => vehicleColourGreen,
        VehicleColour.blue => vehicleColourBlue,
        VehicleColour.brown => vehicleColourBrown,
      };

  /// "white car", "van", "red"... or '' when both are unknown.
  String describeVehicle(VehicleKind? kind, VehicleColour? colour) {
    if (kind != null && colour != null) {
      return vehicleDescription(vehicleColourName(colour), vehicleKindName(kind));
    }
    if (kind != null) return vehicleKindName(kind);
    if (colour != null) return vehicleColourName(colour);
    return '';
  }
}
