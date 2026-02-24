import 'package:ecommerce_mobile/providers/auth_provider.dart';
import 'package:ecommerce_mobile/screens/login_page.dart';
import 'package:ecommerce_mobile/providers/favorite_provider.dart';
import 'package:ecommerce_mobile/providers/loyalty_provider.dart';
import 'package:ecommerce_mobile/providers/notification_provider.dart';
import 'package:ecommerce_mobile/providers/review_provider.dart';
import 'package:ecommerce_mobile/screens/favorite_restaurants_screen.dart';
import 'package:ecommerce_mobile/screens/my_reviews_screen.dart';
import 'package:ecommerce_mobile/screens/loyalty_rewards_screen.dart';
import 'package:ecommerce_mobile/screens/help_support_screen.dart';
import 'package:ecommerce_mobile/screens/notifications_screen.dart';
import 'package:ecommerce_mobile/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final LoyaltyProvider _loyaltyProvider = LoyaltyProvider();
  int _currentPoints = 0;
  int _favoriteCount = 0;
  int _reviewCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading) setState(() => _loading = true);
    context.read<NotificationProvider>().load();
    final pts = await _loyaltyProvider.getMyPoints();
    final fav = context.read<FavoriteProvider>();
    if (!fav.isLoaded) await fav.load();
    int reviewCount = 0;
    try {
      final list = await context.read<ReviewProvider>().getMyReviews();
      reviewCount = list.length;
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _currentPoints = pts.currentPoints;
      _favoriteCount = fav.count;
      _reviewCount = reviewCount;
      _loading = false;
    });
  }

  Future<void> _onRefresh() => _load(showLoading: false);

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _onRefresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Loyalty points card
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF8B7355),
                                Color.lerp(const Color(0xFF8B7355), Colors.white, 0.45)!,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B7355).withOpacity(0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.stars_rounded,
                                  size: 32,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$_currentPoints',
                                      style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: -0.5,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Points',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withOpacity(0.9),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Claim your rewards',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.white.withOpacity(0.85),
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _listTile(
                          icon: Icons.notifications_outlined,
                          label: 'Notifications',
                          count: context.watch<NotificationProvider>().unreadCount > 0 ? context.watch<NotificationProvider>().unreadCount : null,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationsScreen(),
                              ),
                            );
                            _load(showLoading: false);
                          },
                        ),
                        _listTile(
                          icon: Icons.favorite_border,
                          label: 'Favorite Restaurants',
                          count: _favoriteCount,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const FavoriteRestaurantsScreen(),
                              ),
                            );
                            _load(showLoading: false);
                          },
                        ),
                        _listTile(
                          icon: Icons.star_border,
                          label: 'Reviews',
                          count: _reviewCount,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MyReviewsScreen(),
                              ),
                            );
                            _load(showLoading: false);
                          },
                        ),
                        _listTile(
                          icon: Icons.card_giftcard,
                          label: 'Loyalty Rewards',
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoyaltyRewardsScreen(),
                              ),
                            );
                            _load(showLoading: false);
                          },
                        ),
                        _listTile(
                          icon: Icons.settings,
                          label: 'Settings',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SettingsScreen(),
                              ),
                            );
                          },
                        ),
                        _listTile(
                          icon: Icons.help_outline,
                          label: 'Help & Support',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HelpSupportScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          leading: Icon(Icons.logout, color: Colors.red[700], size: 26),
                          title: Text(
                            'Log Out',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.red[700],
                              fontSize: 16,
                            ),
                          ),
                          onTap: () {
                            AuthProvider.clear();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => LoginPage()),
                              (_) => false,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _listTile({
    required IconData icon,
    required String label,
    int? count,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Icon(icon, color: const Color(0xFF8B7355), size: 26),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (count != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
              ),
            ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[600]),
        ],
      ),
      onTap: onTap,
    );
  }
}
