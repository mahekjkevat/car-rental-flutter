import '../../car_data_model.dart';

class CarRecommendation {
  final CarDataModel car;
  final double confidenceScore;
  final String reason;

  CarRecommendation({
    required this.car,
    required this.confidenceScore,
    required this.reason,
  });
}

class UserPreferences {
  final String preferredBrand;
  final String preferredFuelType;
  final int preferredSeats;
  final double priceRangeMin;
  final double priceRangeMax;
  final String preferredCarType;

  UserPreferences({
    required this.preferredBrand,
    required this.preferredFuelType,
    required this.preferredSeats,
    required this.priceRangeMin,
    required this.priceRangeMax,
    required this.preferredCarType,
  });
}