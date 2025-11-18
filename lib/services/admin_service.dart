import 'package:graphql_flutter/graphql_flutter.dart';
import '../models/property_model.dart';
import 'graphql_service.dart';
import 'property_service.dart';

class AdminService {
  final GraphQLClient client;

  AdminService({required this.client});

  // ✅ Factory method for easy instantiation
  factory AdminService.create() {
    return AdminService(client: GraphQLService.initializeClient().value);
  }

  // ✅ Static instance getter
  static AdminService get instance {
    return AdminService(client: GraphQLService.initializeClient().value);
  }

  // ========== PROPERTY MANAGEMENT ==========

  // Get all properties (for admin - includes all statuses)
  Future<List<Property>> getAllProperties() async {
    const String query = '''
      query GetAllProperties {
        getProperties {
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
        fetchPolicy: FetchPolicy.networkOnly,
      ));

      if (result.hasException) {
        throw Exception('Failed to fetch properties: ${result.exception}');
      }

      final List<dynamic> propertiesData = result.data?['getProperties'] ?? [];
      return propertiesData.map((json) => Property.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Admin service error: $e');
    }
  }

  // ✅ Fixed fallback method
  Future<List<Property>> getProperties() async {
    try {
      return await getAllProperties();
    } catch (e) {
      print('Admin properties fetch failed: $e');
      // Fallback to regular properties service
      final PropertyService propertyService = PropertyService(
        client: client, // Use same client instead of creating new one
      );
      return await propertyService.getProperties();
    }
  }

  // ✅ Fixed create property mutation
  Future<Property> createProperty(Property property) async {
    const String mutation = '''
      mutation CreateProperty(\$input: PropertyInput!) {
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

  // Update property
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

  // Delete property
  Future<bool> deleteProperty(int id) async {
    const String mutation = '''
      mutation DeleteProperty(\$id: Int!) {
        deleteProperty(id: \$id) {
          id
        }
      }
    ''';

    try {
      final result = await client.mutate(MutationOptions(
        document: gql(mutation),
        variables: {'id': id},
      ));

      if (result.hasException) {
        throw Exception('Failed to delete property: ${result.exception}');
      }

      return result.data?['deleteProperty'] != null;
    } catch (e) {
      throw Exception('Delete property error: $e');
    }
  }

  // ========== USER MANAGEMENT ==========

  // Get all users (for admin)
  Future<List<User>> getAllUsers() async {
    const String query = '''
      query GetAllUsers {
        users {
          id
          name
          email
          role
          phone
        }
      }
    ''';

    try {
      final result = await client.query(QueryOptions(
        document: gql(query),
      ));

      if (result.hasException) {
        throw Exception('Failed to fetch users: ${result.exception}');
      }

      final List<dynamic> usersData = result.data?['users'] ?? [];
      return usersData.map((json) => User.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Get users error: $e');
    }
  }

  // Create partner account
  Future<Map<String, dynamic>> createPartner({
    required String userName,
    required String email,
    required String password,
    required String contact,
    required String momoAccount,
    String? phone,
    int? companyId,
    String? companyName,
    String? logoUrl,
  }) async {
    const String mutation = '''
      mutation CreatePartner(\$input: PartnerInput!) {
        createPartner(input: \$input) {
          token
          user {
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
      final result = await client.mutate(MutationOptions(
        document: gql(mutation),
        variables: {
          'input': {
            'userName': userName,
            'email': email,
            'password': password,
            'phone': phone,
            'companyId': companyId,
            'companyName': companyName,
            'logoUrl': logoUrl,
            'contact': contact,
            'momoAccount': momoAccount,
          }
        },
      ));

      if (result.hasException) {
        throw Exception('Failed to create partner: ${result.exception}');
      }

      return result.data?['createPartner'] ?? {};
    } catch (e) {
      throw Exception('Create partner error: $e');
    }
  }

  // ========== COMPANY MANAGEMENT ==========

  // Get all companies
  Future<List<Company>> getAllCompanies() async {
    const String query = '''
      query GetAllCompanies {
        companies {
          id
          name
          logoUrl
          contact
          isOwnCompany
        }
      }
    ''';

    try {
      final result = await client.query(QueryOptions(
        document: gql(query),
      ));

      if (result.hasException) {
        throw Exception('Failed to fetch companies: ${result.exception}');
      }

      final List<dynamic> companiesData = result.data?['companies'] ?? [];
      return companiesData.map((json) => Company.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Get companies error: $e');
    }
  }

  // Assign property to company
  Future<Property> assignPropertyToCompany(int propertyId, int companyId) async {
    const String mutation = '''
      mutation UpdatePropertyCompany(\$id: Int!, \$companyId: Int!) {
        updatePropertyCompany(id: \$id, companyId: \$companyId) {
          id
          title
          company {
            id
            name
          }
        }
      }
    ''';

    try {
      final result = await client.mutate(MutationOptions(
        document: gql(mutation),
        variables: {'id': propertyId, 'companyId': companyId},
      ));

      if (result.hasException) {
        throw Exception('Failed to assign property: ${result.exception}');
      }

      return Property.fromJson(result.data?['updatePropertyCompany']);
    } catch (e) {
      throw Exception('Assign property error: $e');
    }
  }

  // ========== ANALYTICS & STATS ==========

  // ✅ Fixed dashboard stats query
  Future<Map<String, dynamic>> getDashboardStats() async {
    const String query = '''
      query GetDashboardStats {
        properties {
          id
          status
          price
        }
        users {
          id
          role
        }
        bookings {
          id
          totalAmount
          status
        }
        companies {
          id
          isOwnCompany
        }
      }
    ''';

    try {
      final result = await client.query(QueryOptions(
        document: gql(query),
      ));

      if (result.hasException) {
        throw Exception('Failed to fetch stats: ${result.exception}');
      }

      final properties = result.data?['properties'] ?? [];
      final users = result.data?['users'] ?? [];
      final bookings = result.data?['bookings'] ?? [];
      final companies = result.data?['companies'] ?? [];

      // Calculate stats
      final totalProperties = properties.length;
      final availableProperties = properties.where((p) => p['status'] == 'available').length;
      final totalUsers = users.length;
      final adminUsers = users.where((u) => u['role'] == 'admin').length;
      final partnerUsers = users.where((u) => u['role'] == 'partner').length;

      final totalRevenue = bookings.fold(0.0, (sum, booking) => sum + (booking['totalAmount'] ?? 0));
      final totalCommission = bookings.fold(0.0, (sum, booking) => sum + (booking['commissionAmount'] ?? 0));

      final ownCompanies = companies.where((c) => c['isOwnCompany'] == true).length;
      final partnerCompanies = companies.where((c) => c['isOwnCompany'] == false).length;

      return {
        'totalProperties': totalProperties,
        'availableProperties': availableProperties,
        'takenProperties': totalProperties - availableProperties,
        'totalUsers': totalUsers,
        'adminUsers': adminUsers,
        'partnerUsers': partnerUsers,
        'totalRevenue': totalRevenue,
        'totalCommission': totalCommission,
        'ownCompanies': ownCompanies,
        'partnerCompanies': partnerCompanies,
      };
    } catch (e) {
      throw Exception('Get dashboard stats error: $e');
    }
  }

  // ========== QUICK ACTIONS ==========

  // Toggle property availability
  Future<Property> togglePropertyAvailability(int propertyId, bool isAvailable) async {
    return await updateProperty(propertyId, {
      'status': isAvailable ? 'available' : 'taken',
    });
  }

  // Update property status
  Future<Property> updatePropertyStatus(int propertyId, String status) async {
    return await updateProperty(propertyId, {
      'status': status,
    });
  }

  // Bulk update properties
  Future<void> bulkUpdateProperties(List<int> propertyIds, Map<String, dynamic> updates) async {
    for (final id in propertyIds) {
      await updateProperty(id, updates);
    }
  }
}