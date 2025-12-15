import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
// NOTE: This feature requires adding the 'speech_to_text' package to your pubspec.yaml
import 'package:speech_to_text/speech_to_text.dart';
import 'package:mahek_cafe/product_model.dart';
import 'package:mahek_cafe/MahekCoffeeToast.dart'; // Import the Toast utility

// Assuming ProductDetailPage is defined elsewhere for navigation.

/// Card inferred from popular_meal_card.dart snippet.
class PopularMealCard extends StatelessWidget {
  final String name;
  final double rating;
  final double price;
  final String description;
  final int index;
  final String imgUrl;

  // The primary color definition is consistent with the app's theme
  final Color primaryAppColor = const Color(0xFFE65100);
  final Color secondaryDarkColor = const Color(0xFF212121);

  const PopularMealCard({
    super.key,
    required this.name,
    required this.rating,
    required this.price,
    required this.description,
    required this.index,
    required this.imgUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: Implement navigation to ProductDetailPage
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        // Placeholder content for the card
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: CachedNetworkImage(
                  imageUrl: imgUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            ),
            // Details area
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: secondaryDarkColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${price.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: primaryAppColor,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: secondaryDarkColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductSearchFilterPage extends StatefulWidget {
  const ProductSearchFilterPage({super.key});

  @override
  State<ProductSearchFilterPage> createState() => _ProductSearchFilterPageState();
}

class _ProductSearchFilterPageState extends State<ProductSearchFilterPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];
  bool _isLoading = true;
  StreamSubscription<QuerySnapshot>? _productsSubscription;

  // Aesthetic Colors
  // Updated primaryAppColor to match the requested AppBar color
  final Color primaryAppColor = const Color(0xFFF96D0A); // Requested AppBar BG Color
  final Color secondaryDarkColor = const Color(0xFF212121);
  final Color lightBackground = const Color(0xFFF5F5F5);

  // --- Speech-to-Text Variables ---
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  // -------------------------------------

  @override
  void initState() {
    super.initState();
    _initSpeech(); // Initialize speech service
    _fetchProducts();
    _searchController.addListener(_onSearchChanged);
  }

  // --- Speech-to-Text Methods ---

  // Initialize the speech recognition service
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
        onStatus: (status) {
          if (mounted) {
            if (status == 'listening') {
              setState(() => _isListening = true);
            } else if (status == 'notListening') {
              setState(() => _isListening = false);
              // When listening stops, check if recognized words are available and show toast
              if (_searchController.text.isNotEmpty) {
                MahekCoffeeToast.show(
                  context,
                  "Searching for: ${_searchController.text}",
                );
              }
            }
          }
        },
        onError: (errorNotification) {
          if (mounted) {
            print("Speech Error: ${errorNotification.errorMsg}");
            MahekCoffeeToast.show(
              context,
              "Speech Error: ${errorNotification.errorMsg}",
              isError: true,
            );
            setState(() => _isListening = false);
          }
        }
    );
    if (mounted) {
      setState(() {});
    }
    if (!_speechEnabled) {
      print("Speech recognition not available.");
    }
  }

  // Start listening for user speech
  void _startListening() async {
    if (_speechEnabled && !_isListening) {
      setState(() {
        _isListening = true;
        _searchController.clear(); // Clear text field when starting to listen
      });
      await _speechToText.listen(
        onResult: (result) {
          if (mounted) {
            // Update text controller with recognized speech
            setState(() {
              _searchController.text = result.recognizedWords;
              // Move cursor to end of text
              _searchController.selection = TextSelection.fromPosition(
                TextPosition(offset: _searchController.text.length),
              );
            });
            // Stop listening after final result, which will trigger _onSearchChanged
            if (result.finalResult) {
              _stopListening();
              // Toast moved to onStatus listener for 'notListening' for clean separation
            }
          }
        },
        listenFor: const Duration(seconds: 10), // Listen for up to 10 seconds
        // You can specify the locale here if needed, e.g., localeId: 'en_US'
      );
    }
  }

  // Stop listening for user speech
  void _stopListening() async {
    await _speechToText.stop();
    if (mounted) {
      setState(() => _isListening = false);
    }
  }

  // -------------------------------------


  void _fetchProducts() {
    // This is a placeholder for fetching all products from a single collection.
    _productsSubscription = FirebaseFirestore.instance
        .collection('products')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          // Assuming ProductModel.fromFirestore is defined and works correctly
          _allProducts = snapshot.docs
              .map((doc) => ProductModel.fromFirestore(doc.data()))
              .toList();
          // Initially, filter based on any existing query
          _filterProducts(_searchQuery);
          _isLoading = false;
        });
      }
    }, onError: (error) {
      if (mounted) {
        print("Error fetching products: $error");
        setState(() => _isLoading = false);
      }
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    if (query != _searchQuery) {
      setState(() {
        _searchQuery = query;
      });
      _filterProducts(query);
    }
  }

  void _filterProducts(String query) {
    final lowerCaseQuery = query.toLowerCase().trim();
    if (lowerCaseQuery.isEmpty) {
      setState(() {
        _filteredProducts = _allProducts;
      });
      return;
    }

    setState(() {
      _filteredProducts = _allProducts.where((product) {
        return product.name.toLowerCase().contains(lowerCaseQuery) ||
            product.description.toLowerCase().contains(lowerCaseQuery);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _productsSubscription?.cancel();

    // Dispose of speech service
    if (_speechToText.isListening) {
      _speechToText.stop();
    }

    super.dispose();
  }

  // Helper widget to build the search bar
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30.0),
          boxShadow: [
            BoxShadow(
              color: primaryAppColor.withOpacity(0.1), // Subtle shadow using primary color
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: GoogleFonts.poppins(fontSize: 16, color: secondaryDarkColor),
          decoration: InputDecoration(
            hintText: _isListening ? 'Listening...' : 'Search for a meal...',
            hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
            prefixIcon: Icon(Icons.search, color: primaryAppColor.withOpacity(0.7)),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min, // Important for Row inside suffixIcon
              children: [
                // 1. Clear Button
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                      _filterProducts('');
                      _stopListening(); // Stop listening if clearing text
                    },
                  ),
                // 2. Speech-to-Text Button (NEW)
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    // Use primaryAppColor when listening for an active feedback look
                    color: _isListening ? primaryAppColor : Colors.grey.shade600,
                  ),
                  onPressed: _speechEnabled
                      ? (_isListening ? _stopListening : _startListening)
                      : null, // Disable if speech not enabled
                  tooltip: _speechEnabled
                      ? (_isListening ? 'Tap to Stop' : 'Tap to Speak')
                      : 'Speech not available',
                ),
                const SizedBox(width: 8.0), // Add some space
              ],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0),
              borderSide: BorderSide.none,
            ),
            filled: false, // Set to false since the container handles the fill
            contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    MahekCoffeeToast.init(context);

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: Text(
          'Product Search',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white, // Requested White text
          ),
        ),
        backgroundColor: primaryAppColor, // Requested 0xFFF96D0A
        elevation: 4, // Added slight elevation for depth
        iconTheme: const IconThemeData(color: Colors.white), // Requested White icons
        // Added a back button
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: primaryAppColor))
                : _filteredProducts.isEmpty && _searchQuery.isNotEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sentiment_dissatisfied_rounded,
                    size: 60,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No results for "$_searchQuery"',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    'Try a different search term.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            )
                : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 0.75,
                ),
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = _filteredProducts[index];
                  // Meal Card is Perfect - using the existing widget
                  return PopularMealCard(
                    name: product.name,
                    rating: product.rate,
                    price: product.price,
                    description: product.description,
                    index: index,
                    imgUrl: product.imgUrl,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
