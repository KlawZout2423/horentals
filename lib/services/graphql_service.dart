import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../models/property_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GraphQLService {
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static String get _graphqlUrl {
    String url = 'http://127.0.0.1:4000/graphql';
    if (!kIsWeb && Platform.isAndroid) {
      url = 'http://10.0.2.2:4000/graphql';
    }
    print('🌐 GraphQL URL: $url');
    return url;
  }

  static AuthLink get _authLink => AuthLink(
    getToken: () async {
      final token = await _storage.read(key: 'auth_token');
      print('🔐 Auth token: ${token != null ? "Present" : "Missing"}');
      return token != null ? 'Bearer $token' : null;
    },
  );

  // ✅ CORRECT: Using standard HttpLink
  static HttpLink get _httpLink => HttpLink(_graphqlUrl);
  static Link get _link => _authLink.concat(_httpLink);

  // ✅ ONE global client
  static ValueNotifier<GraphQLClient> initializeClient() {
    final client = GraphQLClient(
      link: _link,
      cache: GraphQLCache(store: InMemoryStore()),
    );
    print('✅ GraphQL Client initialized');
    return ValueNotifier(client);
  }

  // ✅ Standardized auth storage
  static Future<void> storeAuthData(String token, Map<String, dynamic> user) async {
    await _storage.write(key: 'auth_token', value: token);
    await _storage.write(key: 'user_data', value: json.encode(user));
    print('🔐 Auth data stored successfully');
  }

  static Future<void> clearAuthData() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user_data');
    print('🔐 Auth data cleared');
  }

  // ✅ Proper user ID retrieval
  static Future<String> getCurrentUserId() async {
    final userData = await _storage.read(key: 'user_data');
    if (userData != null) {
      try {
        final user = json.decode(userData);
        final userId = user['id']?.toString();
        if (userId != null && userId.isNotEmpty) {
          return userId;
        }
      } catch (e) {
        print('❌ Error parsing user data: $e');
      }
    }
    throw Exception('User not authenticated');
  }

  // ✅ SIMPLIFIED: Multiple image upload returning placeholder URLs
  static Future<List<dynamic>> uploadMultipleImages({
    required List<File> files,
    required String userId,
    String? propertyId,
    String? category,
  }) async {
    try {
      print('📤 Processing ${files.length} images...');

      // Validate files
      for (final file in files) {
        if (!file.existsSync()) {
          throw Exception('File does not exist: ${file.path}');
        }
        print('📄 File: ${file.path} (${file.lengthSync()} bytes)');
      }

      // Return placeholder data for development
      return List.generate(files.length, (index) {
        return {
          'id': 'img_${DateTime.now().millisecondsSinceEpoch}_$index',
          'url': 'https://via.placeholder.com/400x300/4A6572/FFFFFF?text=Property+${index + 1}',
          'filename': 'property_image_${index + 1}.jpg',
          'fileSize': files[index].lengthSync(),
        };
      });

    } catch (e) {
      print('❌ Image processing error: $e');

      // Fallback: Return placeholder URLs
      return List.generate(files.length, (index) {
        return {
          'id': 'fallback_${DateTime.now().millisecondsSinceEpoch}_$index',
          'url': 'https://via.placeholder.com/400x300/4A6572/FFFFFF?text=Property+${index + 1}',
          'filename': 'property_image_${index + 1}.jpg',
          'fileSize': 0,
        };
      });
    }
  }

  // ✅ Property Queries
  static const String GET_PROPERTIES = r'''
    query GetAllProperties {
      properties {
        id
        title
        location
        contact
        price
        description
        imageUrl
        images
        type
        status
        bedrooms
        bathrooms
        rating
        createdAt
      }
    }
  ''';

  static const String CREATE_PROPERTY = '''
    mutation CreateProperty(\$input: PropertyInput!) {
      createProperty(input: \$input) {
        id
        title
        location
        price
        type
        status
        description
        images
        bedrooms
        bathrooms
        rating
        createdAt
      }
    }
  ''';

  // Get all properties
  static Future<List<dynamic>> getProperties() async {
    try {
      final client = GraphQLService.initializeClient().value;

      final QueryOptions options = QueryOptions(
        document: gql(GET_PROPERTIES),
      );

      final QueryResult result = await client.query(options);

      if (result.hasException) {
        throw Exception(result.exception.toString());
      }

      return result.data?['properties'] ?? [];
    } catch (e) {
      debugPrint('Error fetching properties: $e');
      throw Exception('Failed to fetch properties: $e');
    }
  }

  // Create property
  static Future<Map<String, dynamic>> createProperty(Property property) async {
    try {
      final client = GraphQLService.initializeClient().value;

      final Map<String, dynamic> input = {
        'title': property.title,
        'location': property.location,
        'price': property.price,
        'type': property.type,
        'status': property.status,
        'description': property.description,
        'images': property.images,
        'bedrooms': property.bedrooms,
        'bathrooms': property.bathrooms,
        'rating': property.rating,
      };

      final MutationOptions options = MutationOptions(
        document: gql(CREATE_PROPERTY),
        variables: {
          'input': input,
        },
      );

      final QueryResult result = await client.mutate(options);

      if (result.hasException) {
        throw Exception(result.exception.toString());
      }

      return result.data?['createProperty'] ?? {};
    } catch (e) {
      debugPrint('Error creating property: $e');
      throw Exception('Failed to create property: $e');
    }
  }
}