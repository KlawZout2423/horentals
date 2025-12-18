
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../themes.dart';
import '../services/graphql_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'dart:convert';


// Helper function to calculate responsive font size
double responsiveFontSize(BuildContext context, double baseFontSize) {
  final screenWidth = MediaQuery.of(context).size.width;
  if (screenWidth < 360) return baseFontSize * 0.8;
  if (screenWidth < 400) return baseFontSize * 0.9;
  return baseFontSize;
}

// Helper function to calculate responsive padding
EdgeInsets responsivePadding(BuildContext context,
    {double horizontal = 24.0, double vertical = 0.0}) {
  final screenWidth = MediaQuery.of(context).size.width;
  if (screenWidth < 360) return EdgeInsets.symmetric(horizontal: horizontal * 0.8, vertical: vertical);
  if (screenWidth < 400) return EdgeInsets.symmetric(horizontal: horizontal * 0.9, vertical: vertical);
  return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _acceptTerms = false;
  final _storage = const FlutterSecureStorage();

  late AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    GraphQLService.validateGraphQLUrl();
  }

  void _signUp() async {
    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (fullName.isEmpty || phone.isEmpty || password.isEmpty) {
      _showSnackBar('Please fill in all fields');
      return;
    }
    if (phone.length < 10) {
      _showSnackBar('Phone must be at least 10 digits');
      return;
    }
    if (password.length < 6) {
      _showSnackBar('Password must be at least 6 characters');
      return;
    }
    if (password != confirmPassword) {
      _showSnackBar('Passwords do not match');
      return;
    }
    if (!_acceptTerms) {
      _showSnackBar('Please accept the terms and conditions');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final autoEmail = '$phone@horentals.com';
      final result = await _authService.register(
        name: fullName,
        phone: phone,
        password: password,
        email: autoEmail,
      );

      if (result['token'] != null && result['user'] != null) {
        await _storage.write(key: 'auth_token', value: result['token']);
        await _storage.write(key: 'user_data', value: json.encode(result['user']));
        await _storage.write(key: 'user_role', value: result['user']['role'] ?? 'user');

        _showSnackBar('Account created! Welcome, $fullName');
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showSnackBar('Registration completed! Please login with your phone number.');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (e.toString().contains('User_email_key') || e.toString().contains('P2002')) {
        _showSnackBar('Phone number already registered. Please try logging in.');
      } else if (e.toString().contains('phone') && e.toString().contains('unique')) {
        _showSnackBar('Phone number already registered. Please try logging in.');
      } else {
        _showSnackBar('Signup error: ${e.toString()}');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: responsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              _buildBackButton(context),
              const SizedBox(height: 20),
              _buildLogo(),
              const SizedBox(height: 20),
              _buildHeader(context),
              const SizedBox(height: 32),
              _buildForm(context),
              const SizedBox(height: 32),
              _buildLoginLink(context),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.arrow_back_rounded, color: AppTheme.textColor(context), size: 20),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(25)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Image.asset(
          'assets/logo.jpg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: AppTheme.primaryRed,
            child: Center(
              child: Text('LOGO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Text(
          "Create Account",
          style: TextStyle(
            fontSize: responsiveFontSize(context, 24),
            fontWeight: FontWeight.w800,
            color: AppTheme.textColor(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Join thousands finding their perfect home in Ghana",
          style: TextStyle(
            fontSize: responsiveFontSize(context, 16),
            color: AppTheme.textSecondaryColor(context),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return Container(
      padding: responsivePadding(context, horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _buildTextField(_fullNameController, "Full Name", "Enter your full name"),
          const SizedBox(height: 20),
          _buildTextField(_phoneController, "Phone Number", "Enter your phone number",
              keyboardType: TextInputType.phone),
          const SizedBox(height: 20),
          _buildTextField(_passwordController, "Password", "Create a password",
              isPassword: true, obscureText: _obscurePassword, toggleObscure: () {
                setState(() => _obscurePassword = !_obscurePassword);
              }),
          const SizedBox(height: 20),
          _buildTextField(_confirmPasswordController, "Confirm Password", "Confirm your password",
              isPassword: true, obscureText: _obscureConfirmPassword, toggleObscure: () {
                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
              }),
          const SizedBox(height: 20),
          _buildTerms(),
          const SizedBox(height: 24),
          _buildSignUpButton(),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint,
      {TextInputType keyboardType = TextInputType.text,
        bool isPassword = false,
        bool obscureText = false,
        VoidCallback? toggleObscure}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textColor(context))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: TextStyle(color: AppTheme.textColor(context)),
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              suffixIcon: isPassword
                  ? IconButton(
                icon: Icon(obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                onPressed: toggleObscure,
              )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTerms() {
    return Row(
      children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: (v) => setState(() => _acceptTerms = v!),
          fillColor: MaterialStateProperty.all(AppTheme.primaryRed),
        ),
        Expanded(
          child: Wrap(
            children: [
              Text("I agree to the ", style: TextStyle(color: AppTheme.textSecondaryColor(context))),
              GestureDetector(
                  onTap: () => _showSnackBar('Terms & Conditions coming soon'),
                  child: Text("Terms & Conditions", style: TextStyle(color: AppTheme.primaryRed))),
              Text(" and ", style: TextStyle(color: AppTheme.textSecondaryColor(context))),
              GestureDetector(
                  onTap: () => _showSnackBar('Privacy Policy coming soon'),
                  child: Text("Privacy Policy", style: TextStyle(color: AppTheme.primaryRed))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryRed,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("CREATE ACCOUNT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildLoginLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Already have an account? ", style: TextStyle(color: AppTheme.textSecondaryColor(context))),
        GestureDetector(
          onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
          child: Text("Sign In", style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
