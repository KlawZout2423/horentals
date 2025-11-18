import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'models/property_model.dart';
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
import 'services/auth_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  // ✅ FIXED: ONE global client for entire app
  final ValueNotifier<GraphQLClient> _client = GraphQLService.initializeClient();

  // ✅ FIXED: ONE global auth service using the global client
  late final AuthService _authService = AuthService(_client.value);

  void _toggleTheme(bool isDark) {
    setState(() {
      _isDarkMode = isDark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
      client: _client, // ✅ Single client for entire app
      child: MaterialApp(
        title: 'HO Rentals',
        theme: _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => SplashScreen(),
          '/login': (context) => LoginScreen(),
          '/signup': (context) => SignupScreen(),
          '/admin': (context) => AdminDashboard(),
          '/admin/properties': (context) => PropertyManagement(),
          '/admin/upload': (context) => PropertyUploadScreen(),
          '/home': (context) => HomeScreen(toggleTheme: _toggleTheme),
          '/chat': (context) => ChatScreen(toggleTheme: _toggleTheme),
          '/profile': (context) => ProfileScreen(toggleTheme: _toggleTheme),
          '/property/details': (context) {
            final property = ModalRoute.of(context)!.settings.arguments as Property;
            return PropertyDetailsScreen(property: property);
          },
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}