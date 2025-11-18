import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../models/property_model.dart';
import '/themes.dart';

class PropertyManagement extends StatefulWidget {
  @override
  _PropertyManagementState createState() => _PropertyManagementState();
}

class _PropertyManagementState extends State<PropertyManagement> {
  String _selectedFilter = 'All';
  bool _showSelfContainedDropdown = false;

  // GraphQL Query
  final String getAllPropertiesQuery = '''
    query GetAllProperties {
      properties {
        id
        title
        location
        contact
        price
        description
        imageUrl
        images
        type
        status
        bedrooms
        bathrooms
        rating
        createdAt
        company {
          id
          name
          logoUrl
          contact
          isOwnCompany
        }
        owner {
          id
          name
          email
          role
          phone
        }
      }
    }
  ''';

  final String updatePropertyMutation = '''
    mutation UpdateProperty(\$id: Int!, \$input: PropertyInput!) {
      updateProperty(id: \$id, input: \$input) {
        id
        status
      }
    }
  ''';

  final String deletePropertyMutation = '''
    mutation DeleteProperty(\$id: Int!) {
      deleteProperty(id: \$id) {
        id      
      }
    }
  ''';

  // Chip data
  final List<Map<String, dynamic>> _typeChips = [
    {'label': 'All', 'icon': Icons.all_inclusive_rounded, 'type': 'All'},
    {'label': 'Student Hostel', 'icon': Icons.school_rounded, 'type': 'Student Hostel'},
    {'label': 'Single Room', 'icon': Icons.single_bed_rounded, 'type': 'Single Room'},
    {'label': 'Chamber & Hall', 'icon': Icons.apartment_rounded, 'type': 'Chamber & Hall'},
    {'label': 'Self-Contained', 'icon': Icons.arrow_drop_down_rounded, 'type': 'self-contained'},
  ];

  final List<Map<String, dynamic>> _selfContainedOptions = [
    {'label': 'Single Room SC', 'icon': Icons.single_bed_rounded, 'type': 'Single Room SC'},
    {'label': 'Chamber and Hall SC', 'icon': Icons.meeting_room_rounded, 'type': 'Chamber and Hall SC'},
    {'label': '2 Bedroom SC', 'icon': Icons.bed_rounded, 'type': '2 Bedroom SC'},
    {'label': '3 Bedroom SC', 'icon': Icons.bed_rounded, 'type': '3 Bedroom SC'},
    {'label': '4 Bedroom SC', 'icon': Icons.bed_rounded, 'type': '4 Bedroom SC'},
  ];

  List<Property> _filterProperties(List<Property> properties) {
    return properties.where((p) {
      return _selectedFilter == 'All' || p.type == _selectedFilter;
    }).toList();
  }

  void _editProperty(Property property) {
    // Navigate to edit screen
    print('Edit property: ${property.title}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit property: ${property.title}')),
    );
  }

  void _deleteProperty(int propertyId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Property'),
        content: Text('Are you sure you want to delete this property?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel')
          ),
          Mutation(
            options: MutationOptions(
              document: gql(deletePropertyMutation),
              variables: {'id': propertyId},
              onCompleted: (data) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Property deleted successfully')),
                );
              },
              onError: (error) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting property: $error')),
                );
              },
            ),
            builder: (RunMutation runMutation, QueryResult? result) {
              return ElevatedButton(
                onPressed: result?.isLoading == true ? null : () => runMutation({'id': propertyId}),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: result?.isLoading == true
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator())
                    : Text('Delete'),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Properties'),
        backgroundColor: AppTheme.primaryRed,
      ),
      body: Query(
        options: QueryOptions(document: gql(getAllPropertiesQuery)),
        builder: (QueryResult result, {Refetch? refetch, FetchMore? fetchMore}) {
          if (result.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (result.hasException) {
            return Center(
              child: Text('Error loading properties: ${result.exception.toString()}'),
            );
          }

          final propertiesData = result.data?['properties'] ?? [];
          final List<Property> properties = propertiesData.map((json) => Property.fromJson(json)).toList();
          final filteredProperties = _filterProperties(properties);

          return Column(
            children: [
              // Filter Chips
              Container(
                height: 60,
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _typeChips.map((c) {
                    final selected = _selectedFilter == c['type'];
                    if (c['type'] == 'self-contained') return _selfContainedChip(c, selected);
                    return _typeChip(c, selected);
                  }).toList(),
                ),
              ),

              // Properties List
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: filteredProperties.length,
                  itemBuilder: (context, index) {
                    final property = filteredProperties[index];
                    return _propertyManagementCard(property);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _typeChip(Map<String, dynamic> c, bool sel) => GestureDetector(
    onTap: () => setState(() => _selectedFilter = c['type']),
    child: Container(
      margin: EdgeInsets.only(right: 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: sel ? AppTheme.primaryRed : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(c['icon'], size: 16, color: sel ? Colors.white : AppTheme.primaryRed),
        SizedBox(width: 6),
        Text(c['label'], style: TextStyle(color: sel ? Colors.white : Colors.black)),
      ]),
    ),
  );

  Widget _selfContainedChip(Map<String, dynamic> c, bool sel) => GestureDetector(
    onTap: () => setState(() => _showSelfContainedDropdown = !_showSelfContainedDropdown),
    child: Container(
      margin: EdgeInsets.only(right: 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _showSelfContainedDropdown ? AppTheme.primaryRed : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(_showSelfContainedDropdown ? Icons.arrow_drop_up : c['icon'],
            size: 18, color: _showSelfContainedDropdown ? Colors.white : AppTheme.primaryRed),
        SizedBox(width: 6),
        Text(c['label'], style: TextStyle(color: _showSelfContainedDropdown ? Colors.white : Colors.black)),
      ]),
    ),
  );

  Widget _propertyManagementCard(Property property) {
    return Mutation(
      options: MutationOptions(document: gql(updatePropertyMutation)),
      builder: (RunMutation runMutation, QueryResult? result) {
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Property Image
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200],
                        image: property.images.isNotEmpty
                            ? DecorationImage(
                            image: NetworkImage(property.images.first),
                            fit: BoxFit.cover
                        )
                            : null,
                      ),
                      child: property.images.isEmpty
                          ? Icon(Icons.home_work, color: Colors.grey)
                          : null,
                    ),
                    SizedBox(width: 16),

                    // Property Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(property.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text(property.location, style: TextStyle(color: Colors.grey)),
                          SizedBox(height: 4),
                          Text('GHC ${property.price}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryRed)),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Chip(
                                label: Text(property.type, style: TextStyle(fontSize: 12)),
                                backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
                              ),
                              SizedBox(width: 8),
                              Chip(
                                label: Text(property.status,
                                    style: TextStyle(fontSize: 12, color: Colors.white)),
                                backgroundColor: property.status == 'available' ? Colors.green : Colors.red,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    // Toggle Availability
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(property.status == 'available' ? Icons.block : Icons.check_circle, size: 18),
                        label: Text(property.status == 'available' ? 'Mark as Taken' : 'Mark Available'),
                        onPressed: result?.isLoading == true ? null : () {
                          final newStatus = property.status == 'available' ? 'taken' : 'available';
                          runMutation({
                            'id': property.id,
                            'input': {'status': newStatus}
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 8),

                    // Edit Button
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editProperty(property),
                    ),

                    // Delete Button
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteProperty(property.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}