import 'package:flutter/material.dart';
import '../themes.dart';
import '../services/graphql_service.dart';

class Property {
  final String title;
  final String location;
  final double price;
  final String type;
  final String? displayImage;

  Property({
    required this.title,
    required this.location,
    required this.price,
    required this.type,
    this.displayImage,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      title: json['title'],
      location: json['location'],
      price: (json['price'] as num).toDouble(),
      type: json['type'],
      displayImage: json['displayImage'],
    );
  }
}

class PropertyListScreen extends StatefulWidget {
  const PropertyListScreen({super.key});

  @override
  State<PropertyListScreen> createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  String _selectedLocation = 'All Locations';

  // Replace hardcoded data with real data
  List<Property> _properties = [];
  bool _isLoading = true;


  // Advanced filter state
  double _minPrice = 100;
  double _maxPrice = 1000;
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  final List<String> _propertyTypes = [
    "Student Hostel",
    "Single Room",
    "Chamber & Hall",
    "Single Room SC",
    "2 Bedroom SC",
    "3 Bedroom SC",
    "4 Bedroom SC",
    "Apartment"
  ];
  final List<String> _cities = ['Ho', 'Accra', 'Kumasi', 'Takoradi', 'Cape Coast', 'Sunyani', 'Tamale'];

  // Filter state
  final Set<String> _selectedPropertyTypes = {};
  final Set<String> _selectedLocations = {};

  final List<String> _filters = [
    'All',
    'Student Hostel',
    'Single Room',
    'Chamber & Hall',
    'Single Room SC',
    '2 Bedroom SC',
    '3 Bedroom SC',
    '4 Bedroom SC',
    'Furnitures',
    'Lands',
    'Shops',
    'Short Stay'
  ];
  final List<String> _locations = [
    'All Locations',
    'HO Poly',
    'Mirage',
    'Barracks',
    'Ahove',
    'UHAS',
    'NTC',
    'New Town',
    'Deme'
  ];

  @override
  void initState() {
    super.initState();
    _fetchProperties();
    _minPriceController.text = _minPrice.toInt().toString();
    _maxPriceController.text = _maxPrice.toInt().toString();
  }

  Future<void> _fetchProperties() async {
    try {
      setState(() => _isLoading = true);
      final propertiesData = await GraphQLService.getProperties();
      setState(() {
        _properties = propertiesData.map((data) => Property.fromJson(data)).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching properties: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Property> get _filteredProperties {
    return _properties.where((property) {
      final matchesSearch = _searchController.text.isEmpty ||
          property.title.toLowerCase().contains(_searchController.text.toLowerCase());
      final matchesFilter = _selectedFilter == 'All' || property.type == _selectedFilter;
      final matchesLocation = _selectedLocation == 'All Locations' ||
          property.location == _selectedLocation;
      final matchesPrice = property.price >= _minPrice && property.price <= _maxPrice;

      // Advanced filters
      final matchesPropertyTypes = _selectedPropertyTypes.isEmpty ||
          _selectedPropertyTypes.contains(property.type);
      final matchesLocations = _selectedLocations.isEmpty ||
          _selectedLocations.contains(property.location);

      return matchesSearch && matchesFilter && matchesLocation && matchesPrice &&
          matchesPropertyTypes && matchesLocations;
    }).toList();
  }

  void _showPropertyDetails(Property property) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Property Image
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: property.displayImage != null
                        ? DecorationImage(
                            image: NetworkImage(property.displayImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    gradient: property.displayImage == null
                        ? LinearGradient(colors: [AppTheme.primaryRed.withOpacity(0.2), AppTheme.gold.withOpacity(0.2)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                        : null,
                  ),
                  child: property.displayImage == null
                      ? Center(child: Icon(Icons.home_work_rounded, color: AppTheme.primaryRed.withOpacity(0.6), size: 80))
                      : null,
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Property Title and Rating
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            property.title,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textColor(context),
                            ),
                          ),
                        ), // REMOVED RATING WIDGET
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Location
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: AppTheme.primaryRed,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          property.location,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.textSecondaryColor(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Property Type
                    Row(
                      children: [
                        Icon(
                          Icons.category_rounded,
                          color: AppTheme.textSecondaryColor(context),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          property.type,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondaryColor(context),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Price in Ghana Cedis
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryRed.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Monthly Rent',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondaryColor(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'GHC ${property.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryRed,
                            ),
                          ),
                          Text(
                            'Per Month',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
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
                              'Close',
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
                              // Contact landlord action
                              _showContactDialog(property);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryRed,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Contact Landlord',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContactDialog(Property property) {
    Navigator.pop(context); // Close property details first

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Contact Landlord',
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Would you like to contact the landlord for "${property.title}" in ${property.location}?',
          style: TextStyle(
            color: AppTheme.textSecondaryColor(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppTheme.textSecondaryColor(context),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Contacting landlord for ${property.title}...'),
                  backgroundColor: AppTheme.primaryRed,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
            ),
            child: const Text('Call Now'),
          ),
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
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85, // Reduced height
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondaryColor(context).withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Text(
                    'Set Your Preferences',
                    style: TextStyle(
                      fontSize: 20, // Slightly smaller
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: AppTheme.textSecondaryColor(context)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildFilterContent(),
              ),
            ),

            // Bottom buttons (fixed at bottom)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardColor(context),
                border: Border(
                  top: BorderSide(
                    color: AppTheme.textSecondaryColor(context).withOpacity(0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
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
                      onPressed: () {
                        setState(() {});
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRed,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with Search
          SliverAppBar(
            backgroundColor: AppTheme.cardColor(context),
            elevation: 0,
            pinned: true,
            floating: true,
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good morning 👋',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor(context),
                      ),
                    ),
                    Text(
                      'Jaque Daniels',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textColor(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search & Filters Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor(context),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: TextStyle(
                              color: AppTheme.textColor(context),
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search properties...',
                              hintStyle: TextStyle(
                                color: AppTheme.textSecondaryColor(context),
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: AppTheme.textSecondaryColor(context),
                                size: 22,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 18),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.filter_list_rounded, color: AppTheme.primaryRed),
                          onPressed: _showAdvancedFilterModal,
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Filter Chips
                  Text(
                    'Property Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 60, // Increased from 50 to accommodate more chips
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _filters.map((filter) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              filter,
                              style: TextStyle(
                                fontWeight: _selectedFilter == filter
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: _selectedFilter == filter
                                    ? Colors.white
                                    : AppTheme.textColor(context),
                              ),
                            ),
                            selected: _selectedFilter == filter,
                            onSelected: (selected) {
                              setState(() {
                                _selectedFilter = filter;
                              });
                            },
                            backgroundColor: AppTheme.cardColor(context),
                            selectedColor: AppTheme.primaryRed,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            side: BorderSide(
                              color: _selectedFilter == filter
                                  ? AppTheme.primaryRed
                                  : AppTheme.textSecondaryColor(context).withOpacity(0.3),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Location Chips
                  Text(
                    'Popular Locations in Ghana',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _locations.map((location) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              location,
                              style: TextStyle(
                                fontWeight: _selectedLocation == location
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: _selectedLocation == location
                                    ? Colors.white
                                    : AppTheme.textColor(context),
                              ),
                            ),
                            selected: _selectedLocation == location,
                            onSelected: (selected) {
                              setState(() {
                                _selectedLocation = location;
                              });
                            },
                            backgroundColor: AppTheme.cardColor(context),
                            selectedColor: AppTheme.primaryRed,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            side: BorderSide(
                              color: _selectedLocation == location
                                  ? AppTheme.primaryRed
                                  : AppTheme.textSecondaryColor(context).withOpacity(0.3),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Properties Grid
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Properties Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Available Properties (${_filteredProperties.length})',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textColor(context),
                        ),
                      ),
                      if (_filteredProperties.isNotEmpty)
                        const Text(
                          'See all',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.primaryRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Property Cards or Empty State
                  if (_filteredProperties.isEmpty)
                    _buildEmptyState(context)
                  else
                    ..._filteredProperties.map((property) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildPropertyCard(context, property),
                      );
                    }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 60,
            color: AppTheme.textSecondaryColor(context).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No properties found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or search terms',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterContent() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Budget Range
            Text(
              'Budget Range (GHC/month)',
              style: TextStyle(
                fontSize: 16, // Smaller font
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor(context),
              ),
            ),
            const SizedBox(height: 16),

            // Price Input Fields
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Min Price',
                        style: TextStyle(
                          fontSize: 14,
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
                          controller: _minPriceController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: AppTheme.textColor(context),
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: '300',
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
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              final newValue = double.tryParse(value);
                              if (newValue != null && newValue >= 0 && newValue <= 3000) {
                                setModalState(() {
                                  _minPrice = newValue;
                                  if (_minPrice > _maxPrice) {
                                    _maxPrice = _minPrice;
                                    _maxPriceController.text = _maxPrice.toInt().toString();
                                  }
                                });
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Max Price',
                        style: TextStyle(
                          fontSize: 14,
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
                          controller: _maxPriceController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: AppTheme.textColor(context),
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: '1500',
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
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              final newValue = double.tryParse(value);
                              if (newValue != null && newValue >= 0 && newValue <= 3000) {
                                setModalState(() {
                                  _maxPrice = newValue;
                                  if (_maxPrice < _minPrice) {
                                    _minPrice = _maxPrice;
                                    _minPriceController.text = _minPrice.toInt().toString();
                                  }
                                });
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            RangeSlider(
              values: RangeValues(_minPrice, _maxPrice),
              min: 0,
              max: 3000,
              divisions: 30,
              onChanged: (RangeValues values) {
                setModalState(() {
                  _minPrice = values.start;
                  _maxPrice = values.end;
                  _minPriceController.text = _minPrice.toInt().toString();
                  _maxPriceController.text = _maxPrice.toInt().toString();
                });
              },
              activeColor: AppTheme.primaryRed,
              inactiveColor: AppTheme.textSecondaryColor(context).withOpacity(0.3),
            ),

            Center(
              child: Text(
                'GHC${_minPrice.toInt()} - GHC${_maxPrice.toInt()}',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor(context),
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Property Types
            Text(
              'Property Types',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor(context),
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _propertyTypes.map((type) { final isSelected = _selectedPropertyTypes.contains(type);
                return ChoiceChip(
                  label: Text(type),
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.primaryRed : AppTheme.textColor(context),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setModalState(() {
                      if (selected) {
                        _selectedPropertyTypes.add(type);
                      } else {
                        _selectedPropertyTypes.remove(type);
                      }
                    });
                  },
                  backgroundColor: AppTheme.backgroundColor(context),
                  selectedColor: AppTheme.primaryRed.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.primaryRed
                          : AppTheme.textSecondaryColor(context).withOpacity(0.3),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Locations
            Text(
              'Locations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor(context),
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _cities.map((city) { final isSelected = _selectedLocations.contains(city);
                return ChoiceChip(
                  label: Text(city),
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.primaryRed : AppTheme.textColor(context),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setModalState(() {
                      if (selected) {
                        _selectedLocations.add(city);
                      } else {
                        _selectedLocations.remove(city);
                      }
                    });
                  },
                  backgroundColor: AppTheme.backgroundColor(context),
                  selectedColor: AppTheme.primaryRed.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.primaryRed
                          : AppTheme.textSecondaryColor(context).withOpacity(0.3),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20), // Extra space at bottom for scrolling
          ],
        );
      },
    );
  }

  Widget _buildPriceInputField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondaryColor(context),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: TextStyle(color: AppTheme.textColor(context), fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            prefixText: 'GHC ',
            prefixStyle: TextStyle(color: AppTheme.textSecondaryColor(context)),
            filled: true,
            fillColor: AppTheme.backgroundColor(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.textSecondaryColor(context).withOpacity(0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.textSecondaryColor(context).withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryRed, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyCard(BuildContext context, Property property) {
    return GestureDetector(
      onTap: () => _showPropertyDetails(property),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(20),
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
            // Property Image
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                image: property.displayImage != null ? DecorationImage(
                  image: NetworkImage(property.displayImage!),
                  fit: BoxFit.cover,
                ) : null,
                gradient: property.displayImage == null ? LinearGradient(
                  colors: [
                    AppTheme.primaryRed.withOpacity(0.1),
                    AppTheme.gold.withOpacity(0.1)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ) : null,
              ),
              child: property.displayImage == null ? Center(child: Icon(Icons.home_work_rounded, color: AppTheme.primaryRed.withOpacity(0.5), size: 60)) : null,

            ),

            // Property Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          property.title, // ← Use property.title
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textColor(context),
                          ),
                        ),
                      ), // REMOVE THE RATING WIDGET COMPLETELY
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: AppTheme.textSecondaryColor(context),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(property.location, // ← Use property.location
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondaryColor(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'GHC ${property.price.toStringAsFixed(0)}/month', // ← Use property.price
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryRed,
                        ),
                      ),
                      Container( // ... view details button
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRed,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}