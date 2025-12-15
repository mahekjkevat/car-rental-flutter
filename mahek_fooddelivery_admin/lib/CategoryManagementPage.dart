import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:appwrite/appwrite.dart';
import 'package:mahek_fooddelivery_admin/admin_mahek_toast.dart';

class CategoryManagementPage extends StatefulWidget {
  final Client client;

  const CategoryManagementPage({super.key, required this.client});

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> {
  final Color primaryAppColor = const Color(0xFFF96D0A);
  final Color secondaryDarkColor = const Color(0xFF333333);

  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('category')
          .get();

      setState(() {
        _categories = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'] ?? '',
            'type': data['type'] ?? '',
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      if (mounted) {
        // Assuming context.showErrorToast is a custom extension/function
        context.showErrorToast('Failed to load categories');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _convertToType(String name) {
    // Convert name to lowercase and replace spaces with underscores
    return name.toLowerCase().replaceAll(' ', '_');
  }

  Future<void> _addCategory(String categoryName) async {
    if (categoryName.isEmpty) {
      context.showWarningToast('Please enter category name');
      return;
    }

    try {
      final categoryType = _convertToType(categoryName);

      // Check if category already exists
      final existingCategory = await FirebaseFirestore.instance
          .collection('category')
          .where('type', isEqualTo: categoryType)
          .get();

      if (existingCategory.docs.isNotEmpty) {
        context.showWarningToast('Category "$categoryName" already exists');
        return;
      }

      final newCategory = {
        'name': categoryName,
        'type': categoryType,
        'status': 'active',
      };

      await FirebaseFirestore.instance.collection('category').add(newCategory);

      if (mounted) {
        context.showSuccessToast('Category "$categoryName" added successfully!');
        _fetchCategories(); // Refresh the list
      }
    } catch (e) {
      debugPrint('Error adding category: $e');
      if (mounted) {
        context.showErrorToast('Failed to add category');
      }
    }
  }

  Future<void> _deleteCategory(String categoryId, String categoryName) async {
    try {
      // Check if any products are using this category
      final productsUsingCategory = await FirebaseFirestore.instance
          .collection('products')
          .where('type', isEqualTo: categoryName)
          .get();

      if (productsUsingCategory.docs.isNotEmpty) {
        context.showWarningToast('Cannot delete category. Some products are using it.');
        return;
      }

      await FirebaseFirestore.instance.collection('category').doc(categoryId).delete();

      if (mounted) {
        context.showSuccessToast('Category deleted successfully!');
        _fetchCategories(); // Refresh the list
      }
    } catch (e) {
      debugPrint('Error deleting category: $e');
      if (mounted) {
        context.showErrorToast('Failed to delete category');
      }
    }
  }

  void _showAddCategoryDialog() {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add New Category',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: secondaryDarkColor,
          ),
        ),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Category Name',
            hintText: 'e.g., Tea, Milk Shake, Coffee',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _addCategory(nameController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryAppColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Add', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(int index, Map<String, dynamic> category) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: primaryAppColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.category,
            color: primaryAppColor,
            size: 24,
          ),
        ),
        title: Text(
          category['name'],
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: secondaryDarkColor,
          ),
        ),
        subtitle: Text(
          'Type: ${category['type']}',
          style: GoogleFonts.poppins(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primaryAppColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${index + 1}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: primaryAppColor,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red.shade400),
              onPressed: () => _showDeleteConfirmation(category['id'], category['name']),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String categoryId, String categoryName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Category',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "$categoryName"?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCategory(categoryId, categoryName);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      // START of updated AppBar
      appBar: AppBar(
        title: Text(
          'Manage Categories',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 20, // Slightly larger for prominence
            color: secondaryDarkColor,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: secondaryDarkColor),
        // Example action button using the primaryAppColor
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: primaryAppColor),
            onPressed: () {
              // Action for a search button, replace with your desired functionality
            },
          ),
          const SizedBox(width: 8), // Added spacing
        ],
      ),
      // END of updated AppBar
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF96D0A))) // Added color
          : _categories.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Categories Found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add your first category',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          return _buildCategoryCard(index, _categories[index]);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        backgroundColor: primaryAppColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
