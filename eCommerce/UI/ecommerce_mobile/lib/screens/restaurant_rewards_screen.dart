import 'package:ecommerce_mobile/model/reward.dart';
import 'package:ecommerce_mobile/model/restaurant.dart';
import 'package:ecommerce_mobile/providers/loyalty_provider.dart';
import 'package:flutter/material.dart';

class RestaurantRewardsScreen extends StatefulWidget {
  final Restaurant restaurant;

  const RestaurantRewardsScreen({
    super.key,
    required this.restaurant,
  });

  @override
  State<RestaurantRewardsScreen> createState() => _RestaurantRewardsScreenState();
}

class _RestaurantRewardsScreenState extends State<RestaurantRewardsScreen> {
  final LoyaltyProvider _loyaltyProvider = LoyaltyProvider();
  List<Reward> _rewards = [];
  bool _loading = true;
  String? _error;
  bool _redeeming = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRewards());
  }

  Future<void> _loadRewards() async {
    setState(() { _loading = true; _error = null; });
    try {
      final rewards = await _loyaltyProvider.getAvailableRewards(widget.restaurant.id);
      if (!mounted) return;
      setState(() {
        _rewards = rewards;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _redeemReward(Reward reward) async {
    if (!reward.canRedeem || _redeeming) return;
    setState(() => _redeeming = true);
    try {
      final success = await _loyaltyProvider.redeemReward(reward.id);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully redeemed: ${reward.title}'),
            backgroundColor: Colors.green,
          ),
        );
        _loadRewards();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to redeem reward'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to redeem reward'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _redeeming = false);
    }
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
                    widget.restaurant.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Loyalty Rewards',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _error!,
                                  style: TextStyle(color: Colors.red[700]),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadRewards,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _rewards.isEmpty
                          ? Center(
                              child: Text(
                                'No rewards available at this restaurant.',
                                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadRewards,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: _rewards.length,
                                itemBuilder: (context, i) => _buildRewardCard(_rewards[i]),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardCard(Reward reward) {
    final canRedeem = reward.canRedeem && !_redeeming;
    final buttonText = canRedeem ? 'Redeem Reward' : 'Earn More Points';
    final buttonColor = canRedeem
        ? const Color(0xFF8B7355)
        : const Color(0xFF8B7355).withOpacity(0.5);
    final textColor = canRedeem ? Colors.white : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reward.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (reward.description != null && reward.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        reward.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B7355).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${reward.pointsRequired} pts',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8B7355),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canRedeem ? () => _redeemReward(reward) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: textColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }
}
