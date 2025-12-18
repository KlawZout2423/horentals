import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/property_model.dart';
import '../services/graphql_service.dart';
import '../themes.dart';
import 'property_details_screen.dart';

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
      appBar: AppBar(
        title: const Text('Saved Properties'),
        backgroundColor: AppTheme.primaryRed,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedProperties.isEmpty
              ? const Center(
                  child: Text('You have no saved properties yet.'),
                )
              : ListView.builder(
                  itemCount: _savedProperties.length,
                  itemBuilder: (context, index) {
                    final property = _savedProperties[index];
                    return ListTile(
                      leading: Image.network(property.displayImage ?? '', width: 100, fit: BoxFit.cover),
                      title: Text(property.title),
                      subtitle: Text(property.location),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PropertyDetailsScreen(property: property),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
