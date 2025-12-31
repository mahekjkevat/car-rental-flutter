import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../car_booking_model.dart';
import '../car_data_model.dart';
import 'car_recommendation_model.dart';
import 'svm_recommendation_engine.dart';

class RecommendationUtils {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch user's booking history for training
  static Future<List<CarBooking>> getUserBookingHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ RecommendationUtils: User not logged in');
      return [];
    }

    try {
      print('📡 RecommendationUtils: Fetching booking history from Firebase...');

      final querySnapshot = await _firestore
          .collection('Users')
          .doc(user.uid)
          .collection('car_booking')
          .where('status', whereIn: ['completed', 'accepted', 'confirmed'])
          .orderBy('bookingTime', descending: true)
          .limit(50) // Increased limit for better training
          .get();

      final bookings = querySnapshot.docs.map((doc) {
        return CarBooking.fromFirestore(doc.data(), doc.id);
      }).toList();

      print('✅ RecommendationUtils: Successfully fetched ${bookings.length} bookings');

      // Log booking details for debugging
      for (final booking in bookings.take(3)) { // Show first 3 for debugging
        print('   - ${booking.carName} (${booking.carBrand}) - Status: ${booking.status} - Price: ₹${booking.totalPrice}');
      }

      return bookings;
    } catch (e) {
      print('❌ RecommendationUtils: Error fetching booking history: $e');
      return [];
    }
  }

  // Fetch all cars from database
  static Future<List<CarDataModel>> getAllCars() async {
    try {
      print('📡 RecommendationUtils: Fetching all cars from Firebase...');

      final querySnapshot = await _firestore
          .collection('CarData')
          .get();

      final cars = querySnapshot.docs.map((doc) {
        return CarDataModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      print('✅ RecommendationUtils: Successfully fetched ${cars.length} cars');

      // Log car details for debugging
      for (final car in cars.take(3)) {
        print('   - ${car.carName} (${car.carBrand}) - Seats: ${car.noOfSeats} - Price: ₹${car.basicPrice}');
      }

      return cars;
    } catch (e) {
      print('❌ RecommendationUtils: Error fetching cars: $e');
      return [];
    }
  }

  // Get car recommendations for user
  static Future<List<CarRecommendation>> getPersonalizedRecommendations({
    int limit = 6,
  }) async {
    print('\n🎯 RecommendationUtils: Starting recommendation process...');

    // Step 1: Fetch all required data
    final userBookings = await getUserBookingHistory();
    final allCars = await getAllCars();

    if (allCars.isEmpty) {
      print('❌ RecommendationUtils: No cars available for recommendations');
      return [];
    }

    // Step 2: Initialize and train SVM engine
    final engine = SVMRecommendationEngine();

    print('🔧 RecommendationUtils: Training SVM engine...');
    await engine.trainModel(userBookings);

    // Step 3: Generate recommendations
    print('🔧 RecommendationUtils: Generating recommendations...');
    final recommendations = engine.getRecommendations(allCars, limit);

    // Step 4: Log final results
    print('\n📊 RecommendationUtils: FINAL RESULTS');
    print('   - User Bookings: ${userBookings.length}');
    print('   - Available Cars: ${allCars.length}');
    print('   - Engine Trained: ${engine.isTrained}');
    print('   - Recommendations Generated: ${recommendations.length}');
    print('   - Training Data Used: ${engine.trainingDataSize} bookings');

    return recommendations;
  }

  // Get recommendation explanation for UI
  static String getRecommendationExplanation(int bookingCount) {
    if (bookingCount == 0) {
      return 'Based on popular choices and high ratings across all users';
    } else if (bookingCount < 3) {
      return 'Starting to learn your preferences from recent bookings';
    } else if (bookingCount < 10) {
      return 'Personalized using your recent booking history';
    } else {
      return 'Highly personalized using your extensive booking history';
    }
  }

  // Get engine status for debugging
  static Future<Map<String, dynamic>> getEngineStatus() async {
    final userBookings = await getUserBookingHistory();
    final engine = SVMRecommendationEngine();
    await engine.trainModel(userBookings);

    return {
      'isTrained': engine.isTrained,
      'userBookings': userBookings.length,
      'preferences': engine.userPreferences,
      'counts': engine.preferenceCounts,
      'trainingDataSize': engine.trainingDataSize,
    };
  }
}