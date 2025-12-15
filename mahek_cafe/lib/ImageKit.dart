import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ImageKitUploader extends StatefulWidget {
  @override
  _ImageKitUploaderState createState() => _ImageKitUploaderState();
}

class _ImageKitUploaderState extends State<ImageKitUploader> {
  List<String> imageUrls = [];
  bool isUploading = false;

  final String privateApiKey = 'private_u6KRAwruwE6w8xR63Vl7enrhpzk=';
  final String uploadEndpoint = 'https://upload.imagekit.io/api/v1/files/upload';

  Future<void> uploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    setState(() => isUploading = true);

    try {
      final file = File(pickedFile.path);
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse(uploadEndpoint),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$privateApiKey:'))}',
        },
        body: {
          'file': base64Image,
          'fileName': 'flutter_upload_${DateTime.now().millisecondsSinceEpoch}.jpg',
          'useUniqueFileName': 'true',
          'folder': '/products', // 👈 This stores the image in the "products" folder
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          imageUrls.add(data['url']);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Upload successful')),
        );
      } else {
        print('❌ Upload failed: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('❌ Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image')),
      );
    } finally {
      setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ImageKit Upload & View')),
      body: Column(
        children: [
          ElevatedButton.icon(
            onPressed: isUploading ? null : uploadImage,
            icon: Icon(Icons.upload),
            label: Text(isUploading ? 'Uploading...' : 'Upload Image'),
          ),
          Expanded(
            child: imageUrls.isEmpty
                ? Center(child: Text('No images uploaded yet'))
                : ListView.builder(
              itemCount: imageUrls.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.network(imageUrls[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
