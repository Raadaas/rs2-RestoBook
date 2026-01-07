import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ecommerce_desktop/models/restaurant_model.dart';
import 'package:ecommerce_desktop/models/table_model.dart' as table_model;
import 'package:ecommerce_desktop/models/reservation_model.dart';
import 'package:ecommerce_desktop/providers/restaurant_provider.dart';
import 'package:ecommerce_desktop/providers/base_provider.dart';
import 'package:ecommerce_desktop/providers/auth_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CalendarScreen extends StatefulWidget {
  final int restaurantId;

  const CalendarScreen({
    super.key,
    required this.restaurantId,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final RestaurantProvider _restaurantProvider = RestaurantProvider();
  Restaurant? _restaurant;
  List<table_model.Table> _tables = [];
  List<Reservation> _reservations = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load restaurant
      final baseUrl = const String.fromEnvironment(
        "baseUrl",
        defaultValue: "http://localhost:5121/api/"
      );
      final restaurantUrl = Uri.parse("${baseUrl}restaurants/${widget.restaurantId}");
      final headers = _restaurantProvider.createHeaders();
      final restaurantResponse = await http.get(restaurantUrl, headers: headers);
      
      print('Loading restaurant: ${restaurantResponse.statusCode}');
      print('Response body: ${restaurantResponse.body}');
      
      if (restaurantResponse.statusCode == 200) {
        final restaurantData = jsonDecode(restaurantResponse.body);
        print('Restaurant data: $restaurantData');
        setState(() {
          _restaurant = Restaurant.fromJson(restaurantData);
        });
        print('Restaurant loaded: ${_restaurant?.name}, OpenTime: ${_restaurant?.openTime}, CloseTime: ${_restaurant?.closeTime}');
      } else {
        print('Failed to load restaurant: ${restaurantResponse.statusCode} - ${restaurantResponse.body}');
        throw Exception('Failed to load restaurant: ${restaurantResponse.statusCode}');
      }

      // Load tables
      final tablesUrl = Uri.parse("${baseUrl}tables?restaurantId=${widget.restaurantId}");
      final tablesResponse = await http.get(tablesUrl, headers: headers);
      
      if (tablesResponse.statusCode == 200) {
        final tablesData = jsonDecode(tablesResponse.body);
        if (tablesData['items'] != null) {
          setState(() {
            _tables = (tablesData['items'] as List)
                .map((e) => table_model.Table.fromJson(e))
                .toList();
          });
        }
      }

      // Load reservations for selected date
      await _loadReservations(_selectedDate);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadReservations(DateTime date) async {
    try {
      final baseUrl = const String.fromEnvironment(
        "baseUrl",
        defaultValue: "http://localhost:5121/api/"
      );
      // Normalize date to start of day (remove time component)
      final normalizedDate = DateTime(date.year, date.month, date.day);
      
      // Use ReservationDateFrom and ReservationDateTo to filter for the entire day
      final dateFrom = normalizedDate; // Start of day (00:00:00)
      final dateTo = normalizedDate.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)); // End of day (23:59:59)
      
      // Format dates for query string
      final dateFromStr = dateFrom.toIso8601String();
      final dateToStr = dateTo.toIso8601String();
      
      final url = Uri.parse("${baseUrl}reservations?restaurantId=${widget.restaurantId}&reservationDateFrom=${Uri.encodeComponent(dateFromStr)}&reservationDateTo=${Uri.encodeComponent(dateToStr)}");
      final headers = _restaurantProvider.createHeaders();
      final response = await http.get(url, headers: headers);
      
      print('Loading reservations for date: ${DateFormat('yyyy-MM-dd').format(normalizedDate)}');
      print('URL: $url');
      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['items'] != null) {
          setState(() {
            _reservations = (data['items'] as List)
                .map((e) => Reservation.fromJson(e))
                .toList();
          });
        }
      }
    } catch (e) {
      print('Error loading reservations: $e');
    }
  }

  List<TimeOfDay> _getTimeSlots() {
    if (_restaurant == null) return [];
    
    final openTime = _parseTime(_restaurant!.openTime);
    final closeTime = _parseTime(_restaurant!.closeTime);
    
    List<TimeOfDay> slots = [];
    // Start from the hour of open time (always use minute 0 for slots)
    var currentHour = openTime.hour;
    
    // Handle case where close time is next day (e.g., 22:00 to 02:00)
    bool crossesMidnight = closeTime.hour < openTime.hour || 
                          (closeTime.hour == openTime.hour && closeTime.minute < openTime.minute);
    
    int maxIterations = 24; // Safety limit to prevent infinite loop
    int iterations = 0;
    
    while (iterations < maxIterations) {
      // Always use minute 0 for hourly slots
      slots.add(TimeOfDay(hour: currentHour, minute: 0));
      
      // Check if we've reached close time
      if (!crossesMidnight) {
        if (currentHour > closeTime.hour || 
            (currentHour == closeTime.hour)) {
          break;
        }
      } else {
        // For midnight crossing, stop when we reach close time hour
        if (currentHour == closeTime.hour) {
          break;
        }
      }
      
      // Increment hour
      currentHour++;
      if (currentHour >= 24) {
        currentHour = 0;
        if (!crossesMidnight) {
          break; // Shouldn't happen, but safety check
        }
      }
      
      iterations++;
    }
    
    return slots;
  }

  TimeOfDay _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length < 2) {
        return const TimeOfDay(hour: 9, minute: 0);
      }
      return TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 9,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    } catch (e) {
      print('Error parsing time: $timeStr - $e');
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  Reservation? _getReservationForSlot(TimeOfDay time, table_model.Table table) {
    try {
      return _reservations.firstWhere(
        (r) {
          if (r.tableId != table.id) return false;
          
          final reservationTime = _parseTime(r.reservationTime);
          final duration = _parseTime(r.duration);
          
          final reservationStart = DateTime(
            r.reservationDate.year,
            r.reservationDate.month,
            r.reservationDate.day,
            reservationTime.hour,
            reservationTime.minute,
          );
          
          final reservationEnd = reservationStart.add(Duration(
            hours: duration.hour,
            minutes: duration.minute,
          ));
          
          final slotStart = DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            time.hour,
            time.minute,
          );
          
          final slotEnd = slotStart.add(const Duration(hours: 1));
          
          // Check overlap: start1 < end2 AND start2 < end1
          return reservationStart.isBefore(slotEnd) && slotStart.isBefore(reservationEnd);
        },
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F0),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date picker component
            _buildDatePicker(),
            const SizedBox(height: 24),
            // Day Timeline
            Expanded(
              child: _buildDayTimeline(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    final isToday = _selectedDate.year == DateTime.now().year &&
                    _selectedDate.month == DateTime.now().month &&
                    _selectedDate.day == DateTime.now().day;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Left arrow button
        InkWell(
          onTap: () {
            setState(() {
              _selectedDate = _selectedDate.subtract(const Duration(days: 1));
            });
            _loadReservations(_selectedDate);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: const Icon(
              Icons.chevron_left,
              color: Color(0xFF4A4A4A),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Date display field
        InkWell(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null && picked != _selectedDate) {
              setState(() {
                _selectedDate = picked;
              });
              _loadReservations(picked);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Text(
              isToday 
                ? 'Today - ${DateFormat('MMM d, yyyy').format(_selectedDate)}'
                : DateFormat('MMM d, yyyy').format(_selectedDate),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4A4A4A),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Right arrow button
        InkWell(
          onTap: () {
            setState(() {
              _selectedDate = _selectedDate.add(const Duration(days: 1));
            });
            _loadReservations(_selectedDate);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: const Icon(
              Icons.chevron_right,
              color: Color(0xFF4A4A4A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayTimeline() {
    if (_restaurant == null || _tables.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final timeSlots = _getTimeSlots();
    if (timeSlots.isEmpty) {
      return const Center(child: Text('No working hours configured'));
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: SizedBox(
                width: 100 + (_tables.length * 120), // Time column + table columns
                child: Column(
                  children: [
              // Header row with table names
              Container(
                height: 50,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                ),
                child: Row(
                  children: [
                    // Empty cell for time column
                    Container(
                      width: 100,
                      decoration: const BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                      ),
                    ),
                    // Table headers
                    ..._tables.map((table) => Container(
                      width: 120,
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          table.tableNumber,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4A4A4A),
                          ),
                        ),
                      ),
                    )),
                  ],
                ),
              ),
                    // Time slots rows with Stack for overlapping reservations
                    SizedBox(
                      height: (timeSlots.length * 50) + 50, // Total height: rows + header (reduced from 80 to 50)
                      child: Stack(
                        clipBehavior: Clip.hardEdge, // Clip overflow to ignore the exception
                        children: [
                          // Background grid
                          Column(
                            children: timeSlots.map((time) => _buildTimeRow(time)).toList(),
                          ),
                          // Overlay reservations
                          ..._buildReservationOverlays(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeRow(TimeOfDay time) {
    return Container(
      height: 50, // Reduced from 80 to 50
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0)),
        ),
      ),
      child: Row(
        children: [
          // Time label
          Container(
            width: 100,
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: Color(0xFFE0E0E0)),
              ),
            ),
            child: Center(
              child: Text(
                time.format(context),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF4A4A4A),
                ),
              ),
            ),
          ),
          // Table cells (empty, reservations will be overlaid)
          ..._tables.map((table) => Container(
            width: 120,
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: Color(0xFFE0E0E0)),
              ),
            ),
          )),
        ],
      ),
    );
  }

  List<Widget> _buildReservationOverlays() {
    final timeSlots = _getTimeSlots();
    if (timeSlots.isEmpty) return [];

    List<Widget> overlays = [];

    for (var reservation in _reservations) {
      final reservationTime = _parseTime(reservation.reservationTime);
      final duration = _parseTime(reservation.duration);
      
      // Find the row index where reservation starts
      // Match by hour only, since slots are hourly (e.g., 9:00, 10:00, 11:00...)
      // Reservations are being placed one slot too late, so we need to shift them up
      int matchedIndex = -1;
      
      // Find the matching slot
      for (int i = 0; i < timeSlots.length; i++) {
        if (timeSlots[i].hour == reservationTime.hour) {
          matchedIndex = i;
          break;
        }
      }
      
      if (matchedIndex == -1) continue;
      
      // Use the matched index directly without shifting
      // Reservation at 9:00 (matchedIndex=0) should be at slot 0 (9:00)
      int startRowIndex = matchedIndex;
      
      // Find table column index
      int tableIndex = _tables.indexWhere((t) => t.id == reservation.tableId);
      if (tableIndex == -1) continue;
      
      // Calculate number of rows this reservation spans
      // Each hour = exactly 1 slot
      final hours = duration.hour;
      final rowHeight = 50.0; // Reduced from 80 to 50
      final totalHeight = hours * rowHeight; // Each hour = exactly 1 slot
      
      // Calculate position
      final left = 100.0 + (tableIndex * 120.0) + 4.0; // Time column width + table offset + padding
      final top = (startRowIndex * rowHeight) + 4.0; // Row offset + padding (header is outside Stack)
      
      // Only add if position is valid
      if (left >= 0 && top >= 0 && totalHeight > 0) {
        overlays.add(
          Positioned(
            left: left,
            top: top,
            width: 112.0, // 120 - 8 (padding)
            height: totalHeight - 8.0, // Subtract padding
            child: _buildReservationBlock(reservation),
          ),
        );
      }
    }

    return overlays;
  }

  Widget _buildReservationBlock(Reservation reservation) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF6B8E7F),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            reservation.userName,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.people,
                size: 12,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              Text(
                '${reservation.numberOfGuests}',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
