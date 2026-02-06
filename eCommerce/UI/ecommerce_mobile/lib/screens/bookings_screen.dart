import 'package:ecommerce_mobile/app_styles.dart';
import 'package:ecommerce_mobile/screens/modify_reservation_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_mobile/providers/reservation_provider.dart';
import 'package:ecommerce_mobile/model/reservation.dart';
import 'package:ecommerce_mobile/providers/restaurant_provider.dart';
import 'package:ecommerce_mobile/model/restaurant.dart';
import 'package:intl/intl.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Reservation> _allReservations = [];
  List<Reservation> _upcomingReservations = [];
  List<Reservation> _pastReservations = [];
  List<Reservation> _cancelledReservations = [];
  bool _isLoading = true;
  Map<int, Restaurant?> _restaurantCache = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReservations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReservations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Loading reservations...');
      final provider = Provider.of<ReservationProvider>(context, listen: false);
      final reservations = await provider.getMyReservations();
      print('Loaded ${reservations.length} reservations');

      // Debug: print all reservation statuses
      for (var r in reservations) {
        print('Reservation ${r.id}: status=${r.status}, date=${r.reservationDate}, isPast=${r.isPast}');
      }

      // Separate into upcoming, past, and cancelled/expired
      final now = DateTime.now();
      final upcoming = <Reservation>[];
      final past = <Reservation>[];
      final cancelled = <Reservation>[];

      for (var reservation in reservations) {
        if (reservation.status == 'Cancelled' || reservation.status == 'Expired') {
          cancelled.add(reservation);
        } else if (reservation.status == 'Requested' || reservation.status == 'Confirmed') {
          if (!reservation.isPast) {
            upcoming.add(reservation);
          } else {
            // If it's past but still Requested/Confirmed, move to past
            past.add(reservation);
          }
        } else if (reservation.status == 'Completed') {
          past.add(reservation);
        }
      }

      // Sort upcoming by date (earliest first)
      upcoming.sort((a, b) => a.reservationDate.compareTo(b.reservationDate));
      
      // Sort past by date (latest first)
      past.sort((a, b) => b.reservationDate.compareTo(a.reservationDate));
      
      // Sort cancelled/expired by date (latest first)
      cancelled.sort((a, b) => b.reservationDate.compareTo(a.reservationDate));

      setState(() {
        _allReservations = reservations; // Keep all reservations for restaurant info loading
        _upcomingReservations = upcoming;
        _pastReservations = past;
        _cancelledReservations = cancelled;
        _isLoading = false;
      });

      // Load restaurant info for all reservations
      await _loadRestaurantInfo();
    } catch (e, stackTrace) {
      print('Error in _loadReservations: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading reservations: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _loadRestaurantInfo() async {
    final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
    final restaurantIds = _allReservations.map((r) => r.restaurantId).toSet();

    for (var restaurantId in restaurantIds) {
      if (!_restaurantCache.containsKey(restaurantId)) {
        try {
          final restaurant = await restaurantProvider.getById(restaurantId);
          setState(() {
            _restaurantCache[restaurantId] = restaurant;
          });
        } catch (e) {
          print('Error loading restaurant $restaurantId: $e');
        }
      }
    }
  }

  Future<void> _cancelReservation(Reservation reservation) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Reservation'),
        content: const Text('Are you sure you want to cancel this reservation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final provider = Provider.of<ReservationProvider>(context, listen: false);
        await provider.cancelReservation(reservation.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reservation cancelled successfully')),
          );
          _loadReservations();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error cancelling reservation: $e')),
          );
        }
      }
    }
  }

  void _editReservation(Reservation reservation) {
    if (reservation.status != 'Requested') return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModifyReservationScreen(reservation: reservation),
      ),
    ).then((_) => _loadReservations());
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'Requested':
        return 'Requested';
      case 'Confirmed':
        return 'Confirmed';
      case 'Completed':
        return 'Completed';
      case 'Cancelled':
        return 'Cancelled';
      case 'Expired':
        return 'Expired';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Requested':
        return Colors.orange;
      case 'Confirmed':
        return Colors.green;
      case 'Completed':
        return Colors.blue;
      case 'Cancelled':
        return Colors.red;
      case 'Expired':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('My Reservations', style: kScreenTitleStyle),
                  const SizedBox(height: 8),
                  kScreenTitleUnderline(margin: EdgeInsets.zero),
                ],
              ),
            ),
            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF8B7355),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF8B7355),
              tabs: const [
                Tab(text: 'Upcoming'),
                Tab(text: 'Past'),
                Tab(text: 'Cancelled'),
              ],
            ),
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildUpcomingTab(),
                        _buildPastTab(),
                        _buildCancelledTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingTab() {
    if (_upcomingReservations.isEmpty) {
      return const Center(
        child: Text(
          'No upcoming reservations',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReservations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _upcomingReservations.length,
        itemBuilder: (context, index) {
          final reservation = _upcomingReservations[index];
          return _buildReservationCard(reservation);
        },
      ),
    );
  }

  Widget _buildPastTab() {
    if (_pastReservations.isEmpty) {
      return const Center(
        child: Text(
          'No past reservations',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReservations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pastReservations.length,
        itemBuilder: (context, index) {
          final reservation = _pastReservations[index];
          return _buildReservationCard(reservation);
        },
      ),
    );
  }

  Widget _buildCancelledTab() {
    if (_cancelledReservations.isEmpty) {
      return const Center(
        child: Text(
          'No cancelled or expired reservations',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReservations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _cancelledReservations.length,
        itemBuilder: (context, index) {
          final reservation = _cancelledReservations[index];
          return _buildReservationCard(reservation);
        },
      ),
    );
  }

  Widget _buildReservationCard(Reservation reservation) {
    final restaurant = _restaurantCache[reservation.restaurantId];
    final statusColor = _getStatusColor(reservation.status);
    final statusText = _getStatusText(reservation.status);

    // Parse time
    final timeParts = reservation.reservationTime.split(':');
    final time = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    // Format date
    final dateFormat = DateFormat('MMM d, yyyy');
    final formattedDate = dateFormat.format(reservation.reservationDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant image and name row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Restaurant image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                    child: Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: Icon(Icons.restaurant, size: 40, color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(width: 12),
                // Restaurant name and status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reservation.restaurantName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      if (restaurant != null)
                        Text(
                          restaurant.cuisineTypeName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Reservation details
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(formattedDate, style: TextStyle(color: Colors.grey[700])),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  time.format(context),
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '${reservation.numberOfGuests} guests • Table ${reservation.tableNumber}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
            if (restaurant != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      restaurant.address,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
              if (restaurant.phoneNumber != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      restaurant.phoneNumber!,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ],
            ],
            const SizedBox(height: 16),
            // Action buttons
            if (reservation.status == 'Requested' || reservation.status == 'Confirmed') ...[
              Row(
                children: [
                  if (reservation.status == 'Requested')
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _editReservation(reservation),
                        child: const Text('Modify'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  if (reservation.status == 'Requested') const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelReservation(reservation),
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (reservation.status == 'Cancelled' || reservation.status == 'Expired') ...[
              // Show cancellation reason if available
              if (reservation.status == 'Cancelled' && reservation.cancellationReason != null && reservation.cancellationReason!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 20, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cancellation Reason:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              reservation.cancellationReason!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.red[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
