import 'package:graphql_flutter/graphql_flutter.dart';
import 'graphql_service.dart';
import '../utils/logger.dart';


class AuthService {
  final GraphQLClient client;

  // Main constructor
  AuthService({GraphQLClient? client})
      : client = client ?? GraphQLService.initializeClient().value;

  // Factory method for convenience
  factory AuthService.create() {
    return AuthService();
  }

  // Alternative factory method if you need specific client
  factory AuthService.withClient(GraphQLClient client) {
    return AuthService(client: client);
  }

  static const String registerMutation = r'''
    mutation Register($input: RegisterInput!) {
      register(input: $input) {
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

  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String password,
    String? email,
  }) async {
    try {
      AppLogger.info('🔐 Attempting registration for: $name');

      // ✅ ADD TIMEOUT HERE
      final result = await client.mutate(
        MutationOptions(
          document: gql(registerMutation),
          variables: {
            'input': {
              'name': name,
              'phone': phone,
              'password': password,
              'email': email ?? '$phone@horentals.com',
            },
          },
        ),
      ).timeout(
        const Duration(seconds: 15), // ✅ 15-second timeout
        onTimeout: () => throw Exception('Registration timeout - Server not responding'),
      );

      if (result.hasException) {
        AppLogger.error('❌ Registration mutation failed: ${result.exception}');

        // Handle specific GraphQL errors
        if (result.exception?.graphqlErrors != null) {
          for (final error in result.exception!.graphqlErrors) {
            AppLogger.error('   - GraphQL Error: ${error.message}');
            if (error.message.contains('already exists') || error.message.contains('P2002')) {
              throw Exception('Phone number already registered. Please try logging in.');
            }
          }
        }

        throw Exception('Registration failed: ${result.exception}');
      }

      if (result.data == null || result.data!['register'] == null) {
        throw Exception('Registration failed: No data received');
      }

      final registerData = result.data!['register'];

      // Store auth data properly
      if (registerData['token'] != null && registerData['user'] != null) {
        await GraphQLService.storeAuthData(
            registerData['token'],
            registerData['user']
        );
      }

      AppLogger.info('✅ Registration successful');
      return registerData;
    } catch (e) {
      AppLogger.error('💥 Registration error: $e');

      // Handle timeout specifically
      if (e.toString().contains('timeout')) {
        throw Exception('Connection timeout. Please check if your backend server is running.');
      }

      rethrow;
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.info('🔄 Login attempt with email: $email');

      const String loginMutation = r'''
        mutation Login($email: String!, $password: String!) {
          login(email: $email, password: $password) {
            token
            user {
              id
              name
              email
              phone
              role
            }
          }
        }
      ''';

      // ✅ ADD TIMEOUT HERE TOO
      final result = await client.mutate(
        MutationOptions(
          document: gql(loginMutation),
          variables: {
            'email': email,
            'password': password,
          },
        ),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Login timeout - Server not responding'),
      );

      if (result.hasException) {
        AppLogger.error('❌ Login mutation failed: ${result.exception}');

        if (result.exception?.graphqlErrors != null) {
          for (final error in result.exception!.graphqlErrors) {
            AppLogger.error('   - GraphQL Error: ${error.message}');
          }
          // Propagate the first specific GraphQL error message
          throw Exception(result.exception!.graphqlErrors.first.message.replaceAll('Unexpected error.', '').trim());
        }

        throw Exception('Login failed: ${result.exception}');
      }

      if (result.data == null || result.data!['login'] == null) {
        throw Exception('Login failed: Invalid response');
      }

      final loginData = result.data!['login'];

      // Store auth data properly
      if (loginData['token'] != null && loginData['user'] != null) {
        await GraphQLService.storeAuthData(
            loginData['token'],
            loginData['user']
        );
      }

      AppLogger.info('✅ Login successful for user: ${loginData['user']['name']}');
      return loginData;
    } catch (e) {
      AppLogger.error('🚨 Login error: $e');

      if (e.toString().contains('timeout')) {
        throw Exception('Connection timeout. Please check if your backend server is running.');
      }

      rethrow;
    }
  }

  // Add logout method
  Future<void> logout() async {
    await GraphQLService.clearAuthData();
    AppLogger.info('✅ Logout successful');
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await GraphQLService.isLoggedIn();
  }

  // Get current user
  Future<Map<String, dynamic>?> getCurrentUser() async {
    return await GraphQLService.getCurrentUser();
  }
}