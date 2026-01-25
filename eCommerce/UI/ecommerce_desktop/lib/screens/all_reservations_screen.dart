import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_desktop/providers/dashboard_provider.dart';
import 'package:ecommerce_desktop/services/dashboard_service.dart';
import 'package:ecommerce_desktop/models/reservation_model.dart';
import 'package:intl/intl.dart';

class AllReservationsScreen extends StatefulWidget {
  final int restaurantId;

  const AllReservationsScreen({
    super.key,
    required this.restaurantId,
  });

  @override
  State<AllReservationsScreen> createState() => _AllReservationsScreenState();
}

class _AllReservationsScreenState extends State<AllReservationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, List<Reservation>> _reservationsByState = {};
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
      _error = null;
    });

    try {
      final states = ['Pending', 'Confirmed', 'Completed', 'Cancelled', 'Expired'];
      final reservationsMap = <String, List<Reservation>>{};

      for (var state in states) {
        try {
          final reservations = await DashboardService.getAllReservationsByState(widget.restaurantId, state);
          reservationsMap[state] = reservations;
        } catch (e) {
          reservationsMap[state] = [];
        }
      }

      setState(() {
        _reservationsByState = reservationsMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'All Reservations',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A4A4A),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadReservations,
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF8B7355),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF8B7355),
            isScrollable: true,
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Pending'),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${(_reservationsByState['Pending'] ?? []).length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Confirmed'),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${(_reservationsByState['Confirmed'] ?? []).length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Completed'),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${(_reservationsByState['Completed'] ?? []).length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Cancelled'),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${(_reservationsByState['Cancelled'] ?? []).length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Expired'),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${(_reservationsByState['Expired'] ?? []).length}',
                        style: const TextStyle(
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
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Error: $_error',
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadReservations,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildReservationsList('Pending', Colors.orange),
                          _buildReservationsList('Confirmed', Colors.green),
                          _buildReservationsList('Completed', Colors.blue),
                          _buildReservationsList('Cancelled', Colors.red),
                          _buildReservationsList('Expired', Colors.grey),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationsList(String state, Color color) {
    final reservations = _reservationsByState[state] ?? [];

    if (reservations.isEmpty) {
      return const Center(
        child: Text(
          'No reservations found',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // Sort by date (latest first)
    reservations.sort((a, b) {
      final dateCompare = b.reservationDate.compareTo(a.reservationDate);
      if (dateCompare != 0) return dateCompare;
      return b.reservationTime.compareTo(a.reservationTime);
    });

    return RefreshIndicator(
      onRefresh: _loadReservations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reservations.length,
        itemBuilder: (context, index) {
          final reservation = reservations[index];
          return _buildReservationCard(reservation, state, color);
        },
      ),
    );
  }

  Widget _buildReservationCard(Reservation reservation, String state, Color color) {
    final timeStr = reservation.reservationTime.split(':').take(2).join(':');
    final dateFormat = DateFormat('MMM dd, yyyy');
    final dateStr = dateFormat.format(reservation.reservationDate);

    // Determine available actions based on status
    bool canConfirm = state == 'Pending';
    bool canCancel = state == 'Pending' || state == 'Confirmed';
    bool canComplete = false; // Completed automatically when they end

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Reservation details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          reservation.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: color.withOpacity(0.3)),
                        ),
                        child: Text(
                          state,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.table_restaurant, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Table ${reservation.tableNumber}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        timeStr,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.people, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${reservation.numberOfGuests} guests',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  if (reservation.cancellationReason != null && reservation.cancellationReason!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.red[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Cancellation reason: ${reservation.cancellationReason}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Action buttons
            if (canConfirm || canCancel || canComplete)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (canConfirm)
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green, size: 20),
                      onPressed: () => _handleConfirm(reservation.id),
                      tooltip: 'Confirm',
                    ),
                  if (canCancel)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red, size: 20),
                      onPressed: () => _handleCancel(reservation.id),
                      tooltip: 'Cancel',
                    ),
                  if (canComplete)
                    IconButton(
                      icon: const Icon(Icons.done_all, color: Colors.blue, size: 20),
                      onPressed: () => _handleComplete(reservation.id),
                      tooltip: 'Complete',
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _handleConfirm(int reservationId) async {
    try {
      await DashboardService.confirmReservation(reservationId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reservation confirmed successfully')),
      );
      _loadReservations();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error confirming reservation: $e')),
      );
    }
  }

  void _handleCancel(int reservationId) async {
    // Ask for cancellation reason (optional)
    final reasonController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Reservation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Cancellation reason (optional):'),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Enter reason...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Reservation'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DashboardService.cancelReservation(
          reservationId,
          reason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reservation cancelled successfully')),
        );
        _loadReservations();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cancelling reservation: $e')),
        );
      }
    }
  }

  void _handleComplete(int reservationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Reservation'),
        content: const Text('Mark this reservation as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DashboardService.completeReservation(reservationId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reservation completed successfully')),
        );
        _loadReservations();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing reservation: $e')),
        );
      }
    }
  }
}
