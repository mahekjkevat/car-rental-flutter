import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../car_details_page.dart';

class AllCarsPage extends StatefulWidget {
  const AllCarsPage({super.key});

  @override
  _AllCarsPageState createState() => _AllCarsPageState();
}

class _AllCarsPageState extends State<AllCarsPage> {
  String? _selectedBrand;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1A1A), Color(0xFF2D2D2D)],
            ),
          ),
        ),
        title: Text(
          'All Cars',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        elevation: 4,
        shadowColor: Colors.yellow.withOpacity(0.3),
      ),
      body: Stack(
        children: [
          // Background image with 15% opacity
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/images/car.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(),
              ),
            ),
          ),
          // Foreground content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    cursorColor: Colors.yellow,
                    decoration: InputDecoration(
                      hintText: 'Search Cars...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      prefixIcon: const Icon(Icons.search, color: Colors.white),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  // Filter by Brand
                  Text(
                    'Filter by Brand',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('CarData')
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.hasError) {
                        return const SizedBox.shrink();
                      }
                      final brands = [
                        'All',
                        ...snapshot.data!.docs
                            .map(
                              (doc) => doc['car_brand'] as String? ?? 'Unknown',
                            )
                            .where((brand) => brand.isNotEmpty)
                            .toSet(),
                      ];
                      return SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: brands.length,
                          itemBuilder: (context, index) {
                            final brand = brands[index];
                            final isSelected =
                                _selectedBrand == brand ||
                                (brand == 'All' && _selectedBrand == null);
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(
                                  brand,
                                  style: GoogleFonts.poppins(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedBrand =
                                          brand == 'All' ? null : brand;
                                    });
                                  }
                                },
                                selectedColor: Colors.yellow,
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color:
                                        isSelected
                                            ? Colors.yellow
                                            : Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                                elevation: isSelected ? 4 : 1,
                                pressElevation: 8,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  // Cars List with filtering and "No cars found" message
                  StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('CarData')
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.yellow,
                            ),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: GoogleFonts.poppins(
                              color: Colors.redAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            'No cars found',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[400],
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        );
                      }

                      // Filter data based on search and brand
                      final cars =
                          snapshot.data!.docs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final carBrand =
                                data['car_brand'] as String? ?? 'Unknown';
                            final carName = data['car_name'] as String? ?? '';
                            final matchesBrand =
                                _selectedBrand == null ||
                                carBrand == _selectedBrand;
                            final matchesSearch =
                                _searchQuery.isEmpty ||
                                carName.toLowerCase().contains(_searchQuery);
                            return matchesBrand && matchesSearch;
                          }).toList();

                      // Show message if no cars after filtering
                      if (cars.isEmpty) {
                        return Center(
                          child: Text(
                            'No cars found',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cars.length,
                        itemBuilder: (context, index) {
                          final carData =
                              cars[index].data() as Map<String, dynamic>;
                          final carName =
                              carData['car_name'] as String? ?? 'Unknown';
                          final carBrand =
                              carData['car_brand'] as String? ?? 'Unknown';
                          final carImage1 = carData['car_image1'] as String?;

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          CarDetailsPage(carData: carData),
                                ),
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacity(0.1),
                                    Colors.white.withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.yellow.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Car Image on Left
                                  Container(
                                    width: 100,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.yellow.withOpacity(0.5),
                                        width: 1,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child:
                                          carImage1 != null &&
                                                  carImage1.isNotEmpty
                                              ? CachedNetworkImage(
                                                imageUrl: carImage1,
                                                width: 100,
                                                height: 80,
                                                fit: BoxFit.cover,
                                                placeholder:
                                                    (context, url) => Container(
                                                      color: Colors.grey[900],
                                                      child:
                                                          _buildShimmerPlaceholder(),
                                                    ),
                                                errorWidget:
                                                    (
                                                      context,
                                                      url,
                                                      error,
                                                    ) => Container(
                                                      color: Colors.grey[900],
                                                      child: Center(
                                                        child: Icon(
                                                          Icons.broken_image,
                                                          color:
                                                              Colors.grey[400],
                                                          size: 40,
                                                        ),
                                                      ),
                                                    ),
                                              )
                                              : Container(
                                                color: Colors.grey[900],
                                                child: Center(
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    color: Colors.grey[400],
                                                    size: 40,
                                                  ),
                                                ),
                                              ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Car Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          carName,
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          carBrand,
                                          style: GoogleFonts.poppins(
                                            color: Colors.grey[300],
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Tap to view details',
                                          style: GoogleFonts.poppins(
                                            color: Colors.yellow,
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Shimmer effect for image loading
  Widget _buildShimmerPlaceholder() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Colors.grey[800]!, Colors.grey[700]!, Colors.grey[800]!],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 1500),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.transparent,
                Colors.white.withOpacity(0.3),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          onEnd: () {
            setState(() {}); // Trigger animation loop
          },
        ),
      ],
    );
  }
}
