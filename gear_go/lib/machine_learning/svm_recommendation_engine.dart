import '../car_booking_model.dart';
import './/car_data_model.dart';
import 'car_recommendation_model.dart';

class SVMRecommendationEngine {
  bool _isTrained = false;
  late Map<String, dynamic> _userPreferences;
  late Map<String, int> _preferenceCounts;
  List<CarBooking> _trainingData = [];

  SVMRecommendationEngine() {
    _userPreferences = {
      'preferred_brands': <String>[],
      'preferred_fuel_types': <String>[],
      'preferred_seats_range': <int>[],
      'preferred_price_range': <double>[],
      'preferred_car_types': <String>[],
      'avg_booking_price': 0.0,
    };
    _preferenceCounts = {
      'total_bookings': 0,
      'completed_bookings': 0,
      'accepted_bookings': 0,
    };
  }

  // Train the model with user's booking history
  Future<void> trainModel(List<CarBooking> userBookings) async {
    print('🚀 SVM Engine: Starting training with ${userBookings.length} bookings');

    if (userBookings.isEmpty) {
      print('❌ SVM Engine: No booking data available for training');
      _isTrained = false;
      return;
    }

    try {
      _trainingData = userBookings;

      // Analyze user preferences from completed/accepted bookings
      final validBookings = userBookings.where((booking) {
        final status = booking.status.toLowerCase();
        return status == 'completed' || status == 'accepted' || status == 'confirmed';
      }).toList();

      print('✅ SVM Engine: Found ${validBookings.length} valid bookings for training');

      if (validBookings.isEmpty) {
        print('⚠️ SVM Engine: No completed/accepted bookings found');
        _isTrained = false;
        return;
      }

      _analyzeUserPreferences(validBookings);
      _isTrained = true;

      print('🎯 SVM Engine: Training completed successfully');
      print('📊 SVM Engine: User Preferences Analysis:');
      print('   - Preferred Brands: ${_userPreferences['preferred_brands']}');
      print('   - Preferred Fuel Types: ${_userPreferences['preferred_fuel_types']}');
      print('   - Preferred Seats Range: ${_userPreferences['preferred_seats_range']}');
      print('   - Preferred Price Range: ₹${_userPreferences['preferred_price_range']}');
      print('   - Preferred Car Types: ${_userPreferences['preferred_car_types']}');
      print('   - Average Booking Price: ₹${_userPreferences['avg_booking_price']}');
      print('   - Total Bookings: ${_preferenceCounts['total_bookings']}');
      print('   - Completed Bookings: ${_preferenceCounts['completed_bookings']}');

    } catch (e) {
      print('❌ SVM Engine: Error during training: $e');
      _isTrained = false;
    }
  }

  void _analyzeUserPreferences(List<CarBooking> bookings) {
    final brandPreferences = <String, int>{};
    final fuelPreferences = <String, int>{};
    final seatPreferences = <int, int>{};
    final pricePreferences = <double>[];
    final typePreferences = <String, int>{};

    _preferenceCounts['total_bookings'] = bookings.length;
    _preferenceCounts['completed_bookings'] = bookings.where((b) => b.status.toLowerCase() == 'completed').length;
    _preferenceCounts['accepted_bookings'] = bookings.where((b) => b.status.toLowerCase() == 'accepted').length;

    for (final booking in bookings) {
      // Brand preference
      if (booking.carBrand != null && booking.carBrand!.isNotEmpty) {
        final brand = booking.carBrand!.toLowerCase().trim();
        brandPreferences[brand] = (brandPreferences[brand] ?? 0) + 1;
      }

      // Fuel type preference - extract from car name/brand
      final fuelType = _extractFuelTypeFromBooking(booking);
      if (fuelType.isNotEmpty) {
        fuelPreferences[fuelType] = (fuelPreferences[fuelType] ?? 0) + 1;
      }

      // Seat preference
      final seats = booking.seats != null ? int.tryParse(booking.seats!) ?? 4 : 4;
      seatPreferences[seats] = (seatPreferences[seats] ?? 0) + 1;

      // Price preference
      pricePreferences.add(booking.totalPrice);

      // Car type preference
      final carType = _inferCarType(booking);
      if (carType.isNotEmpty) {
        typePreferences[carType] = (typePreferences[carType] ?? 0) + 1;
      }
    }

    // Calculate preference scores
    _calculatePreferenceScores(
      brandPreferences,
      fuelPreferences,
      seatPreferences,
      pricePreferences,
      typePreferences,
    );
  }

  String _extractFuelTypeFromBooking(CarBooking booking) {
    // Analyze car name and brand to infer fuel type
    final carName = booking.carName.toLowerCase();
    final carBrand = booking.carBrand?.toLowerCase() ?? '';

    if (carName.contains('electric') || carBrand.contains('electric')) return 'electric';
    if (carName.contains('diesel') || carBrand.contains('diesel')) return 'diesel';
    if (carName.contains('cng') || carBrand.contains('cng')) return 'cng';
    if (carName.contains('hybrid') || carBrand.contains('hybrid')) return 'hybrid';

    // Default to petrol for most cars
    return 'petrol';
  }

  String _inferCarType(CarBooking booking) {
    final carName = booking.carName.toLowerCase();
    final price = booking.totalPrice;
    final seats = booking.seats != null ? int.tryParse(booking.seats!) ?? 4 : 4;

    if (carName.contains('suv') || carName.contains('xuv') || seats > 6) return 'suv';
    if (carName.contains('hatchback') || carName.contains('hatch')) return 'hatchback';
    if (carName.contains('sedan') || (seats >= 4 && seats <= 5)) return 'sedan';
    if (carName.contains('luxury') || carName.contains('premium') || price > 3000) return 'luxury';
    if (carName.contains('sports') || carName.contains('coupe')) return 'sports';

    return 'standard';
  }

  void _calculatePreferenceScores(
      Map<String, int> brandPrefs,
      Map<String, int> fuelPrefs,
      Map<int, int> seatPrefs,
      List<double> pricePrefs,
      Map<String, int> typePrefs,
      ) {
    // Get top 3 preferred brands
    _userPreferences['preferred_brands'] = _getTopPreferences(brandPrefs, 3);

    // Get top 2 preferred fuel types
    _userPreferences['preferred_fuel_types'] = _getTopPreferences(fuelPrefs, 2);

    // Get seat range (min, max, average)
    _userPreferences['preferred_seats_range'] = _getSeatRange(seatPrefs);

    // Get price range
    _userPreferences['preferred_price_range'] = _getPriceRange(pricePrefs);
    _userPreferences['avg_booking_price'] = pricePrefs.isNotEmpty
        ? pricePrefs.reduce((a, b) => a + b) / pricePrefs.length
        : 0.0;

    // Get top 2 preferred car types
    _userPreferences['preferred_car_types'] = _getTopPreferences(typePrefs, 2);
  }

  List<String> _getTopPreferences(Map<String, int> prefs, int limit) {
    if (prefs.isEmpty) return [];

    final sorted = prefs.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(limit).map((e) => e.key).toList();
  }

  List<int> _getSeatRange(Map<int, int> seatPrefs) {
    if (seatPrefs.isEmpty) return [4, 7]; // Default range

    final seats = seatPrefs.keys.toList();
    seats.sort();

    final minSeats = seats.first;
    final maxSeats = seats.last;
    final avgSeats = (seatPrefs.entries.map((e) => e.key * e.value).reduce((a, b) => a + b) ~/
        seatPrefs.values.reduce((a, b) => a + b));

    return [minSeats, maxSeats, avgSeats];
  }

  List<double> _getPriceRange(List<double> prices) {
    if (prices.isEmpty) return [500.0, 2500.0]; // Default range

    prices.sort();
    final minPrice = prices.first;
    final maxPrice = prices.last;
    final avgPrice = prices.reduce((a, b) => a + b) / prices.length;

    return [minPrice, maxPrice, avgPrice];
  }

  // Get recommendations based on available cars
  List<CarRecommendation> getRecommendations(List<CarDataModel> allCars, int limit) {
    print('🎯 SVM Engine: Generating recommendations for ${allCars.length} cars');

    if (!_isTrained) {
      print('⚠️ SVM Engine: Model not trained, using default recommendations');
      return _getDefaultRecommendations(allCars, limit);
    }

    if (allCars.isEmpty) {
      print('❌ SVM Engine: No cars available for recommendations');
      return [];
    }

    try {
      final recommendations = allCars.map((car) {
        final score = _calculateCarMatchScore(car);
        final reason = _generateRecommendationReason(score, car);

        return CarRecommendation(
          car: car,
          confidenceScore: score,
          reason: reason,
        );
      }).toList();

      // Sort by confidence score (descending)
      recommendations.sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));

      final topRecommendations = recommendations.take(limit).toList();

      print('✅ SVM Engine: Generated ${topRecommendations.length} recommendations');
      for (int i = 0; i < topRecommendations.length; i++) {
        final rec = topRecommendations[i];
        print('   ${i + 1}. ${rec.car.carName} - Score: ${(rec.confidenceScore * 100).toStringAsFixed(1)}% - Reason: ${rec.reason}');
      }

      return topRecommendations;
    } catch (e) {
      print('❌ SVM Engine: Error generating recommendations: $e');
      return _getDefaultRecommendations(allCars, limit);
    }
  }

  double _calculateCarMatchScore(CarDataModel car) {
    double totalScore = 0.0;
    int factorsMatched = 0;

    // 1. Brand match (25% weight)
    final brandScore = _calculateBrandMatch(car.carBrand);
    if (brandScore > 0) factorsMatched++;
    totalScore += brandScore * 0.25;

    // 2. Fuel type match (20% weight)
    final fuelScore = _calculateFuelMatch(car.fuelType);
    if (fuelScore > 0) factorsMatched++;
    totalScore += fuelScore * 0.20;

    // 3. Seat count match (20% weight)
    final seatScore = _calculateSeatMatch(car.noOfSeats);
    if (seatScore > 0) factorsMatched++;
    totalScore += seatScore * 0.20;

    // 4. Price match (20% weight)
    final priceScore = _calculatePriceMatch(car.basicPrice);
    if (priceScore > 0) factorsMatched++;
    totalScore += priceScore * 0.20;

    // 5. Car type match (15% weight)
    final typeScore = _calculateTypeMatch(car.label);
    if (typeScore > 0) factorsMatched++;
    totalScore += typeScore * 0.15;

    // Bonus for high ratings
    final ratingBonus = (car.avg_rating / 5.0) * 0.1;
    totalScore += ratingBonus;

    // Normalize score based on factors matched
    if (factorsMatched > 0) {
      final normalizationFactor = factorsMatched / 5.0;
      totalScore = totalScore / normalizationFactor;
    }

    return totalScore.clamp(0.0, 1.0);
  }

  double _calculateBrandMatch(String carBrand) {
    final preferredBrands = _userPreferences['preferred_brands'] as List<String>;
    if (preferredBrands.isEmpty) return 0.3;

    final carBrandLower = carBrand.toLowerCase();

    // Exact match
    if (preferredBrands.any((brand) => carBrandLower.contains(brand))) {
      return 1.0;
    }

    // Partial match
    for (final preferredBrand in preferredBrands) {
      if (carBrandLower.contains(preferredBrand) || preferredBrand.contains(carBrandLower)) {
        return 0.7;
      }
    }

    return 0.1;
  }

  double _calculateFuelMatch(String carFuelType) {
    final preferredFuels = _userPreferences['preferred_fuel_types'] as List<String>;
    if (preferredFuels.isEmpty) return 0.3;

    final carFuelLower = carFuelType.toLowerCase();

    if (preferredFuels.contains(carFuelLower)) {
      return 1.0;
    }

    return 0.2;
  }

  double _calculateSeatMatch(int carSeats) {
    final seatRange = _userPreferences['preferred_seats_range'] as List<int>;
    if (seatRange.length < 3) return 0.3;

    final minSeats = seatRange[0];
    final maxSeats = seatRange[1];
    final avgSeats = seatRange[2];

    if (carSeats >= minSeats && carSeats <= maxSeats) {
      if (carSeats == avgSeats) return 1.0;
      final diff = (carSeats - avgSeats).abs();
      return 1.0 - (diff / 10.0); // Normalize by max possible difference
    }

    return 0.1;
  }

  double _calculatePriceMatch(double carPrice) {
    final priceRange = _userPreferences['preferred_price_range'] as List<double>;
    if (priceRange.length < 3) return 0.3;

    final minPrice = priceRange[0];
    final maxPrice = priceRange[1];
    final avgPrice = priceRange[2];

    if (carPrice >= minPrice && carPrice <= maxPrice) {
      final priceRatio = carPrice / avgPrice;
      if (priceRatio >= 0.8 && priceRatio <= 1.2) return 1.0; // Within 20% of average
      if (priceRatio >= 0.6 && priceRatio <= 1.4) return 0.7; // Within 40% of average
      return 0.4;
    }

    return 0.1;
  }

  double _calculateTypeMatch(String carType) {
    final preferredTypes = _userPreferences['preferred_car_types'] as List<String>;
    if (preferredTypes.isEmpty) return 0.3;

    final carTypeLower = carType.toLowerCase();

    if (preferredTypes.contains(carTypeLower)) {
      return 1.0;
    }

    // Check for partial matches
    for (final preferredType in preferredTypes) {
      if (carTypeLower.contains(preferredType) || preferredType.contains(carTypeLower)) {
        return 0.6;
      }
    }

    return 0.2;
  }

  String _generateRecommendationReason(double score, CarDataModel car) {
    if (score > 0.85) return 'Perfect match with your booking history! ★';
    if (score > 0.75) return 'Excellent match based on your preferences';
    if (score > 0.65) return 'Great fit for your usual choices';
    if (score > 0.55) return 'Good match with high user ratings';
    if (score > 0.45) return 'Similar to cars you\'ve enjoyed';
    if (score > 0.35) return 'Popular choice with great features';

    // Specific reasons based on car attributes
    final preferredBrands = _userPreferences['preferred_brands'] as List<String>;
    if (preferredBrands.isNotEmpty && preferredBrands.any((brand) => car.carBrand.toLowerCase().contains(brand))) {
      return 'Matches your preferred brand';
    }

    return 'Well-rated vehicle worth considering';
  }

  List<CarRecommendation> _getDefaultRecommendations(List<CarDataModel> allCars, int limit) {
    print('🔧 SVM Engine: Using default rating-based recommendations');

    return allCars
        .where((car) => car.avg_rating >= 2.0) // Lower threshold for more options
        .map((car) {
      final score = (car.avg_rating / 5.0) * 0.6 + 0.4; // Base score on rating with bonus
      return CarRecommendation(
        car: car,
        confidenceScore: score,
        reason: 'Highly rated by users ⭐ (${car.avg_rating.toStringAsFixed(1)}/5.0)',
      );
    })
        .toList()
      ..sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore))
      ..take(limit)
          .toList();
  }

  bool get isTrained => _isTrained;
  Map<String, dynamic> get userPreferences => _userPreferences;
  Map<String, int> get preferenceCounts => _preferenceCounts;
  List<CarBooking> get trainingData => _trainingData;
  int get trainingDataSize => _trainingData.length;
}