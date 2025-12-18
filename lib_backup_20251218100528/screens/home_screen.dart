import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../themes.dart';
import '../services/graphql_service.dart';
import 'property_details_screen.dart';
import '../models/property_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

// Helper function to calculate responsive font size
double responsiveFontSize(BuildContext context, double baseFontSize) {
  final screenWidth = MediaQuery.of(context).size.width;
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
  if (screenWidth < 360) {
    return EdgeInsets.symmetric(horizontal: horizontal * 0.8, vertical: vertical);
  } else if (screenWidth < 400) {
    return EdgeInsets.symmetric(horizontal: horizontal * 0.9, vertical: vertical);
  }
  return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
}

class HomeScreen extends StatefulWidget {
  final Function(bool) toggleTheme;
  const HomeScreen({super.key, required this.toggleTheme});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ---------- STATE ----------
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Local state for properties and filtering
  List<Property> _allProperties = [];
  List<Property> _filteredProperties = [];
  bool _isLoading = true;
  String? _error;

  // Local state for filter criteria
  String _searchQuery = '';
  String _activeTypeFilter = 'All';

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  // Local UI state
  bool _showSearchBar = false;
  bool _showSelfContainedDropdown = false;

  // Filters
  double _minPrice = 300, _maxPrice = 1500;
  final Set<String> _selectedPropTypes = {}, _selectedLocs = {};

  // User data
  Map<String, dynamic>? _currentUser;

  // ---------- CHIP DATA ----------
  final List<Map<String, dynamic>> _typeChips = [
    {'label': 'All', 'icon': Icons.all_inclusive_rounded, 'type': 'All'},
    {'label': 'Filters', 'icon': Icons.filter_alt_rounded, 'type': 'filters'},
    {'label': 'Student Hostel', 'icon': Icons.school_rounded, 'type': 'Student Hostel'},
    {'label': 'Single Room', 'icon': Icons.single_bed_rounded, 'type': 'Single Room'},
    {'label': 'Chamber & Hall', 'icon': Icons.apartment_rounded, 'type': 'Chamber & Hall'},
    {'label': 'Self-Contained', 'icon': Icons.arrow_drop_down_rounded, 'type': 'self-contained'},
    {'label': 'Furnitures', 'icon': Icons.chair_rounded, 'type': 'Furnitures'},
    {'label': 'Lands', 'icon': Icons.landscape_rounded, 'type': 'Lands'},
    {'label': 'Shops', 'icon': Icons.store_rounded, 'type': 'Shops'},
    {'label': 'Short Stay', 'icon': Icons.hotel_rounded, 'type': 'Short Stay'},
  ];

  final List<Map<String, dynamic>> _selfContainedOptions = [
    {'label': 'Single Room SC', 'icon': Icons.single_bed_rounded, 'type': 'Single Room SC'},
    {'label': 'Chamber and Hall SC', 'icon': Icons.meeting_room_rounded, 'type': 'Chamber and Hall SC'},
    {'label': '2 Bedroom SC', 'icon': Icons.bed_rounded, 'type': '2 Bedroom SC'},
    {'label': '3 Bedroom SC', 'icon': Icons.bed_rounded, 'type': '3 Bedroom SC'},
    {'label': '4 Bedroom SC', 'icon': Icons.bed_rounded, 'type': '4 Bedroom SC'},
  ];

  // ---------- LIFECYCLE ----------
  @override
  void initState() {
    super.initState();
    _minPriceController.text = _minPrice.toInt().toString();
    _maxPriceController.text = _maxPrice.toInt().toString();
    _loadUserData();
    _fetchProperties();
  }

  @override
  Future<void> dispose() async {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final data = await _storage.read(key: 'user_data');
      if (data != null && mounted) {
        setState(() => _currentUser = json.decode(data));
        print('👤 Loaded user data: ${_currentUser?['name']}');
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
    }
  }

  String _getInitials() {
    if (_currentUser == null) return '...';
    final name = _currentUser?['name'] as String? ?? _currentUser?['email'] as String? ?? 'User';
    final parts = name.split(' ');
    if (name.isEmpty) return 'U';
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  // ---------- DATA FETCHING & FILTERING ----------
  Future<void> _fetchProperties() async {
    setState(() {
      _isLoading = true;
      _error = null;

    });

    try {
      print('🔄 Fetching properties from GraphQL...');
      final propertiesData = await GraphQLService.getProperties();
      print('✅ Received ${propertiesData.length} properties from backend');

      final List<Property> properties = [];

      for (var propertyData in propertiesData) {
        try {
          final property = Property.fromJson(propertyData);
          properties.add(property);
        } catch (e, stackTrace) {
          print('❌ Error parsing property: $e');
          print('   Stack trace: $stackTrace');
        }
      }
      try {
        print('🔄 Fetching properties from GraphQL...');
        final propertiesData = await GraphQLService.getProperties();
        print('✅ Received ${propertiesData.length} properties from backend');

        final List<Property> properties = [];

        for (var propertyData in propertiesData) {
          try {
            final property = Property.fromJson(propertyData);
            properties.add(property);
          } catch (e, stackTrace) {
            print('❌ Error parsing property: $e');
            print('   Stack trace: $stackTrace');
          }
        }

        // 🚨 MOVE DEBUG CODE HERE - AFTER ALL PROPERTIES ARE PARSED
        print('🔍 CHECKING IMAGE URLS:');
        print('📊 Total properties parsed: ${properties.length}');

        for (var property in properties) {
          print('   =================================');
          print('   Property: ${property.title}');
          print('   Type: ${property.type}');
          print('   displayImage: ${property.displayImage}');
          print('   Has images: ${property.hasImages}');
          print('   All URLs: ${property.allImageUrls}');
          print('   Gallery items: ${property.gallery?.length ?? 0}');
          print('   ImageUrl: ${property.imageUrl}');
          print('   Images array: ${property.images.length}');
          print('   =================================');
        }

        setState(() {
          _allProperties = properties;
          _isLoading = false;
        });

        _applyFilters();

        print('🎯 Total properties loaded: ${_allProperties.length}');
        if (properties.isNotEmpty) {
          print('📊 Sample property: ${properties.first.title} - ${properties.first.type} - ${properties.first.images.length} images');
        }

      } catch (e) {
        print('❌ Error fetching properties: $e');
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _allProperties = [];
          _filteredProperties = [];
        });
      }

      setState(() {
        _allProperties = properties;
        _isLoading = false;
      });

      _applyFilters();

      print('🎯 Total properties loaded: ${_allProperties.length}');
      if (properties.isNotEmpty) {
        print('📊 Sample property: ${properties.first.title} - ${properties.first.type} - ${properties.first.images.length} images');
      }

    } catch (e) {
      print('❌ Error fetching properties: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _allProperties = [];
        _filteredProperties = [];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load properties: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      List<Property> filtered = _allProperties;

      if (_selectedPropTypes.isNotEmpty || _selectedLocs.isNotEmpty || _minPrice != 300 || _maxPrice != 1500) {
        filtered = filtered.where((p) => p.price >= _minPrice && p.price <= _maxPrice).toList();
        if (_selectedPropTypes.isNotEmpty) {
          filtered = filtered.where((p) => _selectedPropTypes.contains(p.type)).toList();
        }
        if (_selectedLocs.isNotEmpty) {
          filtered = filtered.where((p) => _selectedLocs.any((loc) => p.location.toLowerCase().contains(loc.toLowerCase()))).toList();
        }
      } else if (_activeTypeFilter != 'All') {
        if (_activeTypeFilter == 'self-contained') {
          filtered = filtered.where((p) => p.type.toLowerCase().contains('sc')).toList();
        } else {
          filtered = filtered.where((p) => p.type == _activeTypeFilter).toList();
        }
      }

      if (_searchQuery.isNotEmpty) {
        filtered = filtered.where((p) =>
        p.title.toLowerCase().contains(_searchQuery) ||
            p.location.toLowerCase().contains(_searchQuery)
        ).toList();
      }

      _filteredProperties = filtered;
    });
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: AppTheme.cardColor(context),
                pinned: true,
                floating: true,
                title: _showSearchBar
                    ? null
                    : Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: const DecorationImage(
                          image: AssetImage('assets/logo.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'HO Rentals',
                      style: TextStyle(
                        fontSize: responsiveFontSize(context, 18),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                actions: [
                  if (_showSearchBar)
                    Expanded(
                      child: Padding(
                        padding: responsivePadding(context, horizontal: 16),
                        child: _searchField(),
                      ),
                    )
                  else
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.search_rounded, color: AppTheme.primaryRed),
                          onPressed: () => setState(() => _showSearchBar = true),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/profile'),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
                              child: Text(
                                _getInitials(),
                                style: TextStyle(
                                  fontSize: responsiveFontSize(context, 12),
                                  color: AppTheme.primaryRed,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
                bottom: _showSearchBar
                    ? null
                    : PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(
                    color: Colors.grey.withOpacity(0.2),
                    height: 1,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: responsivePadding(context, horizontal: 16, vertical: 16),
                  child: Container(
                    padding: responsivePadding(context, horizontal: 20, vertical: 20),
                    decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: const BorderRadius.all(Radius.circular(16))
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Find Your Perfect Student Accommodation',
                          style: TextStyle(fontSize: responsiveFontSize(context, 20), fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Near Ho Polytechnic, UHAS & Trafalgar Campus',
                          style: TextStyle(color: Colors.white70, fontSize: responsiveFontSize(context, 13)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Quality hostels, rooms & self-contained apartments',
                          style: TextStyle(color: Colors.white70, fontSize: responsiveFontSize(context, 12)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: responsivePadding(context, horizontal: 16),
                  child: SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _typeChips.map((c) {
                        final selected = _activeTypeFilter == c['type'];
                        if (c['type'] == 'filters') return _filterChip(c, selected);
                        if (c['type'] == 'self-contained') return _selfContainedChip(c, selected);
                        return _typeChip(c, selected);
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverPadding(
                padding: responsivePadding(context, horizontal: 16, vertical: 16),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isLoading ? 'Loading...' : 'Available Properties (${_filteredProperties.length})',
                        style: TextStyle(fontSize: responsiveFontSize(context, 18), fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))
              else if (_error != null)
                SliverToBoxAdapter(child: Center(child: Text('Error: $_error')))
              else if (_filteredProperties.isEmpty)
                  SliverToBoxAdapter(child: _emptyState())
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                        padding: responsivePadding(context, horizontal: 16, vertical: 12),
                        child: _propertyCard(_filteredProperties[index]),
                      ),
                      childCount: _filteredProperties.length,
                    ),
                  ),
            ],
          ),
          if (_showSelfContainedDropdown)
            _selfContainedDropdownOverlay(),
          if (_showSelfContainedDropdown)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _showSelfContainedDropdown = false),
                behavior: HitTestBehavior.translucent,
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (i) {
          if (i == 1) Navigator.pushNamed(context, '/chat');
          if (i == 2) Navigator.pushNamed(context, '/profile');
        },
        selectedItemColor: AppTheme.primaryRed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_rounded), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _searchField() => Container(
    height: 40,
    decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(20)
    ),
    child: TextField(
      controller: _searchController,
      autofocus: true,
      onChanged: (value) {
        setState(() => _searchQuery = value.toLowerCase());
        _applyFilters();
      },
      decoration: InputDecoration(
        hintText: 'Search properties by title or location...',
        prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryRed),
        suffixIcon: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _showSearchBar = false;
                _searchController.clear();
                _searchQuery = '';
              });
              _applyFilters();
            }
        ),
        border: InputBorder.none,
      ),
    ),
  );

  Widget _typeChip(Map<String, dynamic> c, bool sel) => GestureDetector(
    onTap: () {
      setState(() => _activeTypeFilter = c['type'] as String);
      _applyFilters();
    },
    child: Container(
      margin: const EdgeInsets.only(right: 8),
      padding: responsivePadding(context, horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: sel ? AppTheme.primaryRed : AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: sel ? AppTheme.primaryRed : Colors.transparent),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(c['icon'], size: 16, color: sel ? Colors.white : AppTheme.primaryRed),
        const SizedBox(width: 6),
        Text(c['label'] as String, style: TextStyle(
          color: sel ? Colors.white : AppTheme.textColor(context),
          fontSize: responsiveFontSize(context, 12),
        )),
      ]),
    ),
  );

  Widget _filterChip(Map<String, dynamic> c, bool sel) => GestureDetector(
    onTap: _showAdvancedFilterModal,
    child: Container(
      margin: const EdgeInsets.only(right: 8),
      padding: responsivePadding(context, horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: sel ? AppTheme.primaryRed : AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(c['icon'], size: 16, color: sel ? Colors.white : AppTheme.primaryRed),
        const SizedBox(width: 6),
        Text(c['label'] as String, style: TextStyle(
          color: sel ? Colors.white : AppTheme.textColor(context),
          fontSize: responsiveFontSize(context, 12),
        )),
      ]),
    ),
  );

  Widget _selfContainedChip(Map<String, dynamic> c, bool sel) {
    final isAnySCOptionSelected = _selfContainedOptions.any((opt) => opt['type'] == _activeTypeFilter);
    final isSelected = _showSelfContainedDropdown || isAnySCOptionSelected;

    return GestureDetector(
      onTap: () => setState(() => _showSelfContainedDropdown = !_showSelfContainedDropdown),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: responsivePadding(context, horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryRed : AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(isSelected ? Icons.arrow_drop_up : c['icon'], size: 18, color: isSelected ? Colors.white : AppTheme.primaryRed),
          const SizedBox(width: 6),
          Text(c['label'] as String,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textColor(context),
                fontSize: responsiveFontSize(context, 12),
              )),
        ]),
      ),
    );
  }

  Widget _selfContainedDropdownOverlay() {
    return Positioned(
      top: 80,
      left: 16,
      right: 16,
      child: Material(
        color: AppTheme.cardColor(context),
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _selfContainedOptions.map((option) {
            final isSelected = _activeTypeFilter == option['type'];
            return ListTile(
              selected: isSelected,
              selectedColor: AppTheme.textColor(context),
              leading: Icon(option['icon'], color: isSelected ? AppTheme.primaryRed : AppTheme.textSecondaryColor(context)),
              title: Text(option['label'], style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
              onTap: () {
                setState(() {
                  _activeTypeFilter = option['type'];
                  _showSelfContainedDropdown = false;
                  _applyFilters();
                });
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _emptyState() => Container(
    padding: const EdgeInsets.all(40),
    margin: const EdgeInsets.all(16),
    decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16)
    ),
    child: Column(children: [
      const Icon(Icons.search_off_rounded, size: 50, color: Colors.grey),
      const SizedBox(height: 16),
      Text('No properties found', style: TextStyle(fontSize: responsiveFontSize(context, 16), fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      const Text('Try adjusting your filters', style: TextStyle(color: Colors.grey)),
    ]),
  );

  Widget _propertyCard(Property p) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PropertyDetailsScreen(property: p))
      ),
      child: Container(
        decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(16)
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _buildPropertyImage(p),
                ),
              ),
              _PropertyCardDetails(p: p),
            ]
        ),
      ),
    );
  }

  Widget _buildPropertyImage(Property p) {
    final imageUrl = p.displayImage;

    print('🖼️ BUILDING IMAGE FOR: ${p.title}');
    print('   displayImage: $imageUrl');
    print('   Is Cloudinary: ${imageUrl?.contains('cloudinary.com') ?? false}');
    print('   Is HTTP URL: ${imageUrl?.startsWith('http') ?? false}');

    if (imageUrl != null && imageUrl.isNotEmpty) {
      // Test URL accessibility in background
      Future(() async {
        try {
          final response = await http.get(Uri.parse(imageUrl));
          print('   ✅ URL test for "${p.title}": ${response.statusCode}');
        } catch (error) {
          print('   ❌ URL test failed for "${p.title}": $error');
        }
      });

      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) {
          print('❌ IMAGE LOAD FAILED for "${p.title}": $url');
          print('   Error type: ${error.runtimeType}');
          print('   Error message: $error');
          return _buildPlaceholderImage();
        },
      );
    }

    print('⚠️ No image URL for property: ${p.title}');
    return _buildPlaceholderImage();
  }

  Widget _buildPlaceholderImage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home_work_rounded, size: 60, color: AppTheme.primaryRed.withOpacity(0.5)),
          const SizedBox(height: 8),
          Text('No Image', style: TextStyle(color: AppTheme.primaryRed.withOpacity(0.7))),
        ],
      ),
    );
  }

  void _showAdvancedFilterModal() {
    _minPriceController.text = _minPrice.toInt().toString();
    _maxPriceController.text = _maxPrice.toInt().toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor(context),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondaryColor(context).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: responsivePadding(context, horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        'Set Your Preferences',
                        style: TextStyle(
                          fontSize: responsiveFontSize(context, 20),
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textColor(context),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 22),
                        onPressed: () => Navigator.pop(context),
                        color: AppTheme.textSecondaryColor(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    physics: const ClampingScrollPhysics(),
                    padding: responsivePadding(context, horizontal: 20, vertical: 20),
                    child: _buildFilterContent(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBudgetSection(),
        const SizedBox(height: 24),
        const Divider(height: 1),
        const SizedBox(height: 20),
        _buildPropertyTypesSection(),
        const SizedBox(height: 24),
        const Divider(height: 1),
        const SizedBox(height: 20),
        _buildLocationsSection(),
        const SizedBox(height: 32),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildBudgetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget Range (GHC/month)',
          style: TextStyle(
            fontSize: responsiveFontSize(context, 16),
            fontWeight: FontWeight.w600,
            color: AppTheme.textColor(context),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildPriceChip('Min', _minPrice),
            const SizedBox(width: 12),
            _buildPriceChip('Max', _maxPrice),
          ],
        ),
        const SizedBox(height: 16),
        RangeSlider(
          values: RangeValues(_minPrice, _maxPrice),
          min: 0,
          max: 3000,
          divisions: 30,
          onChanged: (RangeValues values) {
            setState(() {
              _minPrice = values.start;
              _maxPrice = values.end;
              _minPriceController.text = _minPrice.toInt().toString();
              _maxPriceController.text = _maxPrice.toInt().toString();
            });
          },
          activeColor: AppTheme.primaryRed,
          inactiveColor: AppTheme.textSecondaryColor(context).withOpacity(0.2),
        ),
        Center(
          child: Text(
            'GHC${_minPrice.toInt()} - GHC${_maxPrice.toInt()}',
            style: TextStyle(
              fontSize: responsiveFontSize(context, 14),
              color: AppTheme.textSecondaryColor(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceChip(String label, double value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label Price',
            style: TextStyle(
              fontSize: responsiveFontSize(context, 14),
              color: AppTheme.textSecondaryColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.textSecondaryColor(context).withOpacity(0.3),
              ),
            ),
            child: TextField(
              controller: label == 'Min' ? _minPriceController : _maxPriceController,
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontSize: responsiveFontSize(context, 16),
              ),
              decoration: InputDecoration(
                hintText: label == 'Min' ? '300' : '1500',
                hintStyle: TextStyle(
                  color: AppTheme.textSecondaryColor(context),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                prefix: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    'GHC',
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor(context),
                    ),
                  ),
                ),
              ),
              onChanged: (valueText) {
                if (valueText.isNotEmpty) {
                  final newValue = double.tryParse(valueText);
                  if (newValue != null && newValue >= 0 && newValue <= 3000) {
                    setState(() {
                      if (label == 'Min') {
                        _minPrice = newValue;
                        if (_minPrice > _maxPrice) {
                          _maxPrice = _minPrice;
                          _maxPriceController.text = _maxPrice.toInt().toString();
                        }
                      } else {
                        _maxPrice = newValue;
                        if (_maxPrice < _minPrice) {
                          _minPrice = _maxPrice;
                          _minPriceController.text = _minPrice.toInt().toString();
                        }
                      }
                    });
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyTypesSection() {
    final propertyTypes = [
      "Student Hostel",
      "Single Room",
      "Chamber & Hall",
      "Single Room SC",
      "2 Bedroom SC",
      "3 Bedroom SC",
      "4 Bedroom SC",
      "Furnitures",
      "Lands",
      "Shops",
      "Short Stay"
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Property Types',
          style: TextStyle(
            fontSize: responsiveFontSize(context, 16),
            fontWeight: FontWeight.w600,
            color: AppTheme.textColor(context),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: propertyTypes.map((type) {
            final isSelected = _selectedPropTypes.contains(type);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedPropTypes.remove(type);
                  } else {
                    _selectedPropTypes.add(type);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryRed : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryRed : AppTheme.textSecondaryColor(context).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  type,
                  style: TextStyle(
                    fontSize: responsiveFontSize(context, 13),
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : AppTheme.textColor(context),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLocationsSection() {
    final cities = [
      "Ho",
      "Hohoe",
      "Aflao",
      "Keta",
      "Sokode",
      "Adaklu",
      "Anyako",
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Locations',
          style: TextStyle(
            fontSize: responsiveFontSize(context, 16),
            fontWeight: FontWeight.w600,
            color: AppTheme.textColor(context),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: cities.map((city) {
            final isSelected = _selectedLocs.contains(city);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedLocs.remove(city);
                  } else {
                    _selectedLocs.add(city);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryRed : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryRed : AppTheme.textSecondaryColor(context).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  city,
                  style: TextStyle(
                    fontSize: responsiveFontSize(context, 13),
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : AppTheme.textColor(context),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _selectedPropTypes.clear();
                _selectedLocs.clear();
                _minPrice = 300;
                _maxPrice = 1500;
                _minPriceController.text = _minPrice.toInt().toString();
                _maxPriceController.text = _maxPrice.toInt().toString();
                _activeTypeFilter = 'All';
              });
              _applyFilters();
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(
                color: AppTheme.textSecondaryColor(context).withOpacity(0.3),
              ),
            ),
            child: Text(
              'Reset All',
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
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _activeTypeFilter = 'All';
              });
              _applyFilters();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Apply Filters',
              style: TextStyle(
                fontSize: responsiveFontSize(context, 14),
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showContactInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('HO Rentals Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildContactItem(
              context,
              Icons.business_rounded,
              'HO Rentals',
              'Property Management',
            ),
            const SizedBox(height: 12),
            _buildContactItem(
              context,
              Icons.phone_rounded,
              '+233 55 792 2593',
              'Official Contact',
            ),
            const SizedBox(height: 12),
            _buildContactItem(
              context,
              Icons.location_on_rounded,
              'HO Polytechnic, Ho',
              'Office Location',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () => launchUrl(Uri(scheme: 'tel', path: '+233557922593')),
            child: const Text('Call Office'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(BuildContext context, IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryRed, size: 28),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(color: AppTheme.textSecondaryColor(context), fontSize: responsiveFontSize(context, 12))),
          ],
        ),
      ],
    );
  }
}

class _PropertyCardDetails extends StatelessWidget {
  const _PropertyCardDetails({required this.p});

  final Property p;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: responsivePadding(context, horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.title,
            style: TextStyle(
              fontSize: responsiveFontSize(context, 16),
              fontWeight: FontWeight.w700,
              color: AppTheme.textColor(context),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 14,
                color: AppTheme.textSecondaryColor(context),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  p.location,
                  style: TextStyle(
                    fontSize: responsiveFontSize(context, 13),
                    color: AppTheme.textSecondaryColor(context),
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'GHC ${p.price.toInt()} / month',
            style: TextStyle(
              fontSize: responsiveFontSize(context, 18),
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryRed,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatusBadge(context),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PropertyDetailsScreen(property: p)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  padding: responsivePadding(context, horizontal: 20, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'View Details',
                  style: TextStyle(
                    fontSize: responsiveFontSize(context, 12),
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Container _buildStatusBadge(BuildContext context) {
    final status = p.status?.toLowerCase() ?? 'available';
    final color = status == 'available' ? Colors.green : (status == 'taken' ? Colors.red : Colors.orange);
    final text = status.toUpperCase();

    return Container(
      padding: responsivePadding(context, horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color,
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: responsiveFontSize(context, 11),
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}