class TodayReservations {
  final int pending;
  final int confirmed;
  final int completed;

  TodayReservations({
    required this.pending,
    required this.confirmed,
    required this.completed,
  });

  factory TodayReservations.fromJson(Map<String, dynamic> json) {
    return TodayReservations(
      pending: json['pending'] ?? 0,
      confirmed: json['confirmed'] ?? 0,
      completed: json['completed'] ?? 0,
    );
  }
}

class OccupancyData {
  final int occupied;
  final int total;
  final double percentage;

  OccupancyData({
    required this.occupied,
    required this.total,
    required this.percentage,
  });

  factory OccupancyData.fromJson(Map<String, dynamic> json) {
    return OccupancyData(
      occupied: json['occupied'] ?? 0,
      total: json['total'] ?? 0,
      percentage: (json['percentage'] ?? 0.0).toDouble(),
    );
  }
}

class HourlyData {
  final String hour;
  final int count;
  final String color;

  HourlyData({
    required this.hour,
    required this.count,
    required this.color,
  });

  factory HourlyData.fromJson(Map<String, dynamic> json) {
    return HourlyData(
      hour: json['hour'] ?? '',
      count: json['count'] ?? 0,
      color: json['color'] ?? '#6B8E7F',
    );
  }
}

