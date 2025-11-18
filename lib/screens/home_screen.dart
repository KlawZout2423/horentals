import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../themes.dart';
import '../services/admin_service.dart';
import '../models/property_model.dart';
import 'property_details_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(bool) toggleTheme;
  const HomeScreen({super.key, required this.toggleTheme});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ---------- STATE ----------
  bool _isLoading = false;
  final AdminService _adminService = AdminService.instance;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  // Filters
  List<Property> _properties = [];
  String _selectedFilter = 'All';
  bool _showSearchBar = false;
  bool _showSelfContainedDropdown = false;
  double _minPrice = 300, _maxPrice = 1500;
  final Set<String> _selectedPropTypes = {}, _selectedLocs = {};

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
    _loadProperties();
    _loadUserData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  // ---------- DATA ----------
  Future<void> _loadProperties() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final list = await _adminService.getProperties();
      if (mounted) setState(() => _properties = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load properties'), backgroundColor: Colors.red),
        );
        setState(() => _properties = []);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserData() async {
    final data = await _storage.read(key: 'user_data');
    if (data != null && mounted) {
      setState(() => _currentUser = json.decode(data));
    }
  }

  Map<String, dynamic>? _currentUser;
  String _getInitials() {
    if (_currentUser == null) return 'U';
    final name = _currentUser!['name'] ?? _currentUser!['email'] ?? 'User';
    final parts = name.split(' ');
    return parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name[0].toUpperCase();
  }

  // ---------- FILTER ----------
  List<Property> get _filteredProperties {
    return _properties.where((p) {
      final searchOk = _searchController.text.isEmpty ||
          p.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          p.location.toLowerCase().contains(_searchController.text.toLowerCase());

      final priceOk = p.price >= _minPrice && p.price <= _maxPrice;

      // If using advanced filters, ignore the top-level type filter
      if (_selectedPropTypes.isNotEmpty || _selectedLocs.isNotEmpty) {
        final propTypeOk = _selectedPropTypes.isEmpty || _selectedPropTypes.contains(p.type);
        final locOk = _selectedLocs.isEmpty || _selectedLocs.any((city) => p.location.toLowerCase().contains(city.toLowerCase()));
        return searchOk && priceOk && propTypeOk && locOk;
      }

      final typeOk = _selectedFilter == 'All' || p.type == _selectedFilter;
      return typeOk && searchOk && priceOk;
    }).toList();
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      body: Stack(
        children: [
          // Main scroll content
          CustomScrollView(
          slivers: [
            // AppBar
            SliverAppBar(
              backgroundColor: AppTheme.cardColor(context),
              pinned: true,
              floating: true,
              title: _showSearchBar
                  ? _searchField()
                  : Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: const DecorationImage(
                      image: AssetImage('assets/logo.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('HO Rentals', style: TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/profile'),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.primaryRed,
                    child: Text(_getInitials(), style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ]),
              actions: _showSearchBar
                  ? []
                  : [
                IconButton(
                  icon: Icon(
                      Theme.of(context).brightness == Brightness.dark ? Icons.light_mode : Icons.dark_mode,
                      color: AppTheme.primaryRed),
                  onPressed: () => widget.toggleTheme(Theme.of(context).brightness == Brightness.light),
                ),
                IconButton(
                  icon: const Icon(Icons.search, color: AppTheme.primaryRed),
                  onPressed: () => setState(() => _showSearchBar = true),
                ),
              ],
            ),

            // Welcome banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.all(Radius.circular(16))),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Find Your Perfect\nStudent Accommodation',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                      SizedBox(height: 8),
                      Text('Quality hostels, rooms & apartments in Ho',
                          style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ),
            ),

            // Type chips
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _typeChips.map((c) {
                      final selected = _selectedFilter == c['type'];
                      if (c['type'] == 'filters') return _filterChip(c, selected);
                      if (c['type'] == 'self-contained') return _selfContainedChip(c, selected);
                      return _typeChip(c, selected);
                    }).toList(),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 60)),

            // Properties list
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isLoading ? 'Loading...' : 'Available Properties (${_filteredProperties.length})',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_filteredProperties.isEmpty)
                      _emptyState()
                    else
                      ..._filteredProperties.map((p) => Padding(padding: const EdgeInsets.only(bottom: 16), child: _propertyCard(p))),
                  ],
                ),
              ),
            ),
          ],
          ),

          // Self-contained dropdown overlay - MOVED INSIDE Stack
          if (_showSelfContainedDropdown)
            Positioned(
              top: 160,
              left: 16,
              right: 16,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 300),
                  decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _selfContainedOptions.map((o) {
                      final sel = _selectedFilter == o['type'];
                      return InkWell(
                        onTap: () => setState(() {
                          _selectedFilter = o['type'];
                          _showSelfContainedDropdown = false;
                        }),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: sel ? AppTheme.primaryRed.withOpacity(0.1) : null,
                            border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 0.5)),
                          ),
                          child: Row(children: [
                            Icon(o['icon'], color: AppTheme.primaryRed, size: 18),
                            const SizedBox(width: 8),
                            Text(o['label'],
                                style: TextStyle(
                                    fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                                    color: sel ? AppTheme.primaryRed : null)),
                            const Spacer(),
                            if (sel) const Icon(Icons.check, color: AppTheme.primaryRed),
                          ]),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
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

  // ---------- SMALL WIDGETS ----------
  Widget _searchField() => Container(
    height: 40,
    decoration: BoxDecoration(color: AppTheme.cardColor(context), borderRadius: BorderRadius.circular(20)),
    child: TextField(
      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Search properties...',
        prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryRed),
        suffixIcon: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _showSearchBar = false)),
        border: InputBorder.none,
      ),
    ),
  );

  Widget _typeChip(Map<String, dynamic> c, bool sel) => GestureDetector(
    onTap: () => setState(() => _selectedFilter = c['type']),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: sel ? AppTheme.primaryRed : AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: sel ? AppTheme.primaryRed : Colors.transparent),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(c['icon'], size: 16, color: sel ? Colors.white : AppTheme.primaryRed),
        const SizedBox(width: 6),
        Text(c['label'], style: TextStyle(color: sel ? Colors.white : null)),
      ]),
    ),
  );

  Widget _filterChip(Map<String, dynamic> c, bool sel) => GestureDetector(
    onTap: () => _showAdvancedFilterModal(),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: sel ? AppTheme.primaryRed : AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(c['icon'], size: 16, color: sel ? Colors.white : null),
        const SizedBox(width: 6),
        Text(c['label'], style: TextStyle(color: sel ? Colors.white : null)),
      ]),
    ),
  );

  Widget _selfContainedChip(Map<String, dynamic> c, bool sel) => GestureDetector(
    onTap: () => setState(() => _showSelfContainedDropdown = !_showSelfContainedDropdown),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _showSelfContainedDropdown ? AppTheme.primaryRed : AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(_showSelfContainedDropdown ? Icons.arrow_drop_up : c['icon'],
            size: 18, color: _showSelfContainedDropdown ? Colors.white : AppTheme.primaryRed),
        const SizedBox(width: 6),
        Text(c['label'],
            style: TextStyle(color: _showSelfContainedDropdown ? Colors.white : null)),
      ]),
    ),
  );

  Widget _emptyState() => Container(
    padding: const EdgeInsets.all(40),
    decoration: BoxDecoration(color: AppTheme.cardColor(context), borderRadius: BorderRadius.circular(16)),
    child: const Column(children: [
      Icon(Icons.search_off_rounded, size: 50, color: Colors.grey),
      SizedBox(height: 16),
      Text('No properties found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      SizedBox(height: 8),
      Text('Try adjusting your filters', style: TextStyle(color: Colors.grey)),
    ]),
  );

  Widget _propertyCard(Property p) => GestureDetector(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyDetailsScreen(property: p))),
    child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: AppTheme.cardColor(context), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Property image
        Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            color: AppTheme.primaryRed.withOpacity(0.1),
          ),
          child: p.images.isNotEmpty
              ? ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            child: Image.network(
              p.images.first,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
            ),
          )
              : _buildPlaceholderImage(),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Text(p.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.goldLight, borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  const Icon(Icons.star_rounded, color: AppTheme.gold, size: 16),
                  const SizedBox(width: 4),
                  Text(p.rating.toString(), style: const TextStyle(color: AppTheme.gold)),
                ]),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.location_on_rounded, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(p.location, style: const TextStyle(color: Colors.grey)),
            ]),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.primaryRed.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Monthly Rent', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text('GHC ${p.price}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.primaryRed)),
                ]),
                ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyDetailsScreen(property: p))),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryRed),
                  child: const Text('View Details', style: TextStyle(color: Colors.white)),
                ),
              ]),
            ),
          ]),
        ),
      ]),
    ),
  );

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

  // ---------- ADVANCED FILTER MODAL ----------
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
                // Header with title and close
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        'Set Your Preferences',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textColor(context),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close_rounded, size: 22),
                        onPressed: () => Navigator.pop(context),
                        color: AppTheme.textSecondaryColor(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Scrollable content
                Expanded(
                  child: StatefulBuilder(
                    builder: (BuildContext context, StateSetter setModalState) {
                      return SingleChildScrollView(
                        controller: scrollController,
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: _buildFilterContent(setModalState),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterContent(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Budget Section
        _buildBudgetSection(setModalState),
        const SizedBox(height: 24),
        const Divider(height: 1),
        const SizedBox(height: 20),
        // Property Types
        _buildPropertyTypesSection(setModalState),
        const SizedBox(height: 24),
        const Divider(height: 1),
        const SizedBox(height: 20),
        // Locations
        _buildLocationsSection(setModalState),
        const SizedBox(height: 32),
        // Action Buttons
        _buildActionButtons(setModalState),
      ],
    );
  }

  Widget _buildBudgetSection(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget Range (GHC/month)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textColor(context),
          ),
        ),
        const SizedBox(height: 16),

        // Compact price display
        Row(
          children: [
            _buildPriceChip('Min', _minPrice, setModalState),
            const SizedBox(width: 12),
            _buildPriceChip('Max', _maxPrice, setModalState),
          ],
        ),
        const SizedBox(height: 16),

        // Slider
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
          inactiveColor: AppTheme.textSecondaryColor(context).withOpacity(0.2),
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
      ],
    );
  }

  Widget _buildPriceChip(String label, double value, StateSetter setModalState) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label Price',
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
              controller: label == 'Min' ? _minPriceController : _maxPriceController,
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontSize: 16,
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
              onChanged: (value) {
                if (value.isNotEmpty) {
                  final newValue = double.tryParse(value);
                  if (newValue != null && newValue >= 0 && newValue <= 3000) {
                    setModalState(() {
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

  Widget _buildPropertyTypesSection(StateSetter setModalState) {
    final _propertyTypes = [
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
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textColor(context),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _propertyTypes.map((type) {
            final isSelected = _selectedPropTypes.contains(type);
            return GestureDetector(
              onTap: () {
                setModalState(() {
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
                    fontSize: 13,
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

  Widget _buildLocationsSection(StateSetter setModalState) {
    final _cities = [
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
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textColor(context),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _cities.map((city) {
            final isSelected = _selectedLocs.contains(city);
            return GestureDetector(
              onTap: () {
                setModalState(() {
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
                    fontSize: 13,
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

  Widget _buildActionButtons(StateSetter setModalState) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              // Reset all filters
              setModalState(() {
                _selectedPropTypes.clear();
                _selectedLocs.clear();
                _minPrice = 300;
                _maxPrice = 1500;
              });
              setState(() {});
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
    );
  }
}