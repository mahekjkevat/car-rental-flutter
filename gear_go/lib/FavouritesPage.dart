import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gear_go/car_data_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:animate_do/animate_do.dart';
import 'view_car_page.dart';

class FavouritesPage extends StatefulWidget {
  const FavouritesPage({super.key});

  @override
  State<FavouritesPage> createState() => _FavouritesPageState();
}

class _FavouritesPageState extends State<FavouritesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<CarDataModel> _favoriteCars = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFavoriteCars();
  }

  Future<void> _fetchFavoriteCars() async {
    setState(() {
      _isLoading = true;
    });
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        final favoritesSnapshot = await _firestore
            .collection('Users')
            .doc(user.uid)
            .collection('Favourites')
            .get();

        if (favoritesSnapshot.docs.isNotEmpty) {
          List<String> favoriteCarDocumentIds = favoritesSnapshot.docs
              .map((doc) => doc['carDocumentId'] as String)
              .toList();

          if (favoriteCarDocumentIds.isNotEmpty) {
            final carsSnapshot = await _firestore
                .collection('CarData')
                .where(FieldPath.documentId, whereIn: favoriteCarDocumentIds)
                .get();

            _favoriteCars = carsSnapshot.docs.map((doc) {
              return CarDataModel.fromJson(
                  doc.data() as Map<String, dynamic>, doc.id);
            }).toList();
          }
        }
      } catch (e) {
        print("Error fetching favorite cars: $e");
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: FadeInDown(
          duration: Duration(milliseconds: 500),
          child: Text(
            'My Favorites',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.blue[900],
              letterSpacing: 0.5,
            ),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.blue[800]),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.blue[50]!],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoadingAnimationWidget.fallingDot(
              color: Colors.blue[800]!,
              size: 80,
            ),
            SizedBox(height: 20),
            FadeIn(
              duration: Duration(milliseconds: 600),
              child: Text(
                'Loading your favorites...',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      )
          : _favoriteCars.isEmpty
          ? FadeIn(
        duration: Duration(milliseconds: 800),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElasticIn(
                  duration: Duration(milliseconds: 1000),
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue[100]!,
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.favorite_border_rounded,
                      size: 70,
                      color: Colors.blue[300],
                    ),
                  ),
                ),
                SizedBox(height: 30),
                Text(
                  'No favorites yet',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue[900],
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Start adding cars to your favorites\nand they will appear here',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                        horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: Text(
                    'Explore Cars',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      )
          : Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.grey[50]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Header with count
            FadeInDown(
              duration: Duration(milliseconds: 500),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue[100]!,
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Favorite Cars',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.blue[900],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue[800],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_favoriteCars.length} items',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 8),
            // Cars List
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: _favoriteCars.length,
                itemBuilder: (context, index) {
                  final car = _favoriteCars[index];
                  return SlideInLeft(
                    duration: Duration(milliseconds: 400 + (index * 100)),
                    child: Container(
                      margin: EdgeInsets.only(bottom: 16),
                      child: Stack(
                        children: [
                          // Main Card
                          Card(
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            shadowColor: Colors.blue[100],
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white,
                                    Colors.blue[50]!,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    // Car Image
                                    Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                          BorderRadius.circular(15),
                                          child: Container(
                                            height: 160,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.blue[100]!,
                                                  Colors.blue[200]!,
                                                ],
                                              ),
                                            ),
                                            child: Image.network(
                                              car.carImage1,
                                              height: 160,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context,
                                                  child,
                                                  loadingProgress) {
                                                if (loadingProgress ==
                                                    null) return child;
                                                return Center(
                                                  child:
                                                  CircularProgressIndicator(
                                                    value: loadingProgress
                                                        .cumulativeBytesLoaded /
                                                        (loadingProgress
                                                            .expectedTotalBytes ??
                                                            1),
                                                    color: Colors.blue[800],
                                                  ),
                                                );
                                              },
                                              errorBuilder: (context,
                                                  error, stackTrace) {
                                                return Center(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .center,
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .error_outline,
                                                        color:
                                                        Colors.red,
                                                        size: 40,
                                                      ),
                                                      SizedBox(height: 8),
                                                      Text(
                                                        'Failed to load image',
                                                        style:
                                                        GoogleFonts
                                                            .poppins(
                                                          color:
                                                          Colors.grey,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        // Favorite Icon
                                        Positioned(
                                          top: 10,
                                          right: 10,
                                          child: Container(
                                            padding: EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.red
                                                  .withOpacity(0.9),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.favorite_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                    // Car Name
                                    Text(
                                      car.carName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.blue[900],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 8),
                                    // Price and Action Row
                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment
                                          .spaceBetween,
                                      children: [
                                        // Price
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[800],
                                            borderRadius:
                                            BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '₹${car.basicPrice}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight:
                                              FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        // View and Remove buttons
                                        Row(
                                          children: [
                                            // View Button
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.green[500],
                                                borderRadius:
                                                BorderRadius
                                                    .circular(8),
                                              ),
                                              child: IconButton(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          ViewCarPage(
                                                              carData:
                                                              car),
                                                    ),
                                                  );
                                                },
                                                icon: Icon(
                                                  Icons
                                                      .visibility_rounded,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                                tooltip: 'View Car',
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            // Remove Button
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.red[400],
                                                borderRadius:
                                                BorderRadius
                                                    .circular(8),
                                              ),
                                              child: IconButton(
                                                onPressed: () {
                                                  _showRemoveConfirmationDialog(
                                                      context,
                                                      car.documentId);
                                                },
                                                icon: Icon(
                                                  Icons
                                                      .delete_outline_rounded,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                                tooltip: 'Remove',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRemoveConfirmationDialog(
      BuildContext context, String carDocumentId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return BounceInDown(
          duration: Duration(milliseconds: 500),
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            backgroundColor: Colors.white,
            elevation: 20,
            title: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.favorite_border, color: Colors.red[400]),
                  SizedBox(width: 10),
                  Text(
                    'Remove Favorite?',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(
                    'This car will be removed from your favorites list.',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'Remove',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                onPressed: () {
                  _removeFromFavorites(carDocumentId);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _removeFromFavorites(String carDocumentId) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore
            .collection('Users')
            .doc(user.uid)
            .collection('Favourites')
            .where('carDocumentId', isEqualTo: carDocumentId)
            .get()
            .then((snapshot) {
          for (DocumentSnapshot doc in snapshot.docs) {
            doc.reference.delete();
          }
        });
        _fetchFavoriteCars();
        Fluttertoast.showToast(
          msg: "Removed from Favorites!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red[400],
          textColor: Colors.white,
          fontSize: 14.0,
        );
      } catch (e) {
        print("Error removing from favorites: $e");
        Fluttertoast.showToast(
          msg: "Failed to remove from favorites. Please try again.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }
}