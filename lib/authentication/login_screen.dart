import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'signup_screen.dart';
import '../themes.dart';
import '../services/graphql_service.dart';
import '../services/auth_service.dart';
import '../services/admin_service.dart';

class DefaultAdminService {
  // Default admin credentials for quick login
  static const Map<String, dynamic> defaultAdminCredentials = {
    'phone': '0240000000', // Default admin phone number
    'password': 'admin123', // Default admin password
    'email': 'admin@horentals.com',
    'name': 'System Administrator',
  };

  static bool isDefaultAdmin(String phone, String password) {
    return phone == defaultAdminCredentials['phone'] &&
        password == defaultAdminCredentials['password'];
  }

  static Map<String, dynamic> getDefaultAdminUser() {
    return {
      'id': 'admin-001',
      'name': defaultAdminCredentials['name'],
      'email': defaultAdminCredentials['email'],
      'phone': defaultAdminCredentials['phone'],
      'role': 'admin', // ✅ Use role instead of isAdmin
      'token': 'default-admin-token-${DateTime.now().millisecondsSinceEpoch}',
    };
  }

  // Quick method to pre-fill admin credentials
  static Map<String, String> getCredentials() {
    return {
      'phone': defaultAdminCredentials['phone'],
      'password': defaultAdminCredentials['password'],
    };
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ✅ ADD THE MISSING CONTROLLERS
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController(); // For phone number

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  late AuthService _authService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _authService = AuthService(GraphQLService.initializeClient().value);
    _loadRememberedCredentials();
  }

  void _loadRememberedCredentials() async {
    final rememberedEmail = await _storage.read(key: 'remembered_email');
    if (rememberedEmail != null) {
      setState(() {
        _emailController.text = rememberedEmail;
        _rememberMe = true;
      });
    }
  }

  void _login() async {
    final phone = _emailController.text.trim();
    final password = _passwordController.text;

    if (phone.isEmpty || password.isEmpty) {
      _showSnackBar('Please fill in all fields');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    print('🔐 Login attempt with phone: $phone');

    try {
      // ✅ CHECK FOR DEFAULT ADMIN LOGIN
      if (DefaultAdminService.isDefaultAdmin(phone, password)) {
        print('👑 Default admin login detected');
        final adminUser = DefaultAdminService.getDefaultAdminUser();

        // Store admin authentication data
        await _storage.write(key: 'auth_token', value: adminUser['token']);
        await _storage.write(key: 'user_data', value: json.encode(adminUser));
        await _storage.write(key: 'user_role', value: 'admin');

        _showSnackBar('Welcome back, Administrator!');

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/admin');
        return;
      }

      // ✅ Use the EXACT same format as signup
      // Your signup uses: '$phone@horentals.com' directly
      final emailForBackend = '$phone@horentals.com';
      print('📱 Using email for login: $emailForBackend');

      final result = await _authService.login(
        email: emailForBackend,
        password: password,
      );

      print('🔑 Login result: $result');

      if (result['token'] != null && result['user'] != null) {
        // ✅ FIXED: Use standardized storage
        await GraphQLService.storeAuthData(result['token'], result['user']);

        final userRole = result['user']['role']?.toString().toLowerCase() ?? 'user';

        _showSnackBar('Welcome back, ${result['user']['name']}!');

        if (!mounted) return;

        if (userRole == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        _showSnackBar('Login failed. Please check your phone number and password.');
      }

    // Remember credentials if enabled (moved outside the success block)
    if (_rememberMe) {
      await _storage.write(key: 'remembered_email', value: phone);
    } else {
      await _storage.delete(key: 'remembered_email');
    }
    } catch (e) {
      print('🚨 Login error: $e');
      _showSnackBar('Error: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: message.toLowerCase().contains('error') || message.toLowerCase().contains('fail')
            ? Colors.red
            : AppTheme.primaryRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Your Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Image.asset(
                      'assets/logo.jpg',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppTheme.primaryRed,
                          child: const Center(
                            child: Text(
                              'LOGO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Header Section
                Column(
                  children: [
                    Text(
                      "Welcome Back",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textColor(context),
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Sign in with your phone number",
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondaryColor(context),
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Form Container with Shadow
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor(context),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Phone Number Field (Updated from Email)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Phone Number", // Clear label
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textColor(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                              ),
                            ),
                            child: TextField(
                              controller: _emailController, // ✅ NOW DEFINED
                              style: TextStyle(
                                color: AppTheme.textColor(context),
                              ),
                              keyboardType: TextInputType.phone, // Phone keyboard
                              decoration: InputDecoration(
                                hintText: "Enter your phone number", // Clear hint
                                hintStyle: TextStyle(
                                  color: AppTheme.textSecondaryColor(context),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Password Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Password",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textColor(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                              ),
                            ),
                            child: TextField(
                              controller: _passwordController, // ✅ NOW DEFINED
                              obscureText: _obscurePassword,
                              style: TextStyle(
                                color: AppTheme.textColor(context),
                              ),
                              decoration: InputDecoration(
                                hintText: "Enter your password",
                                hintStyle: TextStyle(
                                  color: AppTheme.textSecondaryColor(context),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                suffixIcon: Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      color: AppTheme.textSecondaryColor(context),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Remember Me & Forgot Password
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    _rememberMe = value!;
                                  });
                                },
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                fillColor: MaterialStateProperty.resolveWith<Color>(
                                      (Set<MaterialState> states) {
                                    return AppTheme.primaryRed;
                                  },
                                ),
                              ),
                              Text(
                                'Remember me',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondaryColor(context),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              _showSnackBar('Password reset feature coming soon');
                            },
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.primaryRed,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Sign In Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryRed,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shadowColor: AppTheme.primaryRed.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : Text(
                            "SIGN IN",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  _emailController.text = DefaultAdminService
                                      .defaultAdminCredentials['phone']!;
                                  _passwordController.text = DefaultAdminService
                                      .defaultAdminCredentials['password']!;
                                  _showSnackBar(
                                      'Admin credentials loaded. Tap SIGN IN.');
                                },
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryRed,
                          ),
                          child: Text(
                            "Use Admin Account",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Sign Up Link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          fontSize: 15,
                          color: AppTheme.textSecondaryColor(context),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignupScreen(),
                            ),
                          );
                        },
                        child: Text(
                          "Sign Up",
                          style: TextStyle(
                            fontSize: 15,
                            color: AppTheme.primaryRed,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ ADD DISPOSE METHOD TO CLEAN UP CONTROLLERS
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}