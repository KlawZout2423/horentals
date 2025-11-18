import 'package:graphql_flutter/graphql_flutter.dart';
import '../models/property_model.dart';

class PropertyService {
  final GraphQLClient client;

  PropertyService({required this.client});

  // ========== PROPERTY QUERIES ==========

  // Get all properties (for regular users - filtered by availability)
  Future<List<Property>> getProperties({String? type, double? minPrice, double? maxPrice, String? location}) async {
    const String query = '''
      query GetProperties {
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
          company {
            id
            name
            logoUrl
            contact
            isOwnCompany
          }
          owner {
            id
            name
            email
            role
            phone
          }
        }
      }
    ''';

    try {
      final result = await client.query(QueryOptions(
        document: gql(query),
        fetchPolicy: FetchPolicy.cacheFirst, // Use cache for better performance
      ));

      if (result.hasException) {
        throw Exception('Failed to fetch properties: ${result.exception}');
      }

      final List<dynamic> propertiesData = result.data?['properties'] ?? [];
      List<Property> properties = propertiesData.map((json) => Property.fromJson(json)).toList();

      // Filter for regular users - only show available properties
      properties = properties.where((property) => property.isAvailable).toList();

      // Apply additional filters
      if (type != null && type != 'All') {
        properties = properties.where((property) => property.type == type).toList();
      }

      if (minPrice != null) {
        properties = properties.where((property) => property.price >= minPrice).toList();
      }

      if (maxPrice != null) {
        properties = properties.where((property) => property.price <= maxPrice).toList();
      }

      if (location != null && location.isNotEmpty) {
        properties = properties.where((property) =>
            property.location.toLowerCase().contains(location.toLowerCase())
        ).toList();
      }

      return properties;
    } catch (e) {
      throw Exception('Property service error: $e');
    }
  }

  // Get single property by ID
  Future<Property> getPropertyById(int id) async {
    const String query = '''
      query GetProperty(\$id: Int!) {
        property(id: \$id) {
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
          company {
            id
            name
            logoUrl
            contact
            isOwnCompany
          }
          owner {
            id
            name
            email
            role
            phone
          }
        }
      }
    ''';

    try {
      final result = await client.query(QueryOptions(
        document: gql(query),
        variables: {'id': id},
      ));

      if (result.hasException) {
        throw Exception('Failed to fetch property: ${result.exception}');
      }

      if (result.data?['property'] == null) {
        throw Exception('Property not found');
      }

      return Property.fromJson(result.data?['property']);
    } catch (e) {
      throw Exception('Get property error: $e');
    }
  }

  // Search properties
  Future<List<Property>> searchProperties(String query) async {
    final allProperties = await getProperties();

    return allProperties.where((property) {
      return property.title.toLowerCase().contains(query.toLowerCase()) ||
          property.location.toLowerCase().contains(query.toLowerCase()) ||
          property.description?.toLowerCase().contains(query.toLowerCase()) == true;
    }).toList();
  }

  // Get properties by type
  Future<List<Property>> getPropertiesByType(String type) async {
    return await getProperties(type: type);
  }

  // Get featured properties (high rated or recently added)
  Future<List<Property>> getFeaturedProperties() async {
    final properties = await getProperties();

    // Sort by rating (highest first) and take top 6
    properties.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));

    return properties.take(6).toList();
  }

  // Get similar properties (same type or location)
  Future<List<Property>> getSimilarProperties(Property property, {int limit = 4}) async {
    final allProperties = await getProperties();

    // Filter out the current property
    final similar = allProperties.where((p) => p.id != property.id).toList();

    // Prioritize same type, then same location
    similar.sort((a, b) {
      int aScore = 0;
      int bScore = 0;

      if (a.type == property.type) aScore += 2;
      if (a.location == property.location) aScore += 1;

      if (b.type == property.type) bScore += 2;
      if (b.location == property.location) bScore += 1;

      return bScore.compareTo(aScore);
    });

    return similar.take(limit).toList();
  }

  // ========== PROPERTY MUTATIONS ==========

  // Create property (for partners/regular users)
  Future<Property> createProperty(Property property) async {
    const String mutation = '''
      mutation AddProperty(\$input: PropertyInput!) {
        addProperty(input: \$input) {
          id
          title
          location
          price
          type
          status
          images
          bedrooms
          bathrooms
          rating
          company {
            id
            name
          }
          owner {
            id
            name
          }
        }
      }
    ''';

    try {
      final result = await client.mutate(MutationOptions(
        document: gql(mutation),
        variables: {'input': property.toInputJson()},
      ));

      if (result.hasException) {
        throw Exception('Failed to create property: ${result.exception}');
      }

      return Property.fromJson(result.data?['addProperty']);
    } catch (e) {
      throw Exception('Create property error: $e');
    }
  }

  // Update property (for owners)
  Future<Property> updateProperty(int id, Map<String, dynamic> updates) async {
    const String mutation = '''
      mutation UpdateProperty(\$id: Int!, \$input: PropertyInput!) {
        updateProperty(id: \$id, input: \$input) {
          id
          title
          location
          price
          type
          status
          images
          bedrooms
          bathrooms
          rating
        }
      }
    ''';

    try {
      final result = await client.mutate(MutationOptions(
        document: gql(mutation),
        variables: {'id': id, 'input': updates},
      ));

      if (result.hasException) {
        throw Exception('Failed to update property: ${result.exception}');
      }

      return Property.fromJson(result.data?['updateProperty']);
    } catch (e) {
      throw Exception('Update property error: $e');
    }
  }

  // ========== FAVORITES & USER-SPECIFIC ==========

  // Get user's properties (if they are owner)
  Future<List<Property>> getUserProperties() async {
    // This would require a backend query like "myProperties"
    // For now, we'll use the general properties query
    final allProperties = await getProperties();

    // In a real app, you'd filter by current user ID
    // For demo, return all properties
    return allProperties;
  }

  // Toggle favorite status (would need backend support)
  Future<bool> toggleFavorite(int propertyId) async {
    // This is a placeholder - you'd need a mutation like:
    // mutation ToggleFavorite($propertyId: Int!) { toggleFavorite(propertyId: $propertyId) }

    await Future.delayed(Duration(milliseconds: 500)); // Simulate API call
    return true;
  }

  // Get favorite properties (would need backend support)
  Future<List<Property>> getFavoriteProperties() async {
    // Placeholder - in real app, query user's favorites
    final allProperties = await getProperties();
    return allProperties.take(3).toList(); // Demo: return first 3
  }

  // ========== FILTERING & SORTING ==========

  // Get available property types
  Future<List<String>> getPropertyTypes() async {
    final properties = await getProperties();
    final types = properties.map((p) => p.type).whereType<String>().toSet();
    return types.toList();
  }

  // Get available locations
  Future<List<String>> getLocations() async {
    final properties = await getProperties();
    final locations = properties.map((p) => p.location).toSet();
    return locations.toList();
  }

  // Filter properties with multiple criteria
  Future<List<Property>> filterProperties({
    String? type,
    double? minPrice,
    double? maxPrice,
    String? location,
    int? minBedrooms,
    int? minBathrooms,
    double? minRating,
  }) async {
    var properties = await getProperties();

    if (type != null && type != 'All') {
      properties = properties.where((p) => p.type == type).toList();
    }

    if (minPrice != null) {
      properties = properties.where((p) => p.price >= minPrice).toList();
    }

    if (maxPrice != null) {
      properties = properties.where((p) => p.price <= maxPrice).toList();
    }

    if (location != null && location.isNotEmpty) {
      properties = properties.where((p) =>
          p.location.toLowerCase().contains(location.toLowerCase())
      ).toList();
    }

    if (minBedrooms != null) {
      properties = properties.where((p) => (p.bedrooms ?? 0) >= minBedrooms).toList();
    }

    if (minBathrooms != null) {
      properties = properties.where((p) => (p.bathrooms ?? 0) >= minBathrooms).toList();
    }

    if (minRating != null) {
      properties = properties.where((p) => (p.rating ?? 0) >= minRating).toList();
    }

    return properties;
  }

  // Sort properties
  List<Property> sortProperties(List<Property> properties, String sortBy) {
    switch (sortBy) {
      case 'price_low':
        properties.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        properties.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'rating':
        properties.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        break;
      case 'newest':
        properties.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
        break;
      default: // relevance or default
        break;
    }
    return properties;
  }
}