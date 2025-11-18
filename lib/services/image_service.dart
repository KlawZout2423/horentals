// lib/services/image_service.dart
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'graphql_service.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  // Pick multiple images from gallery only
  static Future<List<File>> pickImages({int maxImages = 10}) async {
    try {
      final List<XFile>? selectedImages = await _picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (selectedImages == null || selectedImages.isEmpty) {
        return [];
      }

      final List<File> files = [];
      for (int i = 0; i < selectedImages.length && i < maxImages; i++) {
        files.add(File(selectedImages[i].path));
      }

      return files;
    } catch (e) {
      print('Error picking images: $e');
      throw Exception('Failed to pick images: $e');
    }
  }

  // Upload images and return URLs
  static Future<List<String>> uploadImages(List<File> images) async {
    try {
      final userId = await GraphQLService.getCurrentUserId();
      final uploadedUrls = <String>[];

      // Use uploadMultipleImages
      final results = await GraphQLService.uploadMultipleImages(
        files: images,
        userId: userId,
        category: 'property',
      );

      for (final result in results) {
        final url = result['url'];
        if (url != null && url.isNotEmpty) {
          uploadedUrls.add(url.toString());
        }
      }

      return uploadedUrls;
    } catch (e) {
      print('Error uploading images: $e');
      // Fallback: Return placeholder URLs for development
      return List.generate(images.length, (index) => 'https://via.placeholder.com/400x300?text=Property+${index + 1}');
    }
  }
}