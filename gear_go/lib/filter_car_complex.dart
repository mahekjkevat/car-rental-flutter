import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gear_go/custom_toast.dart';
import 'package:gear_go/filter_car_data_show.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'car_data_model.dart';

class FilterCarComplex extends StatefulWidget {
  const FilterCarComplex({Key? key}) : super(key: key);

  @override
  _FilterCarComplexState createState() => _FilterCarComplexState();
}

class _FilterCarComplexState extends State<FilterCarComplex> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<CarDataModel> _cars = [];
  bool _isLoading = true;

  // Filter state
  String _selectedBrand = 'All';

  // Price filter variables
  String _priceType = 'basic_price'; // default
  double _priceRangeMin = 100.0;
  double _priceRangeMax = 500.0;
int _divisions = 8; // (500-100)/50 = 8

  double _currentPrice = 0.0;
  String _selectedRating = 'All';

  final List<Map<String, dynamic>> _ratings = [
    {'label': '4.5 and above', 'value': '4.5', 'min': 4.5},
    {'label': '4.0 - 4.5', 'value': '4.0-4.5', 'min': 4.0, 'max': 4.5},
    {'label': '3.5 - 4.0', 'value': '3.5-4.0', 'min': 3.5, 'max': 4.0},
    {'label': '3.0 - 3.5', 'value': '3.0-3.5', 'min': 3.0, 'max': 3.5},
    {'label': '2.5 - 3.0', 'value': '2.5-3.0', 'min': 2.5, 'max': 3.0},
  ];
void _updateDivisions() {
  _divisions = ((_priceRangeMax - _priceRangeMin) / 50).round();
}
  List<String> get _brands {
    Set<String> uniqueBrands = {'All'};
    for (var car in _cars) {
      if (car.carBrand.isNotEmpty) {
        uniqueBrands.add(car.carBrand);
      }
    }
    return uniqueBrands.toList();
  }

@override
void initState() {
  super.initState();
  _fetchCars().then((_) {
    if (_cars.isNotEmpty) {
      setState(() {
        _currentPrice = _priceRangeMin; // default to 100
      });
    }
  });
}

  Future<void> _fetchCars() async {
    setState(() => _isLoading = true);
    try {
      QuerySnapshot snapshot = await _firestore.collection('CarData').get();
      _cars =
          snapshot.docs.map((doc) {
            return CarDataModel.fromJson(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();

      if (_cars.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        Fluttertoast.showToast(
          msg: "No cars available at the moment.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
      } else {
        setState(() => _isLoading = false);
        // Initialize currentPrice based on first car
        if (_cars.isNotEmpty) {
          _updateCurrentPrice();
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error fetching cars: $e");
      setState(() => _isLoading = false);
    }
  }

  void _updateCurrentPrice() {
    if (_cars.isEmpty) return;
    switch (_priceType) {
      case 'basic_price':
        _currentPrice = _cars[0].basicPrice;
        break;
      case 'max_price':
        _currentPrice = _cars[0].maxPrice;
        break;
      case 'plus_price':
        _currentPrice = _cars[0].plusPrice;
        break;
    }
  }

  String _getPriceTypeLabel() {
    switch (_priceType) {
      case 'basic_price':
        return 'Basic Subscription';
      case 'max_price':
        return 'Max Subscription';
      case 'plus_price':
        return 'Plus Subscription';
      default:
        return '';
    }
  }

  void _applyFilters() {
    List<CarDataModel> results =
        _cars.where((car) {
          // Filter by brand
          bool matchesBrand =
              _selectedBrand == 'All' ||
              car.carBrand.toLowerCase() == _selectedBrand.toLowerCase();

          // Filter by price based on selected price type
          bool matchesPrice = false;
          switch (_priceType) {
            case 'basic_price':
              matchesPrice = car.basicPrice <= _currentPrice;
              break;
            case 'max_price':
              matchesPrice = car.maxPrice <= _currentPrice;
              break;
            case 'plus_price':
              matchesPrice = car.plusPrice <= _currentPrice;
              break;
          }

          // Filter by rating
          bool matchesRating;
          if (_selectedRating == 'All') {
            matchesRating = true;
          } else if (_selectedRating == 'Reviews') {
            // Ratings 4.5 and above
            double minRatingThreshold = 4.5;
            matchesRating = (car.avg_rating ?? 1.0) >= minRatingThreshold;
          } else {
            final ratingRange = _ratings.firstWhere(
              (rating) => rating['value'] == _selectedRating,
            );
            double minRating = ratingRange['min'];
            double maxRating = ratingRange['max'] ?? 5.0;
            double carRating = car.avg_rating ?? 1.0;
            matchesRating = carRating >= minRating && carRating <= maxRating;
          }

          return matchesPrice && matchesBrand && matchesRating;
        }).toList();

    if (results.isEmpty) {
      CustomToast.show(
        context: context,
        message: "No cars found for the selected filters.",
        duration: Duration(seconds: 2),
        textColor: Colors.white,
        gradientColors: [Colors.red, Colors.orange],
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FilterCarDataShow(filteredCars: results),
        ),
      );
      CustomToast.show(
        context: context,
        message: "Filters applied! Cars found.",
        duration: Duration(seconds: 2),
        textColor: Colors.white,
        gradientColors: [Colors.red, Colors.orange],
      );
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedBrand = 'All';
      _priceRangeMin = 50.0;
      _priceRangeMax = 400.0;
      _selectedRating = 'All';
      _priceType = 'basic_price';
      if (_cars.isNotEmpty) {
        _updateCurrentPrice();
      }
    });
    CustomToast.show(
      context: context,
      message: "Filters reset successfully!",
      duration: Duration(seconds: 2),
      textColor: Colors.white,
      gradientColors: [Colors.red, Colors.orange],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Filter',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.blue),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Car Brand filter
                    Text(
                      'Car Brand',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _brands.length,
                        itemBuilder: (context, index) {
                          final brand = _brands[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(brand),
                              selected: _selectedBrand == brand,
                              onSelected: (selected) {
                                setState(() => _selectedBrand = brand);
                              },
                              selectedColor: Colors.blue[700],
                              backgroundColor: Colors.grey[200],
                              labelStyle: GoogleFonts.poppins(
                                color:
                                    _selectedBrand == brand
                                        ? Colors.white
                                        : Colors.black87,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Price Range (${_getPriceTypeLabel()})',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    // Price Type dropdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Change Subscription Type',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 70),
                            // Price Type Dropdown
                            DropdownButton<String>(
                              value: _priceType,
                              items: [
                                DropdownMenuItem(
                                  child: Text(
                                    'Basic',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  value: 'basic_price',
                                ),
                                DropdownMenuItem(
                                  child: Text(
                                    'Max',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  value: 'max_price',
                                ),
                                DropdownMenuItem(
                                  child: Text(
                                    'Plus',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  value: 'plus_price',
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _priceType = value!;
                                  _updateCurrentPrice();
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Price Slider
Slider(
  value: _currentPrice,
  min: _priceRangeMin,
  max: _priceRangeMax,
  divisions: _divisions,
  label: '₹${_currentPrice.round()}',
  activeColor: Colors.blue,
  inactiveColor: Colors.grey[300],
  onChanged: (value) {
    setState(() => _currentPrice = value);
  },
),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${_priceRangeMin.round()}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          '₹${_priceRangeMax.round()}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Ratings filters inside a styled Card
                    Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reviews',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(),
                            ..._ratings.map((rating) {
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      for (int i = 0; i < 5; i++)
                                        Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 20,
                                        ),
                                      Text(
                                        ' ${rating['label']}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Radio<String>(
                                    value: rating['value'] as String,
                                    groupValue: _selectedRating,
                                    onChanged: (value) {
                                      setState(() => _selectedRating = value!);
                                    },
                                    activeColor: Colors.blue,
                                  ),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _resetFilters,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Reset Filter',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _applyFilters,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Apply',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
    );
  }
}
