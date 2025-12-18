import 'package:flutter/material.dart';
import 'property_management.dart';
import 'property_upload_screen.dart';
import '../themes.dart';
import '../services/graphql_service.dart';
import '../models/property_model.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _currentCategory;
  late WidgetsBindingObserver _lifecycleObserver;

  // Consolidated state for all dashboard data
  List<Property> _allProperties = [];
  Map<String, dynamic>? _dashboardStats;
  bool _isLoading = true;

  // Property categories for sidebar
  final List<Map<String, dynamic>> _propertyCategories = [
    {'title': 'Dashboard', 'icon': Icons.dashboard, 'type': 'dashboard'},
    {'title': 'Student Hostel', 'icon': Icons.school, 'type': 'Student Hostel'},
    {'title': 'Single Room', 'icon': Icons.single_bed, 'type': 'Single Room'},
    {'title': 'Chamber & Hall', 'icon': Icons.apartment, 'type': 'Chamber & Hall'},
    {'title': 'Self-Contained', 'icon': Icons.home_work, 'type': 'Self Contained'},
    {'title': 'Lands', 'icon': Icons.landscape, 'type': 'Lands'},
    {'title': 'Furnitures', 'icon': Icons.chair, 'type': 'Furnitures'},
    {'title': 'Shops', 'icon': Icons.store, 'type': 'Shops'},
    {'title': 'Short Stay', 'icon': Icons.hotel, 'type': 'Short Stay'},
  ];

  bool get isMobile => MediaQuery.of(context).size.width < 768;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _lifecycleObserver = _LifecycleObserver(
      onResume: () {
        if (mounted) {
          print('📱 App resumed, refreshing dashboard...');
          _loadDashboardData();
        }
      },
    );
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      // Fetch properties and stats in parallel
      final results = await Future.wait([
        GraphQLService.getProperties(),
        GraphQLService.getDashboardStats(),
      ]);

      final propertiesData = results[0] as List<dynamic>;
      final statsData = results[1] as Map<String, dynamic>;

      setState(() {
        _allProperties = propertiesData.map((data) => Property.fromJson(data)).toList();
        _dashboardStats = statsData;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load dashboard data: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleDrawer() {
    if (_scaffoldKey.currentState!.isDrawerOpen) {
      Navigator.pop(context);
    } else {
      _scaffoldKey.currentState!.openDrawer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        toolbarHeight: kToolbarHeight * 0.8,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: const DecorationImage(
                  image: AssetImage('assets/splash_image.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Admin', style: TextStyle(fontSize: 18)),
          ],
        ),
        backgroundColor: AppTheme.primaryRed,
        leading: isMobile
            ? IconButton(icon: const Icon(Icons.menu), onPressed: _toggleDrawer)
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh Dashboard',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: isMobile ? _buildMobileDrawer() : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                if (!isMobile) _buildDesktopSidebar(),
                Expanded(
                  child: PropertyManagement(
                    categoryFilter: _currentCategory,
                    initialProperties: _allProperties,
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUploadPopup(context),
        backgroundColor: AppTheme.primaryRed,
        tooltip: 'Upload Property',
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    return Container(
      width: 220,
      color: Colors.white,
      child: Column(
        children: [
          _buildStats(context, isMobile: false),
          Expanded(
            child: ListView(
              children: [
                ..._propertyCategories.map((category) {
                  final isSelected = _currentCategory == category['type'] ||
                      (_currentCategory == null && category['type'] == 'dashboard');
                  return ListTile(
                    leading: Icon(
                      category['icon'],
                      color: isSelected ? AppTheme.primaryRed : Colors.grey[600],
                    ),
                    title: Text(
                      category['title'],
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? AppTheme.primaryRed : Colors.grey[800],
                      ),
                    ),
                    selected: isSelected,
                    onTap: () => setState(() => _currentCategory = category['type']),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      child: Column(
        children: [
          _buildStats(context, isMobile: true),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ..._propertyCategories.map((category) {
                  return ListTile(
                    leading: Icon(category['icon']),
                    title: Text(category['title']),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentCategory = category['type']);
                    },
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context, {required bool isMobile}) {
    if (_isLoading) {
      return _buildStatsLoading(isMobile: isMobile);
    }

    final int totalProperties = _allProperties.length;
    final int available = _allProperties.where((p) => p.status == 'available').length;
    final int rented = _allProperties.where((p) => p.status == 'taken').length;
    final int totalUsers = _dashboardStats?['totalUsers'] ?? 0;

    return _buildStatsContent(
      isMobile: isMobile,
      totalProperties: totalProperties,
      available: available,
      rented: rented,
      totalUsers: totalUsers,
    );
  }

  Widget _buildStatsLoading({required bool isMobile}) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, isMobile ? (MediaQuery.of(context).padding.top + 16) : 16, 16, 16),
      color: AppTheme.primaryRed,
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }


  Widget _buildStatsContent({
    required bool isMobile,
    required int totalProperties,
    required int available,
    required int rented,
    required int totalUsers,
  }) {
    return Container(
      color: AppTheme.primaryRed,
      padding: EdgeInsets.fromLTRB(16, isMobile ? (MediaQuery.of(context).padding.top + 16) : 16, 16, 16),
      child: Column(
        children: [
          if (!isMobile) ...[
            Container(
              width: 50,
              height: 50,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
                image: const DecorationImage(
                  image: AssetImage('assets/splash_image.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const Text(
              'Admin',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 12),
          ],
          _buildStatRow('Total Properties', totalProperties, Icons.business),
          const SizedBox(height: 8),
          _buildStatRow('Available', available, Icons.event_available),
          const SizedBox(height: 8),
          _buildStatRow('Rented', rented, Icons.key),
          const SizedBox(height: 8),
          _buildStatRow('Total Users', totalUsers, Icons.people),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int count, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showUploadPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Upload Property',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select property type:',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _propertyCategories
                      .where((cat) => cat['type'] != 'dashboard')
                      .map((category) {
                    return ActionChip(
                      avatar: Icon(category['icon'], size: 18),
                      label: Text(category['title']),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PropertyUploadScreen(
                              preselectedType: category['type'],
                            ),
                          ),
                        ).then((_) => _loadDashboardData());
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// Lifecycle observer
class _LifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback? onResume;

  _LifecycleObserver({this.onResume});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume?.call();
    }
  }
}
