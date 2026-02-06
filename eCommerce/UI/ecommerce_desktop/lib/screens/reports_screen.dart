import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_desktop/providers/reports_provider.dart';
import 'package:ecommerce_desktop/widgets/screen_title_header.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportsScreen extends StatelessWidget {
  final int restaurantId;

  const ReportsScreen({
    super.key,
    required this.restaurantId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: ChangeNotifierProvider(
        create: (_) => ReportsProvider(restaurantId),
        child: Consumer<ReportsProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.reservationsSummary == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.error != null && provider.reservationsSummary == null) {
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
                      onPressed: () => provider.loadReportsData(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => provider.loadReportsData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ScreenTitleHeader(
                      title: 'Reports',
                      subtitle: 'Reservation analytics and insights',
                      icon: Icons.analytics_rounded,
                    ),
                    const SizedBox(height: 24),
                    // Top Row: 4 KPI Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildTotalReservationsCard(provider),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTopTablesCard(provider),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildBottomTablesCard(provider),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildAverageRatingCard(provider),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Charts Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildPeakHoursChart(provider),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _buildWeeklyOccupancyChart(provider),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTotalReservationsCard(ReportsProvider provider) {
    final summary = provider.reservationsSummary;
    final total = summary?.total ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Color(0xFF8B7355), size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Total Reservations',
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
              child: Text(
                total.toString(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A4A4A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopTablesCard(ReportsProvider provider) {
    final topTables = provider.topTables;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.table_restaurant, color: Color(0xFF8B7355), size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Most Used',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A4A4A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (topTables.isEmpty)
              const Text(
                'No data available',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF999999),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Table ${topTables.first.tableNumber}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4A4A4A),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B8E7F),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${topTables.first.reservationCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomTablesCard(ReportsProvider provider) {
    final bottomTables = provider.bottomTables;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.table_bar, color: Color(0xFF8B7355), size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Least Used',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A4A4A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (bottomTables.isEmpty)
              const Text(
                'No data available',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF999999),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Table ${bottomTables.first.tableNumber}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4A4A4A),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB85C5C),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${bottomTables.first.reservationCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAverageRatingCard(ReportsProvider provider) {
    final rating = provider.averageRating;
    final avgRating = rating?.averageRating ?? 0.0;
    final trend = rating?.trend ?? 0.0;
    final isPositive = trend >= 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: Color(0xFF8B7355), size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Avg Rating',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A4A4A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  avgRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A4A4A),
                  ),
                ),
                const SizedBox(width: 8),
                ...List.generate(5, (index) {
                  if (index < avgRating.floor()) {
                    return const Icon(Icons.star, color: Color(0xFFFFD700), size: 20);
                  } else if (index < avgRating) {
                    return const Icon(Icons.star_half, color: Color(0xFFFFD700), size: 20);
                  } else {
                    return const Icon(Icons.star_border, color: Color(0xFFFFD700), size: 20);
                  }
                }),
              ],
            ),
            if (trend != 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 16,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${isPositive ? '+' : ''}${trend.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPeakHoursChart(ReportsProvider provider) {
    final hourlyData = provider.hourlyData;

    if (hourlyData.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(40),
          child: Center(
            child: Text('No hourly data available'),
          ),
        ),
      );
    }

    // Find max count for Y-axis scaling
    final maxCount = hourlyData.map((e) => e.count).reduce((a, b) => a > b ? a : b);
    final yAxisMax = maxCount > 0 ? (maxCount * 1.2).ceil() : 60; // Add 20% padding

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
                  'Peak Hours Analysis',
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
                  maxY: yAxisMax.toDouble(),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => Colors.grey[800]!,
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final data = hourlyData[group.x.toInt()];
                        return BarTooltipItem(
                          '${data.hour}\n${data.count} reservations',
                          const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < hourlyData.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                hourlyData[index].hour.split(':').first,
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
                        interval: yAxisMax > 60 ? (yAxisMax / 4).ceil().toDouble() : 15.0,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF4A4A4A),
                            ),
                          );
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
                    horizontalInterval: yAxisMax > 60 ? (yAxisMax / 4).ceil().toDouble() : 15.0,
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
                    
                    // Color based on count (green < 15, tan 15-30, red > 30)
                    Color barColor;
                    if (data.count < 15) {
                      barColor = const Color(0xFF6B8E7F); // green
                    } else if (data.count < 30) {
                      barColor = const Color(0xFFD4A574); // tan
                    } else {
                      barColor = const Color(0xFFB85C5C); // red
                    }

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data.count.toDouble(),
                          color: barColor,
                          width: 30,
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

  Widget _buildWeeklyOccupancyChart(ReportsProvider provider) {
    final weeklyData = provider.weeklyOccupancy;

    if (weeklyData.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(40),
          child: Center(
            child: Text('No weekly data available'),
          ),
        ),
      );
    }

    // Find max reservation count for Y-axis scaling
    final maxCount = weeklyData.map((e) => e.reservationCount).reduce((a, b) => a > b ? a : b);
    final yAxisMax = maxCount > 0 ? (maxCount * 1.2).ceil() : 10; // Add 20% padding, min 10

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
                const Icon(Icons.timeline, color: Color(0xFF8B7355)),
                const SizedBox(width: 8),
                const Text(
                  'Weekly Reservations Distribution',
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
                  maxY: yAxisMax.toDouble(),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => Colors.grey[800]!,
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final data = weeklyData[group.x.toInt()];
                        return BarTooltipItem(
                          '${data.day}\n${data.reservationCount} reservations',
                          const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < weeklyData.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                weeklyData[index].day,
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
                        interval: yAxisMax > 50 ? (yAxisMax / 5).ceil().toDouble() : (yAxisMax / 4).ceil().toDouble(),
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF4A4A4A),
                            ),
                          );
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
                    horizontalInterval: yAxisMax > 50 ? (yAxisMax / 5).ceil().toDouble() : (yAxisMax / 4).ceil().toDouble(),
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[300]!,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: weeklyData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    
                    // Use dark brown color for all bars
                    const barColor = Color(0xFF8B7355); // Dark brown

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data.reservationCount.toDouble(),
                          color: barColor,
                          width: 40,
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
