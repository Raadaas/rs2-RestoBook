import 'package:ecommerce_mobile/model/restaurant.dart';
import 'package:ecommerce_mobile/providers/favorite_provider.dart';
import 'package:ecommerce_mobile/providers/restaurant_provider.dart';
import 'package:ecommerce_mobile/screens/restaurant_info_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FavoriteRestaurantsScreen extends StatefulWidget {
  const FavoriteRestaurantsScreen({super.key});

  @override
  State<FavoriteRestaurantsScreen> createState() => _FavoriteRestaurantsScreenState();
}

class _FavoriteRestaurantsScreenState extends State<FavoriteRestaurantsScreen> {
  List<Restaurant> _restaurants = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool showLoading = true}) async {
    final fav = context.read<FavoriteProvider>();
    if (!fav.isLoaded) await fav.load();
    if (showLoading) setState(() { _loading = true; _error = null; });
    final ids = fav.ids;
    if (ids.isEmpty) {
      setState(() { _restaurants = []; _loading = false; });
      return;
    }
    final List<Restaurant> list = [];
    final restaurantProvider = context.read<RestaurantProvider>();
    for (final id in ids) {
      try {
        final r = await restaurantProvider.getById(id);
        if (r != null) list.add(r);
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() { _restaurants = list; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Favorite Restaurants',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!, style: TextStyle(color: Colors.red[700])))
                      : _restaurants.isEmpty
                          ? Center(
                              child: Text(
                                'No favorite restaurants yet.',
                                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () => _load(showLoading: false),
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                itemCount: _restaurants.length,
                                itemBuilder: (context, i) => _buildRestaurantCard(_restaurants[i]),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantCard(Restaurant restaurant) {
    final rating = restaurant.averageRating ?? 0.0;
    final reviews = restaurant.totalReviews;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantInfoScreen(restaurantId: restaurant.id),
          ),
        );
        if (mounted) _load(showLoading: false);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: Icon(Icons.restaurant, color: Colors.grey[600], size: 40),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${rating.toStringAsFixed(1)} ($reviews)',
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${restaurant.cuisineTypeName} • ${restaurant.cityName}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () async {
                  await context.read<FavoriteProvider>().remove(restaurant.id);
                  if (mounted) _load(showLoading: false);
                },
                child: const Icon(
                  Icons.favorite,
                  color: Colors.red,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
