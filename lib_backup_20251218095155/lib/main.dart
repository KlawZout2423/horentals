import 'package:flutter/material.dart';
import 'dart:io';
import 'package:graphql_flutter/graphql_flutter.dart';

import 'screens/admin_dashboard.dart';
import 'screens/property_management.dart';
import 'screens/property_upload_screen.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/profile_screen.dart';
import 'authentication/login_screen.dart';
import 'authentication/signup_screen.dart';
import 'screens/property_details_screen.dart';
import 'themes.dart';
import 'screens/splash_screen.dart';
import 'services/graphql_service.dart';
import 'models/property_model.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() async {
  HttpOverrides.global = MyHttpOverrides(); // ← Add this line
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for caching
  await initHiveForFlutter();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  final ValueNotifier<GraphQLClient> _client = GraphQLService.initializeClient();

  void _toggleTheme(bool isDark) {
    setState(() {
      _isDarkMode = isDark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
      client: _client,
      child: MaterialApp(
        title: 'HO Rentals',
        theme: _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(), // Remove const
          '/signup': (context) => const SignupScreen(), // Remove const
          '/admin': (context) => const AdminDashboard(), // Remove const
          '/admin/properties': (context) => const PropertyManagement(),
          '/admin/upload': (context) => const PropertyUploadScreen(), // Remove const
          '/property/details': (context) {
            final property = ModalRoute.of(context)!.settings.arguments as Property;
            return PropertyDetailsScreen(property: property);
          },
        },
        // Use onGenerateRoute for screens that need parameters
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/home':
              return MaterialPageRoute(
                builder: (context) => HomeScreen(toggleTheme: _toggleTheme),
              );
            case '/chat':
            // You need to pass arguments when navigating to this screen
              final args = settings.arguments as Map<String, dynamic>? ?? {};

              return MaterialPageRoute(
                builder: (context) => ChatScreen(
                  propertyId: args['propertyId'] ?? 'default-id', // Provide a default or handle error
                  propertyTitle: args['propertyTitle'] ?? 'Property Chat',
                  ownerId: args['ownerId'] ?? 'default-owner-id',
                ),
              );
            case '/profile':
              return MaterialPageRoute(
                builder: (context) => ProfileScreen(toggleTheme: _toggleTheme),
              );
            default:
              return null;
          }
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}