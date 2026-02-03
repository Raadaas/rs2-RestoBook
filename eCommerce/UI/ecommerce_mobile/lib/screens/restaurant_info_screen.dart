import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_mobile/model/restaurant.dart';
import 'package:ecommerce_mobile/model/restaurant_gallery_item.dart';
import 'package:ecommerce_mobile/model/menu_item.dart';
import 'package:ecommerce_mobile/providers/restaurant_provider.dart';
import 'package:ecommerce_mobile/providers/restaurant_gallery_provider.dart';
import 'package:ecommerce_mobile/providers/favorite_provider.dart';
import 'package:ecommerce_mobile/providers/menu_item_provider.dart';
import 'package:ecommerce_mobile/providers/review_provider.dart';
import 'package:ecommerce_mobile/providers/reservation_provider.dart';
import 'package:ecommerce_mobile/providers/auth_provider.dart';
import 'package:ecommerce_mobile/model/review.dart';
import 'package:ecommerce_mobile/model/reservation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:ecommerce_mobile/screens/book_reservation_screen.dart';

const Color _brown = Color(0xFF8B7355);

class RestaurantInfoScreen extends StatefulWidget {
  final int restaurantId;

  const RestaurantInfoScreen({
    super.key,
    required this.restaurantId,
  });

  @override
  State<RestaurantInfoScreen> createState() => _RestaurantInfoScreenState();
}

class _RestaurantInfoScreenState extends State<RestaurantInfoScreen> {
  Restaurant? _restaurant;
  List<RestaurantGalleryItem> _galleryImages = [];
  List<MenuItem> _menuItems = [];
  List<Review> _reviews = [];
  bool _loading = true;
  bool _menuLoading = false;
  bool _reviewsLoading = false;
  int _reviewRating = 0;
  final TextEditingController _reviewCommentController = TextEditingController();
  bool _reviewSubmitting = false;
  String? _error;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final Set<String> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _reviewCommentController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final restaurantProvider = context.read<RestaurantProvider>();
      final galleryProvider = context.read<RestaurantGalleryProvider>();
      final favProvider = context.read<FavoriteProvider>();
      if (!favProvider.isLoaded) await favProvider.load();

      final results = await Future.wait([
        restaurantProvider.getById(widget.restaurantId),
        galleryProvider.getByRestaurant(widget.restaurantId),
      ]);

      if (!mounted) return;
      final restaurant = results[0] as Restaurant?;
      final gallery = results[1] as List<RestaurantGalleryItem>;

      if (restaurant == null) {
        setState(() {
          _error = 'Restaurant not found';
          _loading = false;
        });
        return;
      }

      setState(() {
        _restaurant = restaurant;
        _galleryImages = gallery;
        _loading = false;
      });
      _loadMenuItems();
      _loadReviews();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadMenuItems() async {
    setState(() => _menuLoading = true);
    try {
      final result = await context.read<MenuItemProvider>().get(
        filter: {'restaurantId': widget.restaurantId},
      );
      if (mounted) {
        setState(() {
          _menuItems = result.items ?? [];
          _menuLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _menuItems = [];
          _menuLoading = false;
        });
      }
    }
  }

  String _getCategoryDisplayName(int? category) {
    if (category == null) return 'Uncategorized';
    switch (category) {
      case 0: return 'Appetizer';
      case 1: return 'Mains';
      case 2: return 'Desserts';
      case 3: return 'Beverages';
      case 4: return 'Starters';
      case 5: return 'Soup';
      case 6: return 'Side Dish';
      case 7: return 'Breakfast';
      case 8: return 'Lunch';
      case 9: return 'Dinner';
      default: return 'Uncategorized';
    }
  }

  Future<void> _loadReviews() async {
    setState(() => _reviewsLoading = true);
    try {
      final result = await context.read<ReviewProvider>().getByRestaurant(widget.restaurantId);
      if (mounted) {
        setState(() {
          _reviews = result;
          _reviewsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _reviews = [];
          _reviewsLoading = false;
        });
      }
    }
  }

  String _timeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()} years ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} months ago';
    if (diff.inDays > 0) return '${diff.inDays} days ago';
    if (diff.inHours > 0) return '${diff.inHours} hours ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} minutes ago';
    return 'Just now';
  }

  String _formatTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
      }
    } catch (_) {}
    return timeStr;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.lerp(Colors.grey[100], _brown, 0.03) ?? Colors.grey[100],
      body: _loading
          ? Center(child: CircularProgressIndicator(color: _brown))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _brown,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _restaurant == null
                  ? const Center(child: Text('Restaurant not found'))
                  : Column(
                      children: [
                        Expanded(
                          child: CustomScrollView(
                            slivers: [
                              _buildGallerySliver(),
                              SliverToBoxAdapter(
                                child: _buildDetailsCard(),
                              ),
                              const SliverToBoxAdapter(
                                child: SizedBox(height: 100),
                              ),
                            ],
                          ),
                        ),
                        SafeArea(
                          top: false,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, -2),
                                ),
                              ],
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BookReservationScreen(
                                        restaurantId: widget.restaurantId,
                                        restaurantName: _restaurant!.name,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _brown,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text('BOOK NOW'),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildGallerySliver() {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: false,
      backgroundColor: Colors.black87,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: _brown.withOpacity(0.2), width: 1),
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back, color: _brown.withOpacity(0.9)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Consumer<FavoriteProvider>(
          builder: (context, fav, _) {
            return FutureBuilder<bool>(
              future: fav.contains(widget.restaurantId),
              builder: (context, snapshot) {
                final isFav = snapshot.data ?? false;
                return Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: _brown.withOpacity(0.2), width: 1),
                  ),
                  child: IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? Colors.red : _brown.withOpacity(0.8),
                    ),
                    onPressed: () async {
                      await fav.toggle(widget.restaurantId);
                      setState(() {});
                    },
                  ),
                );
              },
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _galleryImages.isEmpty
            ? _buildPlaceholderImage()
            : _buildImageCarousel(),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Icon(Icons.restaurant, size: 80, color: Colors.grey[500]),
      ),
    );
  }

  Widget _buildImageCarousel() {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) => setState(() => _currentPage = index),
          itemCount: _galleryImages.length,
          itemBuilder: (context, index) => _buildGalleryImage(_galleryImages[index]),
        ),
        if (_galleryImages.length > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _galleryImages.length,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _currentPage
                        ? Colors.white
                        : Color.lerp(Colors.white, _brown, 0.25)!.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGalleryImage(RestaurantGalleryItem item) {
    return item.imageUrl.startsWith('data:image/')
        ? Image.memory(
            base64Decode(item.imageUrl.split(',')[1]),
            fit: BoxFit.cover,
          )
        : Image.network(
            item.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey[300],
              child: Icon(Icons.broken_image, size: 64, color: Colors.grey[500]),
            ),
          );
  }

  Widget _buildDetailsCard() {
    final r = _restaurant!;
    final rating = r.averageRating ?? 0.0;

    return Transform.translate(
      offset: const Offset(0, -24),
      child: Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              r.name,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber[700], size: 22),
                const SizedBox(width: 6),
                Text(
                  '${rating.toStringAsFixed(1)} (${r.totalReviews} reviews)',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _brown.withOpacity(0.08),
                    border: Border.all(color: _brown.withOpacity(0.25), width: 1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    r.cuisineTypeName,
                    style: TextStyle(
                      fontSize: 14,
                      color: _brown.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (r.description != null && r.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                r.description!,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (r.hasParking) _buildTag('Parking', Icons.local_parking),
                if (r.hasTerrace) _buildTag('Outdoor Seating', Icons.deck),
                if (r.isKidFriendly) _buildTag('Kid Friendly', Icons.child_care),
              ],
            ),
            const SizedBox(height: 24),
            Divider(height: 1, color: _brown.withOpacity(0.15), thickness: 1),
            const SizedBox(height: 16),
            _buildContactItem(Icons.location_on, 'Address',
              '${r.address}, ${r.cityName}',
            ),
            if (r.phoneNumber != null && r.phoneNumber!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildContactItem(Icons.phone, 'Phone', r.phoneNumber!),
            ],
            if (r.email != null && r.email!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildContactItem(Icons.email, 'Email', r.email!),
            ],
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.access_time, color: _brown.withOpacity(0.7), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Working Hours',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mon-Sun ${_formatTime(r.openTime)} - ${_formatTime(r.closeTime)}',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            DefaultTabController(
              length: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _brown.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _brown.withOpacity(0.12), width: 1),
                    ),
                    child: TabBar(
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: _brown.withOpacity(0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: _brown.withOpacity(0.95),
                      unselectedLabelColor: Colors.grey[600],
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      tabs: const [
                        Tab(text: 'Menu'),
                        Tab(text: 'Reviews'),
                        Tab(text: 'Location'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 400,
                    child: TabBarView(
                      children: [
                        _buildMenuTab(),
                        _buildReviewsTab(),
                        _buildLocationTab(),
                      ],
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

  Widget _buildLocationTab() {
    final r = _restaurant;
    if (r == null) return const Center(child: CircularProgressIndicator());
    if (r.latitude == null || r.longitude == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, size: 48, color: _brown.withOpacity(0.4)),
              const SizedBox(height: 16),
              Text(
                'Location not available',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              if (r.address.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  r.address,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      );
    }
    final restaurantLocation = LatLng(r.latitude!, r.longitude!);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: restaurantLocation,
          initialZoom: 15.0,
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
            markers: [
              Marker(
                point: restaurantLocation,
                width: 40,
                height: 40,
                child: Icon(
                  Icons.location_on,
                  color: _brown,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderTab(String text) {
    return Center(
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildReviewsTab() {
    final isLoggedIn = AuthProvider.userId != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Leave a Review form
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Leave a Review',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: List.generate(5, (i) {
                    final star = i + 1;
                    return IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: isLoggedIn
                          ? () => setState(() => _reviewRating = star)
                          : null,
                      icon: Icon(
                        star <= _reviewRating ? Icons.star : Icons.star_border,
                        color: star <= _reviewRating ? Colors.amber[700] : Colors.grey[400],
                        size: 32,
                      ),
                    );
                  }),
                ),
                Text(
                  _reviewRating == 0 ? 'Select rating' : '$_reviewRating star${_reviewRating > 1 ? 's' : ''}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _reviewCommentController,
                  enabled: isLoggedIn,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Share your experience...',
                    hintStyle: TextStyle(color: _brown.withOpacity(0.4)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: _brown.withOpacity(0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: _brown.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: _brown, width: 1.5),
                    ),
                    filled: true,
                    fillColor: _brown.withOpacity(0.03),
                  ),
                ),
                if (!isLoggedIn)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Log in to leave a review',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoggedIn && !_reviewSubmitting
                        ? _submitReview
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brown,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _reviewSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Submit Review'),
                  ),
                ),
              ],
            ),
          ),
          // Existing reviews
          if (_reviewsLoading)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(color: _brown)),
            )
          else if (_reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No reviews yet. Be the first to share your experience!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              ),
            )
          else
            ..._reviews.map((r) => _buildReviewCard(r)),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Review r) {
    final initials = r.userName.isNotEmpty
        ? r.userName.split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join().toUpperCase()
        : '?';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _brown.withOpacity(0.25),
                child: Text(
                  initials,
                  style: TextStyle(
                    color: _brown,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            r.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Color(0xFF2D2D2D),
                            ),
                          ),
                        ),
                        Text(
                          _timeAgo(r.createdAt),
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < r.rating ? Icons.star : Icons.star_border,
                          size: 18,
                          color: i < r.rating ? Colors.amber[700] : Colors.grey[400],
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (r.comment != null && r.comment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              r.comment!,
              style: TextStyle(fontSize: 15, color: Colors.grey[800], height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _submitReview() async {
    if (_reviewRating < 1 || _reviewRating > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }
    final userId = AuthProvider.userId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to leave a review')),
      );
      return;
    }
    setState(() => _reviewSubmitting = true);
    try {
      final reservationProvider = context.read<ReservationProvider>();
      final allReservations = await reservationProvider.getMyReservations();
      final restaurantReservations = allReservations
          .where((r) => r.restaurantId == widget.restaurantId)
          .where((r) => r.status == 'Completed' || r.status == 'Confirmed')
          .toList()
        ..sort((a, b) => b.reservationDate.compareTo(a.reservationDate));

      final reviewedIds = _reviews.map((r) => r.reservationId).toSet();
      final eligible = restaurantReservations
          .where((r) => !reviewedIds.contains(r.id))
          .toList();

      if (eligible.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You need to have a completed reservation at this restaurant to leave a review'),
          ),
        );
        setState(() => _reviewSubmitting = false);
        return;
      }

      final reservation = eligible.first;
      await context.read<ReviewProvider>().createReview(
        reservationId: reservation.id,
        userId: userId,
        restaurantId: widget.restaurantId,
        rating: _reviewRating,
        comment: _reviewCommentController.text.trim().isEmpty
            ? null
            : _reviewCommentController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _reviewSubmitting = false;
        _reviewRating = 0;
        _reviewCommentController.clear();
      });
      await _loadReviews();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _reviewSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildMenuTab() {
    if (_menuLoading) {
      return Center(child: CircularProgressIndicator(color: _brown));
    }
    if (_menuItems.isEmpty) {
      return Center(
        child: Text(
          'No menu items',
          style: TextStyle(fontSize: 15, color: Colors.grey[600]),
        ),
      );
    }
    final itemsByCategory = <String, List<MenuItem>>{};
    for (final item in _menuItems) {
      final cat = _getCategoryDisplayName(item.category);
      itemsByCategory.putIfAbsent(cat, () => []).add(item);
    }
    final sortedCategories = itemsByCategory.keys.toList()
      ..sort((a, b) => a.compareTo(b));
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final category = sortedCategories[index];
        final items = itemsByCategory[category]!;
        final isExpanded = _expandedCategories.contains(category);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedCategories.remove(category);
                  } else {
                    _expandedCategories.add(category);
                  }
                });
              },
              child: Padding(
                padding: EdgeInsets.only(
                  top: index == 0 ? 0 : 16,
                  bottom: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 20,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: _brown.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _brown.withOpacity(0.9),
                        ),
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: _brown.withOpacity(0.7),
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded) ...items.map((item) => _buildMenuItemRow(item)),
          ],
        );
      },
    );
  }

  Widget _buildMenuItemRow(MenuItem item) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _brown.withOpacity(0.12), width: 1),
        ),
      ),
      child: ListTile(
        title: Text(
          item.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: _brown.withOpacity(0.9),
          ),
        ),
        trailing: Text(
          '\$${item.price.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _brown.withOpacity(0.9),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _brown.withOpacity(0.06),
        border: Border.all(color: _brown.withOpacity(0.2), width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: _brown.withOpacity(0.8)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: _brown.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _brown.withOpacity(0.7), size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
