import 'package:flutter/material.dart';
import 'package:gear_go/view_car_page.dart';
import 'package:gear_go/car_data_model.dart';
import 'package:gear_go/machine_learning/recommendation_utils.dart';
import '../widgets/svm_car_display.dart';
import 'package:gear_go/machine_learning/widgets/debug_info_page.dart'; // Add this import

class RecommendedCarsPage extends StatefulWidget {
  const RecommendedCarsPage({Key? key}) : super(key: key);

  @override
  _RecommendedCarsPageState createState() => _RecommendedCarsPageState();
}

class _RecommendedCarsPageState extends State<RecommendedCarsPage> {
  late List<CarDataModel> _allCars = [];
  late Set<String> _favoriteCarIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      print('📱 RecommendedCarsPage: Loading data...');

      // Fetch cars using the utility function
      final cars = await RecommendationUtils.getAllCars();
      final favorites = await _fetchUserFavorites();

      setState(() {
        _allCars = cars;
        _favoriteCarIds = favorites;
        _isLoading = false;
      });

      print('✅ RecommendedCarsPage: Data loaded successfully');
      print('   - Cars: ${_allCars.length}');
      print('   - Favorites: ${_favoriteCarIds.length}');

    } catch (e) {
      print('❌ RecommendedCarsPage: Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Set<String>> _fetchUserFavorites() async {
    // Implement your favorites fetching logic here
    return {}; // Replace with actual implementation
  }

  void _onFavoriteToggle(CarDataModel car) {
    final isFav = _favoriteCarIds.contains(car.documentId);
    if (isFav) {
      _showRemoveFavoriteConfirmation(car);
    } else {
      _showAddToFavoritesDialog(car);
    }
  }

  void _showRemoveFavoriteConfirmation(CarDataModel car) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Remove from Favorites?"),
        content: Text("Are you sure you want to remove this car from your favorites?"),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _removeFavorite(car);
              setState(() {
                _favoriteCarIds.remove(car.documentId);
              });
            },
            child: Text("Yes, Remove"),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text("Cancel"),
          ),
        ],
      ),
    );
  }

  void _showAddToFavoritesDialog(CarDataModel car) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Add to Favorites?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Text("Would you like to add ${car.carName} to your favorites?"),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _addFavorite(car);
                      setState(() {
                        _favoriteCarIds.add(car.documentId);
                      });
                    },
                    child: Text("Add to Favorites"),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addFavorite(CarDataModel car) async {
    print('⭐ Added ${car.carName} to favorites');
  }

  Future<void> _removeFavorite(CarDataModel car) async {
    print('⭐ Removed ${car.carName} from favorites');
  }

  void _showDebugInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DebugInfoPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Recommendations',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
            letterSpacing: 0.5,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3,
                color: Colors.black12,
              ),
            ],
          ),
        ),
        backgroundColor: Colors.blue[800],
        elevation: 4,
        shadowColor: Colors.blue[900]?.withOpacity(0.3),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Icon(
                Icons.analytics,
                color: Colors.white,
                size: 26,
              ),
              onPressed: _showDebugInfo,
              tooltip: 'View Analysis',
              splashRadius: 24,
              visualDensity: VisualDensity.comfortable,
              splashColor: Colors.white24,
              highlightColor: Colors.white12,
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading Recommendations...',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              'Analyzing your booking history',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      )
          : SVMCarDisplay(
        allCars: _allCars,
        onCarTap: (car) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ViewCarPage(carData: car)),
          );
        },
        onFavoriteToggle: _onFavoriteToggle,
        favoriteCarIds: _favoriteCarIds,
      ),
    );
  }
}