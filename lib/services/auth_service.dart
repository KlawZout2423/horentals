import 'package:graphql_flutter/graphql_flutter.dart';
import 'graphql_service.dart';

class AuthService {
  final GraphQLClient client;

  AuthService(this.client);

  // Factory method using global client
  factory AuthService.create() {
    return AuthService(GraphQLService.initializeClient().value);
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
      print('🔐 Attempting registration for: $name');

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
      );

      if (result.hasException) {
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

      print('✅ Registration successful');
      return registerData;
    } catch (e) {
      print('💥 Registration error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔄 Login attempt with email: $email');

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

      final result = await client.mutate(
        MutationOptions(
          document: gql(loginMutation),
          variables: {
            'email': email,
            'password': password,
          },
        ),
      );

      if (result.hasException) {
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

      print('✅ Login successful for user: ${loginData['user']['name']}');
      return loginData;
    } catch (e) {
      print('🚨 Login error: $e');
      rethrow;
    }
  }
}