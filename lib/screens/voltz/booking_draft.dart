/// In-memory state passed between the four Voltz booking-wizard steps.
/// Not persisted — each step screen mutates a copy and hands it forward via
/// constructor args, the same way the wizard would eventually hand off to
/// DeliveryService once wired to a real dispatch flow.
class VoltzBookingDraft {
  String pickupAddress;
  String dropoffAddress;
  String parcelSize;
  String parcelContents;
  String deliverySpeed;
  Set<String> addOns;

  VoltzBookingDraft({
    this.pickupAddress = '',
    this.dropoffAddress = '',
    this.parcelSize = '',
    this.parcelContents = '',
    this.deliverySpeed = '',
    Set<String>? addOns,
  }) : addOns = addOns ?? <String>{};

  VoltzBookingDraft copyWith({
    String? pickupAddress,
    String? dropoffAddress,
    String? parcelSize,
    String? parcelContents,
    String? deliverySpeed,
    Set<String>? addOns,
  }) {
    return VoltzBookingDraft(
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      parcelSize: parcelSize ?? this.parcelSize,
      parcelContents: parcelContents ?? this.parcelContents,
      deliverySpeed: deliverySpeed ?? this.deliverySpeed,
      addOns: addOns ?? this.addOns,
    );
  }

  static const Map<String, double> speedBasePrice = {
    'Express': 4200,
    'Standard': 2500,
    'Scheduled': 2200,
  };

  static const Map<String, double> addOnPrice = {
    'Fragile handling': 400,
    'Signature on delivery': 250,
    'Insurance': 600,
  };

  double get basePrice => speedBasePrice[deliverySpeed] ?? 0;

  double get addOnsPrice =>
      addOns.fold(0.0, (sum, a) => sum + (addOnPrice[a] ?? 0));

  double get total => basePrice + addOnsPrice;
}
