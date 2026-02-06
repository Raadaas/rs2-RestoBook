import 'dart:convert';
import 'package:ecommerce_mobile/app_styles.dart';
import 'package:ecommerce_mobile/model/restaurant.dart';
import 'package:ecommerce_mobile/providers/restaurant_provider.dart';
import 'package:ecommerce_mobile/providers/favorite_provider.dart';
import 'package:ecommerce_mobile/screens/restaurant_info_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Restaurant> _recommended = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecommended();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoriteProvider>().load();
    });
  }

  Future<void> _loadRecommended() async {
    setState(() => _loading = true);
    try {
      final list = await context.read<RestaurantProvider>().getRecommended(count: 10);
      if (mounted) {
        setState(() {
          _recommended = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _recommended = [];
          _loading = false;
        });
      }
    }
  }

  Future<void> _saveRecentRestaurant(Restaurant restaurant) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentJson = prefs.getStringList('recent_restaurants') ?? [];
      recentJson.removeWhere((json) {
        final r = Restaurant.fromJson(jsonDecode(json) as Map<String, dynamic>);
        return r.id == restaurant.id;
      });
      recentJson.insert(0, jsonEncode(restaurant.toJson()));
      if (recentJson.length > 10) {
        recentJson.removeRange(10, recentJson.length);
      }
      await prefs.setStringList('recent_restaurants', recentJson);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadRecommended,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'For You',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      kScreenTitleUnderline(margin: EdgeInsets.zero),
                    ],
                  ),
                ),
              ),
              if (_loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_recommended.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No recommendations yet.\nLog in and book some restaurants to get personalized suggestions.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildRestaurantCard(_recommended[index]),
                      childCount: _recommended.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantCard(Restaurant restaurant) {
    final rating = restaurant.averageRating ?? 0.0;
    final reviews = restaurant.totalReviews;
    final fav = context.watch<FavoriteProvider>();
    final isFav = fav.ids.contains(restaurant.id);

    return GestureDetector(
      onTap: () async {
        await _saveRecentRestaurant(restaurant);
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RestaurantInfoScreen(restaurantId: restaurant.id),
            ),
          );
        }
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
                        Icon(Icons.star, color: Colors.amber[700], size: 16),
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
                  await context.read<FavoriteProvider>().toggle(restaurant.id);
                  if (mounted) setState(() {});
                },
                child: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.red : Colors.grey[400],
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
