import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import 'dashboard.dart';
import '../main.dart';
import 'user_info.dart';
import 'family_list.dart';
import 'settings.dart';
import 'geolocation.dart';
import 'family_billing_log.dart';
import '../models/navigation_item.dart';

class StudentHistoryLocationPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  
  const StudentHistoryLocationPage({
    super.key,
    this.userData,
  });

  @override
  State<StudentHistoryLocationPage> createState() => _StudentHistoryLocationPageState();
}

class _StudentHistoryLocationPageState extends State<StudentHistoryLocationPage> {
  List<dynamic> locationHistory = [];
  bool isLoading = true;
  String? errorMessage;
  bool _isExpanded = true;
  int _selectedIndex = 2;
  late List<NavigationItem> _navigationItems;

  @override
  void initState() {
    super.initState();
    _navigationItems = _getNavigationItems();
    _fetchLocationHistory();
  }

  List<NavigationItem> _getNavigationItems() {
    return [
      NavigationItem(
        title: 'Dashboard',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
      ),
      NavigationItem(
        title: 'Family',
        icon: Icons.family_restroom_outlined,
        selectedIcon: Icons.family_restroom,
      ),
      NavigationItem(
        title: 'Location',
        icon: Icons.location_on_outlined,
        selectedIcon: Icons.location_on,
      ),
      NavigationItem(
        title: 'Billing',
        icon: Icons.receipt_outlined,
        selectedIcon: Icons.receipt,
      ),
      NavigationItem(
        title: 'Settings',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        isBottom: true,
      ),
      NavigationItem(
        title: 'Logout',
        icon: Icons.logout_outlined,
        selectedIcon: Icons.logout,
        isBottom: true,
        onTap: _handleLogout,
      ),
    ];
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _handleNavigation(NavigationItem item) {
    if (item.onTap != null) {
      item.onTap!();
      return;
    }

    final index = _navigationItems.indexOf(item);
    setState(() {
      _selectedIndex = index;
    });

    switch (item.title) {
      case 'Dashboard':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardPage(userData: widget.userData),
          ),
        );
        break;
      case 'Family':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => FamilyListPage(userData: widget.userData ?? {}),
          ),
        );
        break;
      case 'Location':
        // Already on Location page
        break;
      case 'Billing':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => FamilyBillingLogPage(userData: widget.userData ?? {}),
          ),
        );
        break;
      case 'Settings':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SettingsPage(userData: widget.userData),
          ),
        );
        break;
    }
  }

  Future<void> _fetchLocationHistory() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final String userCode = widget.userData?['userCode'] ?? '';
      if (userCode.isEmpty) {
        throw Exception('Invalid user code');
      }

      final response = await http.get(
        Uri.parse('https://stsapi.bccbsis.com/geofence_check.php?family_code=$userCode'),
      );

      final data = json.decode(response.body);
      
      // Debug logging
      print('API Response: $data');
      if (data['geoLocationDetails'] != null && data['geoLocationDetails'].isNotEmpty) {
        print('First location data: ${data['geoLocationDetails'][0]}');
        print('Lat type: ${data['geoLocationDetails'][0]['lat'].runtimeType}');
        print('Lng type: ${data['geoLocationDetails'][0]['lng'].runtimeType}');
      }

      if (response.statusCode == 200 && data['message'] == 'Success') {
        setState(() {
          locationHistory = data['geoLocationDetails'];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = data['message'] ?? 'Failed to fetch location history';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching location history: $e');
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('MMMM dd, yyyy - hh:mm a').format(dateTime);
    } catch (e) {
      return dateTimeString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/image/backgrounds/bg.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black26,
              BlendMode.darken,
            ),
          ),
        ),
        child: Row(
          children: [
            _buildSidebar(),
            Expanded(
              child: Column(
                children: [
                  _buildAppBar(),
                  Expanded(
                    child: Container(
                      color: Colors.grey[50]?.withOpacity(0.95),
                      padding: const EdgeInsets.all(24),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _buildMainContent(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchLocationHistory,
        backgroundColor: const Color(0xFF4CAF50),
        child: const Icon(Icons.refresh),
        tooltip: 'Refresh Data',
      ),
    );
  }

  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _isExpanded ? 250 : 70,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildSidebarHeader(),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  ..._navigationItems.where((item) => !item.isBottom).map(_buildNavigationItem),
                  const Divider(height: 16),
                  ..._navigationItems.where((item) => item.isBottom).map(_buildNavigationItem),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      height: 70,
      padding: EdgeInsets.symmetric(horizontal: _isExpanded ? 16 : 12),
      child: Row(
        children: [
          if (_isExpanded) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage('assets/image/logos/Trackademia.png'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Trackademia',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w300,
                letterSpacing: 0.5,
              ),
            ),
          ],
          const Spacer(),
          IconButton(
            onPressed: () => setState(() => _isExpanded = !_isExpanded),
            icon: Icon(
              _isExpanded ? Icons.chevron_left : Icons.chevron_right,
              size: 22,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItem(NavigationItem item) {
    final isSelected = _navigationItems.indexOf(item) == _selectedIndex;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleNavigation(item),
        child: Container(
          height: 50,
          padding: EdgeInsets.symmetric(
            horizontal: _isExpanded ? 16 : 12,
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? item.selectedIcon : item.icon,
                size: 22,
                color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[600],
              ),
              if (_isExpanded) ...[
                const SizedBox(width: 12),
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                    color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[800],
                  ),
                ),
              ],
              if (_isExpanded && isSelected && item.onTap == null)
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text(
            'Student Location History',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w300,
              color: Color(0xFF4CAF50),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Icon(
                Icons.notifications_outlined,
                color: Colors.grey[600],
                size: 24,
              ),
              const SizedBox(width: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[50]?.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => UserInfoPage(
                            userData: widget.userData,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFF4CAF50),
                          radius: 16,
                          child: Text(
                            (widget.userData?['name'] as String?)?.isNotEmpty == true
                                ? (widget.userData!['name'] as String).substring(0, 1).toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          widget.userData?['name'] ?? 'User',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_drop_down,
                          color: Colors.grey[600],
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (locationHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No location history found',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[600],
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: locationHistory.length,
      itemBuilder: (context, index) {
        final location = locationHistory[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on,
                color: Color(0xFF4CAF50),
                size: 32,
              ),
            ),
            title: Text(
              location['student_name'] ?? 'Unknown Student',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4CAF50),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Time: ${_formatDateTime(location['created_at'])}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Status: ${location['insideStatus']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: location['insideStatus'] == 'Inside'
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Location: (${location['lat']}, ${location['lng']})',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            onTap: () {
              try {
                final lat = double.tryParse(location['lat']?.toString() ?? '0') ?? 0.0;
                final lng = double.tryParse(location['lng']?.toString() ?? '0') ?? 0.0;
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GeoLocationPage(
                      lat: lat,
                      lng: lng,
                      studentName: location['student_name'] ?? 'Unknown Student',
                    ),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error loading location: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }
} 