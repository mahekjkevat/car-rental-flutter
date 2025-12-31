import '../car_booking_model.dart';
import '../car_data_model.dart';
import 'car_recommendation_model.dart';

class SimpleRecommendationEngine {
  final Map<String, int> _userPreferences = {};
  bool _isTrained = false;

  Future<void> trainModel(List<CarBooking> userBookings) async {
    if (userBookings.isEmpty) {
      _isTrained = false;
      return;
    }

    // Analyze user preferences from booking history
    _analyzePreferences(userBookings);
    _isTrained = true;

    print('Simple recommendation engine trained with ${userBookings.length} bookings');
  }

  void _analyzePreferences(List<CarBooking> bookings) {
    final completedBookings = bookings.where((b) => b.status.toLowerCase() == 'completed');

    // Count preferences
    final brandCount = <String, int>{};
    final fuelCount = <String, int>{};
    final seatCount = <int, int>{};
    final priceRange = <double>[];

    for (final booking in completedBookings) {
      // Brand preference
      final brand = booking.carBrand ?? '';
      if (brand.isNotEmpty) {
        brandCount[brand] = (brandCount[brand] ?? 0) + 1;
      }

      // Seat preference
      final seats = booking.seats != null ? int.tryParse(booking.seats!) ?? 0 : 0;
      if (seats > 0) {
        seatCount[seats] = (seatCount[seats] ?? 0) + 1;
      }

      // Price preference
      priceRange.add(booking.totalPrice);
    }

    // Store most frequent preferences
    _userPreferences['preferred_brand'] = _getMostFrequent(brandCount);
    _userPreferences['preferred_fuel'] = _getMostFrequent(fuelCount);
    _userPreferences['preferred_seats'] = _getMostFrequent(seatCount);
    _userPreferences['avg_price'] = priceRange.isNotEmpty
        ? (priceRange.reduce((a, b) => a + b) / priceRange.length).round()
        : 0;
  }

  int _getMostFrequent<T>(Map<T, int> counts) {
    if (counts.isEmpty) return 0;
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.value;
  }

  List<CarRecommendation> getRecommendations(List<CarDataModel> allCars, int limit) {
    final recommendations = allCars.map((car) {
      final score = _calculateMatchScore(car);

      return CarRecommendation(
        car: car,
        confidenceScore: score,
        reason: _getRecommendationReason(score),
      );
    }).toList();

    recommendations.sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));
    return recommendations.take(limit).toList();
  }

  double _calculateMatchScore(CarDataModel car) {
    double score = 0.0;
    double maxScore = 0.0;

    // Brand match (30%)
    if (_userPreferences['preferred_brand']! > 0) {
      final brandMatch = car.carBrand.toLowerCase().contains(
          _getKeyFromValue(_userPreferences, _userPreferences['preferred_brand']!) ?? '')
          ? 0.3 : 0.0;
      score += brandMatch;
    }
    maxScore += 0.3;

    // Fuel type match (25%)
    if (_userPreferences['preferred_fuel']! > 0) {
      final fuelMatch = car.fuelType.toLowerCase().contains(
          _getKeyFromValue(_userPreferences, _userPreferences['preferred_fuel']!) ?? '')
          ? 0.25 : 0.0;
      score += fuelMatch;
    }
    maxScore += 0.25;

    // Seat match (20%)
    if (_userPreferences['preferred_seats']! > 0) {
      final seatDiff = (car.noOfSeats - _userPreferences['preferred_seats']!).abs();
      final seatMatch = seatDiff <= 2 ? 0.2 * (1 - seatDiff / 10) : 0.0;
      score += seatMatch;
    }
    maxScore += 0.2;

    // Price match (15%)
    if (_userPreferences['avg_price']! > 0) {
      final priceRatio = car.basicPrice / _userPreferences['avg_price']!;
      final priceMatch = priceRatio <= 1.5 ? 0.15 * (1 - (priceRatio - 1).abs()) : 0.0;
      score += priceMatch;
    }
    maxScore += 0.15;

    // Rating bonus (10%)
    score += (car.avg_rating / 5.0) * 0.1;
    maxScore += 0.1;

    return score / maxScore;
  }

  String _getKeyFromValue(Map<String, int> map, int value) {
    for (final entry in map.entries) {
      if (entry.value == value) return entry.key;
    }
    return '';
  }

  String _getRecommendationReason(double score) {
    if (score > 0.8) return 'Perfect match for your preferences!';
    if (score > 0.6) return 'Great match based on your history';
    if (score > 0.4) return 'Good option with high ratings';
    return 'Popular choice worth considering';
  }

  bool get isTrained => _isTrained;
}