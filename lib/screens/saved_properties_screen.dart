import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/property_model.dart';
import '../services/graphql_service.dart';
import '../themes.dart';
import 'property_details_screen.dart';
import '../utils/responsive.dart';


class SavedPropertiesScreen extends StatefulWidget {
  const SavedPropertiesScreen({super.key});

  @override
  State<SavedPropertiesScreen> createState() => _SavedPropertiesScreenState();
}

class _SavedPropertiesScreenState extends State<SavedPropertiesScreen> {
  List<Property> _savedProperties = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedProperties();
  }

  Future<void> _loadSavedProperties() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPropertyIds = prefs.getStringList('saved_properties') ?? [];

    if (savedPropertyIds.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final propertiesData = await GraphQLService.getProperties();
      final allProperties = propertiesData.map((data) => Property.fromJson(data)).toList();

      setState(() {
        _savedProperties = allProperties.where((p) => savedPropertyIds.contains(p.id)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load saved properties: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        title: const Text('Saved Properties'),
        backgroundColor: AppTheme.cardColor(context),
        foregroundColor: AppTheme.textColor(context),
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _savedProperties.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bookmark_border_rounded, size: 64, color: AppTheme.textSecondaryColor(context).withOpacity(0.5)),
                          const SizedBox(height: 16),
                          Text(
                            'You have no saved properties yet.',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppTheme.textSecondaryColor(context),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Responsive(
                      mobile: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _savedProperties.length,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _propertyCard(_savedProperties[index]),
                        ),
                      ),
                      desktop: GridView.builder(
                        padding: const EdgeInsets.all(24),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: Responsive.isDesktop(context) ? 3 : 2,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                        ),
                        itemCount: _savedProperties.length,
                        itemBuilder: (context, index) => _propertyCard(_savedProperties[index]),
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _propertyCard(Property p) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PropertyDetailsScreen(property: p)),
      ),
      child: Container(
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Image.network(
                  p.displayImage ?? '',
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppTheme.primaryRed.withOpacity(0.1),
                    child: const Icon(Icons.broken_image_rounded),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.location,
                      style: TextStyle(color: AppTheme.textSecondaryColor(context), fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'GHC ${p.price} / month',
                      style: const TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold),
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
}
