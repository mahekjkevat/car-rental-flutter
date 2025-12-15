import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mahek_cafe/cart_page.dart';
import 'MahekCoffeeToast.dart';
import 'ConfirmOrderPage.dart';

// --- Reused and Clean ZoomableImageScreen (No Change Required) ---
class ZoomableImageScreen extends StatelessWidget {
  final String imgUrl;
  final String heroTag;
  final Color primaryBrown = const Color(0xFF6D4C41);

  const ZoomableImageScreen({
    super.key,
    required this.imgUrl,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: Hero(
              tag: heroTag,
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.8,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: imgUrl,
                  imageBuilder: (context, imageProvider) => Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(color: primaryBrown.withOpacity(0.5)),
                  ),
                  errorWidget: (context, url, error) => Icon(
                    Icons.error_outline_rounded,
                    color: Colors.grey[700],
                    size: 80,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: SafeArea(
              child: FloatingActionButton(
                mini: false,
                backgroundColor: Colors.white.withOpacity(0.9),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Close',
                child: Icon(Icons.close_rounded, color: primaryBrown),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------

// Enum for size selection
enum ProductSize { small, medium, large }

class ProductDetailPage extends StatefulWidget {
  final String name;
  final double rating;
  final double price; // This is now the base price for the LARGE size
  final String description;
  final String heroTag;
  final String imgUrl;

  const ProductDetailPage({
    super.key,
    required this.name,
    required this.rating,
    required this.price,
    required this.description,
    required this.heroTag,
    required this.imgUrl,
  });

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  // --- Constants (Extracted for conciseness) ---
  final Color _primaryBrown = const Color(0xFF6D4C41);
  final Color _accentOrange = const Color(0xFFF96D0A);
  final Color _lightBackground = const Color(0xFFFBFBFB);

  // --- State Variables ---
  ProductSize _selectedSize = ProductSize.large; // Default to Large, as it's the base price
  bool _isFavorite = false;
  bool _isButtonLoading = false;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // --- Price map based on new discount logic ---
  late final Map<ProductSize, double> _priceMap;

  // --- Utility Getters (for style and price) ---
  double get _calculatedPrice {
    return _priceMap[_selectedSize] ?? widget.price;
  }

  TextStyle get _headlineStyle => GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: _primaryBrown);

  // Custom Toast now called from MahekCoffeeToast class
  void _showCustomToast(String message, {bool isError = false}) {
    // NOTE: Replacing MahekCoffeeToast with SnackBar since the class definition is not available.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: GoogleFonts.poppins(color: Colors.white)), backgroundColor: isError ? Colors.red : _accentOrange),
    );
  }

  @override
  void initState() {
    super.initState();
    MahekCoffeeToast.init(context); // Commented out as MahekCoffeeToast file wasn't provided

    // Initialize price map based on the new logic: Large is base price.
    // Medium is 10% less, Small is 30% less.
    _priceMap = {
      ProductSize.large: widget.price,
      ProductSize.medium: widget.price * (1 - 0.10), // 10% less
      ProductSize.small: widget.price * (1 - 0.30),  // 30% less
    };
    _checkFavoriteStatus();
  }

  // --- Favorite Logic (No change, preserved) ---

  Future<void> _toggleFavorite() async {
    if (_currentUser == null) {
      _showCustomToast('Please log in to manage favorites.', isError: true);
      return;
    }

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('Favourites')
        .doc(widget.name);

    if (_isFavorite) {
      // Remove
      await docRef.delete();
      setState(() => _isFavorite = false);
      _showCustomToast('${widget.name} removed from favorites.', isError: true);
    } else {
      // Add
      await docRef.set({
        'name': widget.name,
        'price': _priceMap[ProductSize.large], // Store the base large price for consistency
        'imgUrl': widget.imgUrl,
        'rating': widget.rating,
        'description': widget.description,
        'timestamp': FieldValue.serverTimestamp(),
      });
      setState(() => _isFavorite = true);
      _showCustomToast('${widget.name} added to favorites!');
    }
  }

  Future<void> _checkFavoriteStatus() async {
    if (_currentUser == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('Favourites')
        .doc(widget.name);

    final doc = await docRef.get();
    setState(() => _isFavorite = doc.exists);
  }

  void _showFavoriteDialog() {
    if (_currentUser == null) {
      _showCustomToast('Please log in to manage favorites.', isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          _isFavorite ? 'Remove Favorite' : 'Add to Favorites',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: _primaryBrown),
        ),
        content: Text(
          _isFavorite
              ? 'Are you sure you want to remove ${widget.name} from your favorites?'
              : 'Do you want to add ${widget.name} to your favorites?',
          style: GoogleFonts.poppins(color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              _toggleFavorite();
              Navigator.pop(context); // Close dialog after action
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _isFavorite ? Colors.red[700] : _accentOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              _isFavorite ? 'Remove' : 'Add',
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // --- Cart Logic (Modified to use size instead of temperature) ---

  Future<Map<String, dynamic>?> _checkCartItemExists() async {
    if (_currentUser == null) return null;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('addToCart')
        .where('name', isEqualTo: widget.name)
        .where('size', isEqualTo: _selectedSize.name)
        .get();

    return snapshot.docs.isNotEmpty
        ? {'docId': snapshot.docs.first.id, 'quantity': snapshot.docs.first.data()['quantity']}
        : null;
  }

  void _showAddToCartDialog() async {
    if (_currentUser == null) {
      _showCustomToast('Please log in to add to cart.', isError: true);
      return;
    }

    final existingItem = await _checkCartItemExists();
    int quantity = existingItem?['quantity'] ?? 1;
    bool isUpdate = existingItem != null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          double currentSubtotal = quantity * _calculatedPrice;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            title: Text(
              isUpdate ? 'Update Order' : 'Customize Order',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w800, color: _primaryBrown, fontSize: 22),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: CachedNetworkImage(
                    imageUrl: widget.imgUrl,
                    height: 120,
                    width: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                Text(widget.name, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryBrown)),
                // Updated cart dialog text
                Text(
                  'Size: ${_selectedSize.name.toUpperCase()} | Unit: ₹${_calculatedPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(height: 20),

                // --- Quantity Selector (Cleaned Up) ---
                Text('Quantity', style: _headlineStyle.copyWith(fontSize: 16)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove_circle_rounded, color: quantity > 1 ? _accentOrange : Colors.grey, size: 36),
                      onPressed: () { if (quantity > 1) setDialogState(() => quantity--); },
                    ),
                    SizedBox(
                      width: 50,
                      child: Text('$quantity', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: _primaryBrown)),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle_rounded, color: quantity < 10 ? _accentOrange : Colors.grey, size: 36),
                      onPressed: () { if (quantity < 10) setDialogState(() => quantity++); },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // --- Subtotal Price ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Subtotal:', style: _headlineStyle.copyWith(fontSize: 18)),
                    Text(
                      '₹${currentSubtotal.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w900, color: _accentOrange),
                    ),
                  ],
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16)),
              ),
              ElevatedButton.icon(
                onPressed: () => _handleCartAction(context, isUpdate, existingItem?['docId'], quantity, currentSubtotal),
                icon: const Icon(Icons.shopping_cart_rounded, color: Colors.white),
                label: Text(
                  isUpdate ? 'Update' : 'Add to Cart',
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentOrange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Consolidated Cart Action Logic (Modified to store size)
  Future<void> _handleCartAction(BuildContext context, bool isUpdate, String? docId, int quantity, double subtotal) async {
    Navigator.pop(context);
    setState(() => _isButtonLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));

    final cartCollection = FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).collection('addToCart');

    if (isUpdate) {
      await cartCollection.doc(docId).update({
        'quantity': quantity,
        'price': _calculatedPrice,
        'subtotal': subtotal,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _showCustomToast('${widget.name} (${_selectedSize.name.toUpperCase()}) quantity updated!');
    } else {
      await cartCollection.add({
        'name': widget.name,
        'price': _calculatedPrice,
        'imgUrl': widget.imgUrl,
        'size': _selectedSize.name, // Storing size instead of isIce
        'quantity': quantity,
        'subtotal': subtotal,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _showCustomToast('${widget.name} (${_selectedSize.name.toUpperCase()}) added to cart!');
    }
    setState(() => _isButtonLoading = false);
  }

  void _navigateToCart() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const CartPage()));
  }

  // --- New: Build Size Selector Item (Radio Button) ---
  Widget _buildSizeSelector(ProductSize size, String label) {
    String priceText = '₹${(_priceMap[size] ?? 0.0).toStringAsFixed(2)}';

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSize = size;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Radio<ProductSize>(
                  value: size,
                  groupValue: _selectedSize,
                  onChanged: (ProductSize? newValue) {
                    setState(() {
                      _selectedSize = newValue!;
                    });
                  },
                  activeColor: _accentOrange,
                ),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: _primaryBrown,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 15.0),
              child: Text(
                priceText,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _primaryBrown,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Bottom Action Bar (Restored Buy Now button with updated styling) ---
  Widget _buildBottomBar(BuildContext context) {
    bool isDisabled = _isButtonLoading;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        // Use margin to lift the bar from the screen edge, similar to the original concept
        margin: const EdgeInsets.only(bottom: 25, left: 20, right: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: _primaryBrown.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Row(
          children: [
            // Price Display
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Price', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                  Text(
                    '₹${_calculatedPrice.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: _primaryBrown),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Add to Cart Button (Circular)
            ElevatedButton(
              onPressed: isDisabled ? null : _showAddToCartDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentOrange,
                padding: const EdgeInsets.all(12),
                shape: const CircleBorder(),
                elevation: 6,
              ),
              child: isDisabled && _isButtonLoading ?
              const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) :
              const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 10),

            // Buy Now Button (Restored)
            Expanded(
              child: ElevatedButton(
                onPressed: isDisabled ? null : () async {
                  setState(() => _isButtonLoading = true);
                  await Future.delayed(const Duration(milliseconds: 800));
                  // Navigate to OrderPage (Passing size information if required by OrderPage)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ConfirmOrderPage(
                        name: widget.name,
                        price: _calculatedPrice,
                        imgUrl: widget.imgUrl,
                        isIce: false, // Placeholder, as it's a food item now
                      ),
                    ),
                  );
                  setState(() => _isButtonLoading = false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBrown, // Using primaryBrown for the second button
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 5,
                ),
                child: isDisabled && _isButtonLoading ?
                const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) :
                Text('Buy Now', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
          style: IconButton.styleFrom(backgroundColor: Colors.black.withOpacity(0.4)),
        ),
        title: const Text(''),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 28),
            color: _isFavorite ? Colors.red[700] : Colors.white,
            onPressed: _showFavoriteDialog,
            style: IconButton.styleFrom(backgroundColor: Colors.black.withOpacity(0.4)),
          ),
          const SizedBox(width: 10),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          SingleChildScrollView(
            // Padding to ensure the content scrolls clear of the bottom bar
            padding: const EdgeInsets.only(bottom: 120), // Increased bottom padding for the lifted bottom bar
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Hero Image Area (Modified for Burger Image) ---
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ZoomableImageScreen(imgUrl: widget.imgUrl, heroTag: widget.heroTag)));
                  },
                  child: Hero(
                    tag: widget.heroTag,
                    child: Container(
                      height: 350,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 10))],
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(widget.imgUrl),
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          onError: (e, s) => const Icon(Icons.fastfood_rounded, size: 80),
                        ),
                      ),
                    ),
                  ),
                ),

                // --- Details Section ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and Rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              widget.name,
                              style: GoogleFonts.poppins(fontSize: 30, fontWeight: FontWeight.w800, color: _primaryBrown),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _accentOrange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.star_rounded, color: Colors.white, size: 20),
                                const SizedBox(width: 4),
                                Text('${widget.rating.toStringAsFixed(1)} (148+)', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16), // Reduced spacing since location is removed

                      // Description
                      Text(
                        widget.description,
                        style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey[700], height: 1.6),
                      ),
                      const SizedBox(height: 24),


                      // --- Choose Size Section ---
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choose size',
                              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryBrown),
                            ),
                            Divider(),
                            _buildSizeSelector(ProductSize.small, 'Small'),
                            _buildSizeSelector(ProductSize.medium, 'Medium'),
                            _buildSizeSelector(ProductSize.large, 'Large'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- Fixed Bottom Action Bar (Price Tag and Buttons) ---
          _buildBottomBar(context),
        ],
      ),
    );
  }
}