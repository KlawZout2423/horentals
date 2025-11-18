import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'property_management.dart';
import 'property_upload_screen.dart';
import '/themes.dart';

class AdminDashboard extends StatelessWidget {
  final String getStatsQuery = '''
    query AdminDashboard {
      users {
        id
        name
        email
        role
        phone
      }
      bookings {
        id
        startDate
        endDate
        totalAmount
        status
        commissionAmount
        user {
          id
          name
          email
        }
        property {
          id
          title
          location
          price
        }
        company {
          id
          name
        }
      }
      properties {
        id
        title
        location
        price
        status
        type
        bedrooms
        bathrooms
        rating
        owner {
          id
          name
          email
        }
        company {
          id
          name
        }
      }
      companies {
        id
        name
        logoUrl
        contact
        isOwnCompany
        properties {
          id
          title
          status
        }
      }
      me {
        id
        name
        email
        role
      }
    }
  ''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        backgroundColor: AppTheme.primaryRed,
      ),
      body: Query(
        options: QueryOptions(document: gql(getStatsQuery)),
        builder: (QueryResult result, {Refetch? refetch, FetchMore? fetchMore}) {
          if (result.isLoading) return Center(child: CircularProgressIndicator());

          if (result.hasException) {
            return Center(
              child: Text('Error loading data: ${result.exception.toString()}'),
            );
          }

          final properties = result.data?['properties'] ?? [];
          final users = result.data?['users'] ?? [];
          final bookings = result.data?['bookings'] ?? [];

          // Calculate stats
          final totalProperties = properties.length;
          final availableProperties = properties.where((p) => p['status'] == 'available').length;
          final totalUsers = users.length;
          final totalRevenue = bookings.fold(0.0, (sum, booking) => sum + (booking['totalAmount'] ?? 0));

          return Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Quick Stats
                Row(
                  children: [
                    _buildStatCard('Total Properties', totalProperties, Icons.home),
                    _buildStatCard('Available', availableProperties, Icons.check_circle, color: Colors.green),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatCard('Total Users', totalUsers, Icons.people),
                    _buildStatCard('Revenue', 'GHS $totalRevenue', Icons.attach_money, color: Colors.green),
                  ],
                ),

                SizedBox(height: 32),

                // Quick Actions
                Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),

                GridView(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                  ),
                  children: [
                    _buildActionCard('Manage Properties', Icons.manage_search, Colors.blue, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyManagement()));
                    }),
                    _buildActionCard('Add Property', Icons.add_home_work, Colors.green, () {
                      Navigator.push(context, MaterialPageRoute(
                          builder: (_) => PropertyUploadScreen()
                      ));
                    }),
                    _buildActionCard('View Users', Icons.people_alt, Colors.orange, () {
                      // Navigate to user management
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('User management coming soon')),
                      );
                    }),
                    _buildActionCard('Analytics', Icons.analytics, Colors.purple, () {
                      // Navigate to analytics
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Analytics coming soon')),
                      );
                    }),
                  ],
                ),

                SizedBox(height: 32),

                // Recent Activity
                Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: [
                      ListTile(leading: Icon(Icons.add), title: Text('New property added'), subtitle: Text('2 hours ago')),
                      ListTile(leading: Icon(Icons.person_add), title: Text('New user registered'), subtitle: Text('4 hours ago')),
                      ListTile(leading: Icon(Icons.calendar_today), title: Text('New booking created'), subtitle: Text('6 hours ago')),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, dynamic value, IconData icon, {Color color = Colors.blue}) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 30, color: color),
              SizedBox(height: 8),
              Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(title, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: color),
              SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}