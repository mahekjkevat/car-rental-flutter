import 'package:flutter/material.dart';
import 'package:gear_go/view_car_brand_category.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'brand_model.dart'; // Import your BrandModel

class ViewALLCarBrandCategory extends StatelessWidget {
  final String title;
  final String brandType;

  const ViewALLCarBrandCategory({
    Key? key,
    required this.title,
    required this.brandType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black, // Changed to black
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue[100],
        elevation: 4,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[200]!, Colors.blue[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[50]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('Brands').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error fetching brands: ${snapshot.error}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.red[700],
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: LoadingAnimationWidget.dotsTriangle(
                  color: Colors.black, // Changed to black
                  size: 70,
                ),
              );
            }

            if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.car_rental,
                        size: 80,
                        color: Colors.black, // Changed to black
                      ),
                      SizedBox(height: 20),
                      Text(
                        'No brands available at the moment.',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.grey[800], // Darker grey
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 20.0,
                mainAxisSpacing: 20.0,
                childAspectRatio: 0.9,
              ),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final brand = BrandModel.fromFirestore(
                  snapshot.data!.docs[index],
                );

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewCarBrandCategory(
                          title: brand.name,
                          brandType: brand.type,
                          brand: brand,
                        ),
                      ),
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    transform: Matrix4.identity()
                      ..scale(1.0)
                      ..translate(0.0),
                    transformAlignment: Alignment.center,
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white, Colors.grey[50]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12, // Changed to black shadow
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Brand Logo Container - Black Theme
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black, // Black background
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26, // Black shadow
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: brand.imageUrl.isNotEmpty
                                      ? Image.network(
                                    brand.imageUrl,
                                    fit: BoxFit.contain,
                                    width: 90,
                                    height: 90,
                                    color: Colors.white, // Force white color
                                    colorBlendMode: BlendMode.srcIn,
                                    loadingBuilder: (
                                        context,
                                        child,
                                        loadingProgress,
                                        ) {
                                      if (loadingProgress == null)
                                        return child;
                                      return Center(
                                        child: LoadingAnimationWidget
                                            .dotsTriangle(
                                          color: Colors.white, // White loading
                                          size: 30,
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error,
                                        stackTrace) =>
                                        Center(
                                          child: Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.black,
                                            ),
                                            child: Icon(
                                              Icons.car_rental,
                                              size: 40,
                                              color: Colors.white, // White icon
                                            ),
                                          ),
                                        ),
                                  )
                                      : Center(
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.black,
                                      ),
                                      child: Icon(
                                        Icons.car_rental,
                                        size: 40,
                                        color: Colors.white, // White icon
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              // Brand Name - Bold and Black
                              Text(
                                brand.name,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold, // Made bold
                                  color: Colors.black, // Changed to black
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}