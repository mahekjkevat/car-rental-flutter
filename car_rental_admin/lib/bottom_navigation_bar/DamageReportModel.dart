class DamageReportModel {
  final String carBookingId;
  final String? damageReportId;
  final String userId; // Add this field

  const DamageReportModel({
    required this.carBookingId,
    this.damageReportId,
    required this.userId,
  });
}