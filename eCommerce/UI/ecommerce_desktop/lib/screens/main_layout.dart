import 'package:flutter/material.dart';
import 'package:ecommerce_desktop/screens/dashboard_screen.dart';
import 'package:ecommerce_desktop/screens/calendar_screen.dart';
import 'package:ecommerce_desktop/screens/table_layout_screen.dart';
import 'package:ecommerce_desktop/screens/reports_screen.dart';
import 'package:ecommerce_desktop/screens/menu_screen.dart';
import 'package:ecommerce_desktop/screens/all_reservations_screen.dart';
import 'package:ecommerce_desktop/screens/profile_details_screen.dart';
import 'package:ecommerce_desktop/models/restaurant_model.dart';
import 'package:ecommerce_desktop/model/user.dart';
import 'package:ecommerce_desktop/providers/restaurant_provider.dart';
import 'package:ecommerce_desktop/providers/user_provider.dart';
import 'package:ecommerce_desktop/providers/auth_provider.dart';

class MainLayout extends StatefulWidget {
  final int restaurantId;

  const MainLayout({
    super.key,
    required this.restaurantId,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  bool _showProfile = false;
  Restaurant? _restaurant;
  User? _user;
  bool _isLoading = true;
  
  final RestaurantProvider _restaurantProvider = RestaurantProvider();
  final UserProvider _userProvider = UserProvider();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final restaurant = await _restaurantProvider.getById(widget.restaurantId);
      User? user;
      if (AuthProvider.userId != null) {
        user = await _userProvider.getById(AuthProvider.userId!);
      }
      
      setState(() {
        _restaurant = restaurant;
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading data: $e');
    }
  }

  List<Widget> get _screens => [
    DashboardScreen(restaurantId: widget.restaurantId),
    CalendarScreen(restaurantId: widget.restaurantId),
    TableLayoutScreen(restaurantId: widget.restaurantId),
    ReportsScreen(restaurantId: widget.restaurantId),
    MenuScreen(restaurantId: widget.restaurantId),
    AllReservationsScreen(restaurantId: widget.restaurantId),
  ];

  Widget get _currentScreen {
    if (_showProfile && _restaurant != null && _user != null) {
      return ProfileDetailsScreen(
        user: _user!,
        restaurant: _restaurant!,
        onUpdate: _loadData,
      );
    }
    return _screens[_selectedIndex];
  }

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.dashboard,
      label: 'Dashboard',
    ),
    NavigationItem(
      icon: Icons.calendar_today,
      label: 'Calendar',
    ),
    NavigationItem(
      icon: Icons.table_restaurant,
      label: 'Table Layout',
    ),
    NavigationItem(
      icon: Icons.bar_chart,
      label: 'Reports',
    ),
    NavigationItem(
      icon: Icons.restaurant_menu,
      label: 'Menu',
    ),
    NavigationItem(
      icon: Icons.list_alt,
      label: 'All Reservations',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 280,
            color: const Color(0xFFF5F5F0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Back Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF8B7355).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.arrow_back,
                            color: Color(0xFF8B7355),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Back to Restaurants',
                            style: TextStyle(
                              color: Color(0xFF8B7355),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Navigation Items
                ...List.generate(
                  _navigationItems.length,
                  (index) => _buildNavItem(index),
                ),
                const Spacer(),
                // Profile Section
                _buildProfileSection(),
                const SizedBox(height: 20),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: _currentScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = _navigationItems[index];
    final isSelected = _selectedIndex == index && !_showProfile;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF8B7355) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = index;
            _showProfile = false;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                item.icon,
                color: isSelected ? Colors.white : const Color(0xFF4A4A4A),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                item.label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF4A4A4A),
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    final isProfileSelected = _showProfile;
    
    return InkWell(
      onTap: () {
        if (_restaurant != null && _user != null) {
          setState(() {
            _showProfile = true;
          });
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: isProfileSelected ? const Color(0xFF8B7355).withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(8),
          border: isProfileSelected ? Border.all(color: const Color(0xFF8B7355), width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF8B7355),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Text(
                    _isLoading
                        ? 'Loading...'
                        : (_restaurant?.name ?? 'Restaurant Name'),
                    style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A4A4A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                    _isLoading
                        ? 'Loading...'
                        : (_user != null
                            ? '${_user!.firstName} ${_user!.lastName}'
                            : 'Manager'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
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
}

class NavigationItem {
  final IconData icon;
  final String label;

  NavigationItem({
    required this.icon,
    required this.label,
  });
}

