import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../themes.dart';
import '../services/auth_service.dart';

// Helper function to calculate responsive font size
double responsiveFontSize(BuildContext context, double baseFontSize) {
  final screenWidth = MediaQuery.of(context).size.width;
  // Adjust the base font size based on the screen width
  if (screenWidth < 360) {
    return baseFontSize * 0.8;
  } else if (screenWidth < 400) {
    return baseFontSize * 0.9;
  }
  return baseFontSize;
}

// Helper function to calculate responsive padding
EdgeInsets responsivePadding(BuildContext context, {double horizontal = 24.0, double vertical = 0.0}) {
  final screenWidth = MediaQuery.of(context).size.width;
  // Adjust horizontal padding based on screen width
  if (screenWidth < 360) {
    return EdgeInsets.symmetric(horizontal: horizontal * 0.8, vertical: vertical);
  } else if (screenWidth < 400) {
    return EdgeInsets.symmetric(horizontal: horizontal * 0.9, vertical: vertical);
  }
  return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
}

class PersonalInformationScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const PersonalInformationScreen({super.key, this.userData});

  @override
  State<PersonalInformationScreen> createState() => _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late AuthService _authService;

  bool _isLoading = false;
  bool _isEditing = false;
  bool _isChangingPassword = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    // ✅ FIXED: Use the correct constructor
    _authService = AuthService(); // No arguments needed
    _loadUserData();
  }

  void _loadUserData() {
    if (widget.userData != null) {
      _nameController.text = widget.userData!['name'] ?? '';
      _emailController.text = widget.userData!['email'] ?? '';
      _phoneController.text = widget.userData!['phone'] ?? '';
    }
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.isEmpty) {
      _showSnackBar('Please enter your name');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // TODO: Implement actual profile update with GraphQL
      // For now, we'll update local storage
      final updatedUser = {
        ...?widget.userData,
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
      };

      await _storage.write(key: 'user_data', value: json.encode(updatedUser));

      setState(() {
        _isEditing = false;
        _isLoading = false;
      });

      _showSnackBar('Profile updated successfully!');
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error updating profile: $e');
    }
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty) {
      _showSnackBar('Please enter your current password');
      return;
    }

    if (_newPasswordController.text.length < 6) {
      _showSnackBar('New password must be at least 6 characters');
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnackBar('New passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // TODO: Implement actual password change with GraphQL
      // This would require a backend mutation

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isChangingPassword = false;
        _isLoading = false;
      });

      // Clear password fields
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      _showSnackBar('Password changed successfully!');
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error changing password: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: message.toLowerCase().contains('error') ? Colors.red : Colors.green,
      ),
    );
  }

  void _startEditing() {
    setState(() => _isEditing = true);
  }

  void _cancelEditing() {
    _loadUserData(); // Reset to original values
    setState(() => _isEditing = false);
  }

  void _togglePasswordChange() {
    setState(() {
      _isChangingPassword = !_isChangingPassword;
      if (!_isChangingPassword) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        title: const Text('Personal Information'),
        backgroundColor: AppTheme.cardColor(context),
        foregroundColor: AppTheme.textColor(context),
        elevation: 0,
        actions: [
          if (!_isEditing && !_isChangingPassword)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: _startEditing,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: responsivePadding(context, horizontal: 16, vertical: 16),
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(),
            const SizedBox(height: 24),

            // Personal Information Form
            _buildPersonalInfoForm(),
            const SizedBox(height: 24),

            // Change Password Section
            _buildPasswordSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final userInitials = _getUserInitials();
    final userName = _nameController.text.isNotEmpty ? _nameController.text : 'User';

    return Container(
      padding: responsivePadding(context, horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                userInitials,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: responsiveFontSize(context, 20),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: TextStyle(
                    fontSize: responsiveFontSize(context, 18),
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textColor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _emailController.text.isNotEmpty ? _emailController.text : 'No email provided',
                  style: TextStyle(
                    fontSize: responsiveFontSize(context, 14),
                    color: AppTheme.textSecondaryColor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _phoneController.text.isNotEmpty ? _phoneController.text : 'No phone provided',
                  style: TextStyle(
                    fontSize: responsiveFontSize(context, 14),
                    color: AppTheme.textSecondaryColor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoForm() {
    return Container(
      padding: responsivePadding(context, horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_rounded,
                color: AppTheme.primaryRed,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Personal Details',
                style: TextStyle(
                  fontSize: responsiveFontSize(context, 18),
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Name Field
          _buildFormField(
            label: 'Full Name',
            controller: _nameController,
            icon: Icons.person_outline_rounded,
            enabled: _isEditing,
          ),
          const SizedBox(height: 16),

          // Email Field
          _buildFormField(
            label: 'Email Address',
            controller: _emailController,
            icon: Icons.email_rounded,
            enabled: _isEditing,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),

          // Phone Field
          _buildFormField(
            label: 'Phone Number',
            controller: _phoneController,
            icon: Icons.phone_rounded,
            enabled: _isEditing,
            keyboardType: TextInputType.phone,
          ),

          if (_isEditing) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cancelEditing,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: AppTheme.textSecondaryColor(context).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryRed,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: responsiveFontSize(context, 14),
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Container(
      padding: responsivePadding(context, horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.lock_rounded,
                    color: AppTheme.primaryRed,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Password & Security',
                    style: TextStyle(
                      fontSize: responsiveFontSize(context, 18),
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  _isChangingPassword ? Icons.close_rounded : Icons.edit_rounded,
                  color: AppTheme.primaryRed,
                ),
                onPressed: _togglePasswordChange,
              ),
            ],
          ),

          if (_isChangingPassword) ...[
            const SizedBox(height: 16),
            _buildPasswordField(
              label: 'Current Password',
              controller: _currentPasswordController,
              obscureText: _obscureCurrentPassword,
              onToggleVisibility: () {
                setState(() => _obscureCurrentPassword = !_obscureCurrentPassword);
              },
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              label: 'New Password',
              controller: _newPasswordController,
              obscureText: _obscureNewPassword,
              onToggleVisibility: () {
                setState(() => _obscureNewPassword = !_obscureNewPassword);
              },
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              label: 'Confirm New Password',
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              onToggleVisibility: () {
                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _togglePasswordChange,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: AppTheme.textSecondaryColor(context).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryRed,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Change Password',
                      style: TextStyle(
                        fontSize: responsiveFontSize(context, 14),
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Change your password to keep your account secure',
              style: TextStyle(
                fontSize: responsiveFontSize(context, 14),
                color: AppTheme.textSecondaryColor(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: responsiveFontSize(context, 14),
            fontWeight: FontWeight.w600,
            color: AppTheme.textColor(context),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: enabled ? AppTheme.backgroundColor(context) : AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.textSecondaryColor(context).withOpacity(0.3),
            ),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: responsiveFontSize(context, 16),
            ),
            decoration: InputDecoration(
              hintText: 'Enter your $label',
              hintStyle: TextStyle(
                color: AppTheme.textSecondaryColor(context),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixIcon: Icon(
                icon,
                color: AppTheme.textSecondaryColor(context),
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: responsiveFontSize(context, 14),
            fontWeight: FontWeight.w600,
            color: AppTheme.textColor(context),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.textSecondaryColor(context).withOpacity(0.3),
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: responsiveFontSize(context, 16),
            ),
            decoration: InputDecoration(
              hintText: 'Enter your $label',
              hintStyle: TextStyle(
                color: AppTheme.textSecondaryColor(context),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixIcon: Icon(
                Icons.lock_outline_rounded,
                color: AppTheme.textSecondaryColor(context),
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: AppTheme.textSecondaryColor(context),
                  size: 20,
                ),
                onPressed: onToggleVisibility,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getUserInitials() {
    final name = _nameController.text;
    if (name.isEmpty) return 'U';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}