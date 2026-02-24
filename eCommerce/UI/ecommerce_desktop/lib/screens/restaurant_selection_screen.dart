import 'package:flutter/material.dart';
import 'package:ecommerce_desktop/screens/login_screen.dart';
import 'package:ecommerce_desktop/models/restaurant_model.dart';
import 'package:ecommerce_desktop/providers/auth_provider.dart';
import 'package:ecommerce_desktop/providers/restaurant_provider.dart';
import 'package:ecommerce_desktop/model/user.dart';
import 'package:ecommerce_desktop/screens/add_restaurant_screen.dart';
import 'package:ecommerce_desktop/screens/main_layout.dart';
import 'package:ecommerce_desktop/widgets/screen_title_header.dart';

const Color _brownLight = Color(0xFFB39B7A);

class RestaurantSelectionScreen extends StatefulWidget {
  final User user;

  const RestaurantSelectionScreen({
    super.key,
    required this.user,
  });

  @override
  State<RestaurantSelectionScreen> createState() =>
      _RestaurantSelectionScreenState();
}

class _RestaurantSelectionScreenState
    extends State<RestaurantSelectionScreen> {
  final RestaurantProvider _restaurantProvider = RestaurantProvider();
  List<Restaurant> _restaurants = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _restaurantProvider.getRestaurantsByOwner(widget.user.id);
      setState(() {
        _restaurants = result.items ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _selectRestaurant(Restaurant restaurant) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MainLayout(restaurantId: restaurant.id),
      ),
    );
  }

  void _handleLogout() {
    AuthProvider.clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ScreenTitleHeader(
                      title: 'Select Restaurant',
                      subtitle: 'Choose a restaurant to manage',
                      icon: Icons.restaurant_rounded,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: _brownLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Welcome, ${widget.user.firstName} ${widget.user.lastName}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _handleLogout,
                    icon: Icon(Icons.logout, size: 18, color: Colors.red[700]),
                    label: Text(
                      'Logout',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              if (_isLoading)
                const CircularProgressIndicator()
              else if (_error != null)
                Column(
                  children: [
                    Text(
                      'Error: $_error',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadRestaurants,
                      child: const Text('Retry'),
                    ),
                  ],
                )
              else if (_restaurants.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'No restaurants found.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () async {
                            final created = await Navigator.push<Restaurant>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddRestaurantScreen(user: widget.user),
                              ),
                            );
                            if (created != null && mounted) {
                              _loadRestaurants();
                            }
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add your restaurant now'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF8B7355),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: _restaurants.length,
                          itemBuilder: (context, index) {
                      final restaurant = _restaurants[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () => _selectRestaurant(restaurant),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8B7355),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.restaurant,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        restaurant.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF4A4A4A),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        restaurant.address,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            size: 14,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            restaurant.cityName,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Icon(
                                            Icons.restaurant_menu,
                                            size: 14,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            restaurant.cuisineTypeName,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Color(0xFF8B7355),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                          ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final created = await Navigator.push<Restaurant>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddRestaurantScreen(user: widget.user),
                            ),
                          );
                          if (created != null && mounted) {
                            _loadRestaurants();
                          }
                        },
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('Add another restaurant'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF8B7355),
                          side: const BorderSide(color: Color(0xFF8B7355)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
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

