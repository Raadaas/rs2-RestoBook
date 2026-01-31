import 'dart:convert';
import 'package:ecommerce_mobile/model/restaurant.dart';
import 'package:ecommerce_mobile/model/cuisine_type.dart';
import 'package:ecommerce_mobile/providers/restaurant_provider.dart';
import 'package:ecommerce_mobile/providers/cuisine_type_provider.dart';
import 'package:ecommerce_mobile/providers/favorite_provider.dart';
import 'package:ecommerce_mobile/screens/restaurant_info_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Restaurant> _recentRestaurants = [];
  List<Restaurant> _searchResults = [];
  bool _isSearching = false;
  bool _showMap = false;
  bool _hasSearched = false; // Track if user has ever searched
  final MapController _mapController = MapController();

  // Filter state
  List<CuisineType> _cuisineTypes = [];
  double _minRating = 0.0;
  double _selectedMinRating = 0.0;
  Set<int> _selectedCuisineTypeIds = {};
  bool _filterHasParking = false;
  bool _filterHasTerrace = false;
  bool _filterIsKidFriendly = false;

  @override
  void initState() {
    super.initState();
    _loadRecentRestaurants();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFilterData();
      context.read<FavoriteProvider>().load();
    });
  }

  Future<void> _loadFilterData() async {
    try {
      // Load cuisine types
      final cuisineTypeProvider = context.read<CuisineTypeProvider>();
      final cuisineTypesResult = await cuisineTypeProvider.get(filter: {'isActive': true});
      final cuisineTypes = cuisineTypesResult.items ?? [];

    } catch (e) {
      print('Error loading filter data: $e');
    }
  }

  Future<void> _loadRecentRestaurants() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentJson = prefs.getStringList('recent_restaurants') ?? [];
      final restaurants = recentJson.map((json) => Restaurant.fromJson(jsonDecode(json))).toList();
      setState(() {
        _recentRestaurants = restaurants;
      });
    } catch (e) {
      print('Error loading recent restaurants: $e');
    }
  }

  Future<void> _saveRecentRestaurant(Restaurant restaurant) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentJson = prefs.getStringList('recent_restaurants') ?? [];
      
      // Remove if already exists
      recentJson.removeWhere((json) {
        final r = Restaurant.fromJson(jsonDecode(json));
        return r.id == restaurant.id;
      });
      
      // Add to beginning
      recentJson.insert(0, jsonEncode(restaurant.toJson()));
      
      // Keep only last 10
      if (recentJson.length > 10) {
        recentJson.removeRange(10, recentJson.length);
      }
      
      await prefs.setStringList('recent_restaurants', recentJson);
    } catch (e) {
      print('Error saving recent restaurant: $e');
    }
  }

  Future<void> _applyFilters() async {
    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      final provider = context.read<RestaurantProvider>();
      final query = _searchController.text.trim();

      // Build base filter
      Map<String, dynamic> filter = {
        'isActive': true,
      };

      // Add name search if exists
      if (query.isNotEmpty) {
        filter['name'] = query;
      }

      // Apply boolean filters
      if (_filterHasParking) {
        filter['hasParking'] = true;
      }
      if (_filterHasTerrace) {
        filter['hasTerrace'] = true;
      }
      if (_filterIsKidFriendly) {
        filter['isKidFriendly'] = true;
      }

      // For multiple cuisine types, we need to fetch all and filter on client side
      // since backend only supports single cuisineTypeId
      List<Restaurant> allResults = [];
      
      if (_selectedCuisineTypeIds.isNotEmpty) {
        // Fetch restaurants for each cuisine type
        for (int cuisineTypeId in _selectedCuisineTypeIds) {
          final cuisineFilter = Map<String, dynamic>.from(filter);
          cuisineFilter['cuisineTypeId'] = cuisineTypeId;
          final result = await provider.get(filter: cuisineFilter);
          allResults.addAll(result.items ?? []);
        }
        // Remove duplicates
        allResults = allResults.fold<List<Restaurant>>([], (list, restaurant) {
          if (!list.any((r) => r.id == restaurant.id)) {
            list.add(restaurant);
          }
          return list;
        });
      } else {
        // No cuisine type filter, fetch all
        final result = await provider.get(filter: filter);
        allResults = result.items ?? [];
      }

      // Apply client-side filters (rating)
      List<Restaurant> filtered = allResults.where((r) {
        // Filter by rating
        if (_selectedMinRating > 0 && (r.averageRating ?? 0) < _selectedMinRating) {
          return false;
        }
        return true;
      }).toList();

      setState(() {
        _searchResults = filtered;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error applying filters: $e')),
        );
      }
    }
  }

  Future<void> _searchRestaurants(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    // Use _applyFilters which will use the query from _searchController
    await _applyFilters();
  }

  Future<void> _loadAllRestaurantsForMap() async {
    try {
      final provider = context.read<RestaurantProvider>();
      final result = await provider.get(filter: {'isActive': true});
      
      setState(() {
        _searchResults = result.items?.where((r) => r.latitude != null && r.longitude != null).toList() ?? [];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading restaurants: $e')),
        );
      }
    }
  }

  void _showMapView() {
    if (!_showMap) {
      _loadAllRestaurantsForMap();
    }
    setState(() {
      _showMap = !_showMap;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search bar with filter
            _buildSearchBar(),
            // Results count and Map button
            if (!_showMap) _buildResultsHeader(),
            // Content (recent restaurants, search results, or map)
            Expanded(
              child: _showMap ? _buildMapView() : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search restaurants or cuisin',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: _searchRestaurants,
                onChanged: (value) {
                  if (value.isEmpty) {
                    setState(() {
                      _searchResults = [];
                      _isSearching = false;
                      _hasSearched = false; // Reset when all cleared
                    });
                  } else if (value.length >= 3) {
                    _hasSearched = true;
                    _searchRestaurants(value);
                  } else {
                    // If less than 3 characters, clear results but don't show recent
                    setState(() {
                      _searchResults = [];
                      _isSearching = false;
                      if (value.isNotEmpty) {
                        _hasSearched = true;
                      }
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _showFilterDialog(),
            icon: const Icon(Icons.filter_list),
            label: const Text('Filter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              side: BorderSide(color: Colors.grey[300]!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader() {
    final hasSearchQuery = _searchController.text.isNotEmpty;
    final count = _isSearching ? 0 : (_searchResults.isNotEmpty ? _searchResults.length : 0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _isSearching 
                ? 'Searching...' 
                : (_searchResults.isNotEmpty 
                    ? '$count restaurants found' 
                    : (hasSearchQuery && _searchController.text.length < 3
                        ? 'Type at least 3 characters to search'
                        : 'No restaurants')),
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          ElevatedButton.icon(
            onPressed: _showMapView,
            icon: const Icon(Icons.map, size: 18),
            label: const Text('Map'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              side: BorderSide(color: Colors.grey[300]!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasSearchQuery = _searchController.text.isNotEmpty;

    if (_searchResults.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) => _buildRestaurantCard(_searchResults[index]),
      );
    }

    // Show recent restaurants only if search is empty AND user hasn't searched yet
    if (!hasSearchQuery && !_hasSearched && _recentRestaurants.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Recent Restaurants',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _recentRestaurants.length,
              itemBuilder: (context, index) => _buildRestaurantCard(_recentRestaurants[index]),
            ),
          ),
        ],
      );
    }

    return const Center(
      child: Text(
        'No restaurants',
        style: TextStyle(fontSize: 16, color: Colors.grey),
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
            // Restaurant image placeholder
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

  Widget _buildMapView() {
    final restaurantsWithLocation = _searchResults.where((r) => r.latitude != null && r.longitude != null).toList();
    
    // Default location for Bosnia and Herzegovina (Sarajevo center)
    final defaultLocation = LatLng(43.8563, 18.4131);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: defaultLocation,
            initialZoom: 7.0, // Zoom out to show whole country
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.ecommerce_mobile',
            ),
            MarkerLayer(
              markers: restaurantsWithLocation.map((restaurant) {
                return Marker(
                  point: LatLng(restaurant.latitude!, restaurant.longitude!),
                  width: 30,
                  height: 30,
                  child: Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 30,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        Positioned(
          top: 8,
          right: 8,
          child: ElevatedButton.icon(
            onPressed: () => setState(() => _showMap = false),
            icon: const Icon(Icons.list),
            label: const Text('List'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
          ),
        ),
        // Zoom controls
        Positioned(
          bottom: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
                      },
                      icon: const Icon(Icons.add),
                      tooltip: 'Zoom in',
                    ),
                    Container(
                      height: 1,
                      color: Colors.grey[300],
                    ),
                    IconButton(
                      onPressed: () {
                        _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
                      },
                      icon: const Icon(Icons.remove),
                      tooltip: 'Zoom out',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showFilterDialog() {
    // Temporary state for dialog
    double tempMinRating = _selectedMinRating;
    Set<int> tempCuisineTypeIds = Set<int>.from(_selectedCuisineTypeIds);
    bool tempHasParking = _filterHasParking;
    bool tempHasTerrace = _filterHasTerrace;
    bool tempIsKidFriendly = _filterIsKidFriendly;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.85,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cuisine Type
                        const Text(
                          'Cuisine Type',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ..._cuisineTypes.map((cuisineType) {
                          final emojiMap = {
                            'Italian': '🍕',
                            'Japanese': '🍜',
                            'Balkan': '🥩',
                            'American': '🍔',
                            'Seafood': '🦞',
                            'Vegetarian': '🥗',
                          };
                          final emoji = emojiMap[cuisineType.name] ?? '🍽️';
                          
                          return CheckboxListTile(
                            title: Row(
                              children: [
                                Text(emoji, style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: 8),
                                Text(cuisineType.name),
                              ],
                            ),
                            value: tempCuisineTypeIds.contains(cuisineType.id),
                            onChanged: (value) {
                              setDialogState(() {
                                if (value == true) {
                                  tempCuisineTypeIds.add(cuisineType.id);
                                } else {
                                  tempCuisineTypeIds.remove(cuisineType.id);
                                }
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                          );
                        }),
                        const SizedBox(height: 24),
                        // Minimum Rating
                        const Text(
                          'Minimum Rating',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Slider(
                          value: tempMinRating,
                          min: 0.0,
                          max: 5.0,
                          divisions: 50,
                          label: tempMinRating.toStringAsFixed(1),
                          onChanged: (value) {
                            setDialogState(() {
                              tempMinRating = value;
                            });
                          },
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              '${tempMinRating.toStringAsFixed(1)} and above',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Special Features
                        const Text(
                          'Special Features',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        CheckboxListTile(
                          title: const Row(
                            children: [
                              Text('👥', style: TextStyle(fontSize: 20)),
                              SizedBox(width: 8),
                              Text('Kid Friendly'),
                            ],
                          ),
                          value: tempIsKidFriendly,
                          onChanged: (value) {
                            setDialogState(() {
                              tempIsKidFriendly = value ?? false;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                        CheckboxListTile(
                          title: const Row(
                            children: [
                              Text('🚗', style: TextStyle(fontSize: 20)),
                              SizedBox(width: 8),
                              Text('Parking'),
                            ],
                          ),
                          value: tempHasParking,
                          onChanged: (value) {
                            setDialogState(() {
                              tempHasParking = value ?? false;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                        CheckboxListTile(
                          title: const Row(
                            children: [
                              Text('🌳', style: TextStyle(fontSize: 20)),
                              SizedBox(width: 8),
                              Text('Terrace'),
                            ],
                          ),
                          value: tempHasTerrace,
                          onChanged: (value) {
                            setDialogState(() {
                              tempHasTerrace = value ?? false;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        setDialogState(() {
                          tempMinRating = 0.0;
                          tempCuisineTypeIds.clear();
                          tempHasParking = false;
                          tempHasTerrace = false;
                          tempIsKidFriendly = false;
                        });
                      },
                      child: const Text('Clear All'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedMinRating = tempMinRating;
                          _selectedCuisineTypeIds = tempCuisineTypeIds;
                          _filterHasParking = tempHasParking;
                          _filterHasTerrace = tempHasTerrace;
                          _filterIsKidFriendly = tempIsKidFriendly;
                        });
                        Navigator.pop(context);
                        // Apply filters and show results
                        _applyFilters();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B7355),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Apply Filters'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
