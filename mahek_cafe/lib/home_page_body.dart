// file: lib/home_page_body.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:mahek_cafe/popular_meal_card.dart';
import 'package:mahek_cafe/restaurant_card_view.dart';
import 'PromoDetailsPage.dart';
import 'product_model.dart';
import 'category_model.dart';

class HomePageBody extends StatefulWidget {
  const HomePageBody({super.key});

  @override
  _HomePageBodyState createState() => _HomePageBodyState();
}

class _HomePageBodyState extends State<HomePageBody>
    with SingleTickerProviderStateMixin {
  String _selectedCategoryType = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isCategoriesLoaded = false;
  bool _isProductsLoaded = false;
  final GlobalKey<State> _keyLoader = GlobalKey<State>();

  // Aesthetic Colors
  final Color primaryAppColor = const Color(0xFFF96D0A); // Vibrant Orange/Red
  final Color secondaryDarkColor = const Color(0xFF333333);
  final Color lightBackground = const Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLoadingDialog(context);
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showLoadingDialog(BuildContext context) {
    // ... (Loading Dialog implementation remains the same)
    if (!(_isCategoriesLoaded && _isProductsLoaded)) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return PopScope(
            canPop: false,
            child: Dialog(
              key: _keyLoader,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 8,
              backgroundColor: Colors.white,
              child: Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fastfood, color: primaryAppColor, size: 48),
                    const SizedBox(height: 16),
                    CircularProgressIndicator(color: primaryAppColor),
                    const SizedBox(height: 16),
                    Text(
                      'Preparing Your Order...',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: secondaryDarkColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
  }

  void _tryDismissDialog() {
    // ... (Dismiss Dialog implementation remains the same)
    if (_isCategoriesLoaded && _isProductsLoaded) {
      if (_keyLoader.currentContext != null &&
          Navigator.of(_keyLoader.currentContext!).canPop()) {
        Navigator.of(_keyLoader.currentContext!).pop();
      }
    }
  }

  // --- Navigation Handler for Banner ---
  void _openPromoPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => const PromoDetailsPage(
              title: 'Weekly Special: FREE DELIVERY',
              tagline: 'Claim your free delivery now on all orders over \$10!',
            ),
      ),
    );
  }

  // -------------------------------------

  @override
  Widget build(BuildContext context) {
    return Container(
      color: lightBackground,
      child: CustomScrollView(
        slivers: [
          // Promotional Banner - WRAPPED IN GESTURE DETECTOR
          SliverToBoxAdapter(
            child: GestureDetector(
              // <--- WRAPPER
              onTap: _openPromoPage, // <--- CALL HANDLER
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryAppColor.withOpacity(0.95),
                      primaryAppColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: primaryAppColor.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WEEKLY SPECIAL (Tap to view details)',
                            // Added instruction
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'FREE DELIVERY\nOn all orders over \$10',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.delivery_dining,
                      color: Colors.white,
                      size: 60,
                      shadows: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Popular Restaurants
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:  [
                Padding(
                  padding: EdgeInsets.only(left: 16.0, bottom: 10.0, top: 20.0),
                  child: Text(
                    "Popular Restaurants",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: secondaryDarkColor,
                    ),

                  ),
                ),
                const SizedBox(height: 5),
                HorizontalRestaurantList(), // Your new horizontal list widget

              ],
            ),
          ),
          // Category Tabs Header (Remains the same)
          SliverPadding(
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
            sliver: SliverToBoxAdapter(
              child: Text(
                'What are you craving?',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: secondaryDarkColor,
                ),
              ),
            ),
          ),

          // Category Tabs and Products Grid (Remaining code is the same)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('category')
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: primaryAppColor),
                    );
                  }

                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    _isCategoriesLoaded = true;
                    _tryDismissDialog();
                  }

                  if (snapshot.hasError) {
                    _isCategoriesLoaded = true;
                    _tryDismissDialog();
                    return Center(
                      child: Text(
                        'Error loading categories.',
                        style: GoogleFonts.poppins(color: Colors.red),
                      ),
                    );
                  }

                  final categories =
                      snapshot.data!.docs
                          .map(
                            (doc) => CategoryModel.fromFirestore(
                              doc.data() as Map<String, dynamic>,
                            ),
                          )
                          .toList();

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategoryType = 'All';
                            });
                          },
                          child: _buildCategoryTab(
                            'All',
                            _selectedCategoryType == 'All',
                            Icons.all_inclusive,
                          ),
                        ),
                        ...categories.map((category) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategoryType = category.type;
                              });
                            },
                            child: _buildCategoryTab(
                              category.name,
                              _selectedCategoryType == category.type,
                              Icons.local_dining,
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // Products Grid Header (Remains the same)
          SliverPadding(
            padding: const EdgeInsets.only(
              top: 16,
              left: 16,
              right: 16,
              bottom: 10,
            ),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Popular Meals',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: secondaryDarkColor,
                ),
              ),
            ),
          ),

          // Products Grid (Remains the same)
          StreamBuilder<QuerySnapshot>(
            stream:
                _selectedCategoryType == 'All'
                    ? FirebaseFirestore.instance
                        .collection('products')
                        .snapshots()
                    : FirebaseFirestore.instance
                        .collection('products')
                        .where('type', isEqualTo: _selectedCategoryType)
                        .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: CircularProgressIndicator(color: primaryAppColor),
                  ),
                );
              }

              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                _isProductsLoaded = true;
                _tryDismissDialog();
              }

              if (snapshot.hasError) {
                _isProductsLoaded = true;
                _tryDismissDialog();
                return SliverToBoxAdapter(
                  child: Center(
                    child: Text(
                      'Error loading products: ${snapshot.error}',
                      style: GoogleFonts.poppins(color: Colors.red),
                    ),
                  ),
                );
              }

              List<ProductModel> products =
                  snapshot.data!.docs
                      .map(
                        (doc) => ProductModel.fromFirestore(
                          doc.data() as Map<String, dynamic>,
                        ),
                      )
                      .toList();

              if (_searchQuery.isNotEmpty) {
                products =
                    products
                        .where(
                          (product) =>
                              product.name.toLowerCase().contains(_searchQuery),
                        )
                        .toList();
              }

              if (products.isEmpty) {
                _isProductsLoaded = true;
                _tryDismissDialog();
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        _searchQuery.isNotEmpty
                            ? 'No matching meals found.'
                            : 'No Meals Found in this category.',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: secondaryDarkColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: AnimationLimiter(
                  child: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.7,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final product = products[index];
                      return AnimationConfiguration.staggeredGrid(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        columnCount: 2,
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: PopularMealCard(
                              name: product.name,
                              rating: product.rate,
                              price: product.price,
                              description: product.description,
                              index: index,
                              imgUrl: product.imgUrl,
                            ),
                          ),
                        ),
                      );
                    }, childCount: products.length),
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
          // Padding at the bottom
        ],
      ),
    );
  }

  // Helper method to build category tabs (Remains the same)
  Widget _buildCategoryTab(String title, bool isSelected, IconData icon) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? primaryAppColor : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? primaryAppColor : Colors.grey.shade300,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color:
                isSelected
                    ? primaryAppColor.withOpacity(0.4)
                    : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? Colors.white : secondaryDarkColor,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: isSelected ? Colors.white : secondaryDarkColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
