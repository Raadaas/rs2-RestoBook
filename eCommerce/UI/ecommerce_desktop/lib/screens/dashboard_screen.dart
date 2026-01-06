import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_desktop/providers/dashboard_provider.dart';
import 'package:ecommerce_desktop/screens/calendar_screen.dart';
import 'package:ecommerce_desktop/screens/table_layout_screen.dart';
import 'package:ecommerce_desktop/screens/add_reservation_screen.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatelessWidget {
  final int restaurantId;

  const DashboardScreen({
    super.key,
    required this.restaurantId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: ChangeNotifierProvider(
        create: (_) => DashboardProvider(restaurantId),
        child: Consumer<DashboardProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.todayReservations == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.todayReservations == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${provider.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadDashboardData(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadDashboardData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Dashboard',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A4A4A),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddReservationScreen(
                                restaurantId: restaurantId,
                              ),
                            ),
                          );
                          // Refresh dashboard if reservation was created
                          if (result == true) {
                            provider.loadDashboardData();
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Reservation'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B7355),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Top Row: Today's Reservations and Current Occupancy
                  Row(
                    children: [
                      Expanded(
                        child: _buildTodayReservationsCard(context, provider),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildOccupancyCard(context, provider),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Hourly Occupancy Chart
                  _buildHourlyOccupancyChart(provider),
                ],
              ),
            ),
          );
        },
        ),
      ),
    );
  }

  Widget _buildTodayReservationsCard(
      BuildContext context, DashboardProvider provider) {
    final reservations = provider.todayReservations;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Color(0xFF8B7355), size: 20),
                const SizedBox(width: 8),
                const Text(
                  "Today's Reservations",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A4A4A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildReservationBadge(
              'Pending',
              reservations?.pending ?? 0,
              Colors.orange,
              context,
            ),
            const SizedBox(height: 10),
            _buildReservationBadge(
              'Confirmed',
              reservations?.confirmed ?? 0,
              Colors.green,
              context,
            ),
            const SizedBox(height: 10),
            _buildReservationBadge(
              'Completed',
              reservations?.completed ?? 0,
              Colors.blue,
              context,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationBadge(
      String label, int count, Color color, BuildContext context) {
    return InkWell(
      onTap: () {
                      // Navigate to calendar with filter
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CalendarScreen(restaurantId: restaurantId),
                        ),
                      );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4A4A4A),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOccupancyCard(
      BuildContext context, DashboardProvider provider) {
    final occupancy = provider.occupancyData;
    final percentage = occupancy?.percentage ?? 0.0;
    final occupied = occupancy?.occupied ?? 0;
    final total = occupancy?.total ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TableLayoutScreen(restaurantId: restaurantId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.people, color: Color(0xFF8B7355), size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Current Occupancy',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A4A4A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: SizedBox(
                  width: 150,
                  height: 150,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Circular progress indicator (ring around the text)
                      SizedBox(
                        width: 150,
                        height: 150,
                        child: CircularProgressIndicator(
                          value: percentage / 100,
                          strokeWidth: 16,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFF6B8E7F),
                          ),
                        ),
                      ),
                      // Percentage text (centered inside the ring)
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A4A4A),
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  '$occupied of $total tables occupied',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHourlyOccupancyChart(DashboardProvider provider) {
    final hourlyData = provider.hourlyData;
    final occupancy = provider.occupancyData;
    final totalTables = occupancy?.total ?? 1; // Default to 1 to avoid division by zero

    if (hourlyData.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Padding(
          padding: EdgeInsets.all(40),
          child: Center(
            child: Text('No hourly data available'),
          ),
        ),
      );
    }

    // Y-axis shows only 0 at bottom and total tables at top
    final yAxisInterval = totalTables.toDouble(); // Large interval so only 0 and max show

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, color: Color(0xFF8B7355)),
                const SizedBox(width: 8),
                const Text(
                  'Hourly Occupancy',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A4A4A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: totalTables.toDouble(),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => Colors.grey[800]!,
                      tooltipRoundedRadius: 8,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < hourlyData.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                hourlyData[index].hour,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF4A4A4A),
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: yAxisInterval,
                        getTitlesWidget: (value, meta) {
                          // Only show 0 and total tables
                          if (value.toInt() == 0) {
                            return const Text(
                              '0',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF4A4A4A),
                              ),
                            );
                          } else if (value.toInt() == totalTables) {
                            return Text(
                              totalTables.toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF4A4A4A),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: totalTables.toDouble(), // Only show grid at 0 and max
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[300]!,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: hourlyData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    Color barColor;
                    // Color based on percentage of total tables
                    final percentage = (data.count / totalTables) * 100;
                    if (percentage < 30) {
                      barColor = const Color(0xFF6B8E7F); // green
                    } else if (percentage < 70) {
                      barColor = const Color(0xFFD4A574); // orange
                    } else {
                      barColor = const Color(0xFFB85C5C); // red
                    }

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data.count.toDouble(),
                          color: barColor,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

