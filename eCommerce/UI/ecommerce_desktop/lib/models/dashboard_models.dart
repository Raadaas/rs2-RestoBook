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

class TableUsageData {
  final int tableId;
  final String tableNumber;
  final int capacity;
  final int reservationCount;

  TableUsageData({
    required this.tableId,
    required this.tableNumber,
    required this.capacity,
    required this.reservationCount,
  });

  factory TableUsageData.fromJson(Map<String, dynamic> json) {
    return TableUsageData(
      tableId: json['tableId'] ?? 0,
      tableNumber: json['tableNumber'] ?? '',
      capacity: json['capacity'] ?? 0,
      reservationCount: json['reservationCount'] ?? 0,
    );
  }
}

class ReservationsSummary {
  final int total;
  final int confirmed;
  final int completed;
  final int cancelled;
  final double trend;

  ReservationsSummary({
    required this.total,
    required this.confirmed,
    required this.completed,
    required this.cancelled,
    required this.trend,
  });

  factory ReservationsSummary.fromJson(Map<String, dynamic> json) {
    return ReservationsSummary(
      total: json['total'] ?? 0,
      confirmed: json['confirmed'] ?? 0,
      completed: json['completed'] ?? 0,
      cancelled: json['cancelled'] ?? 0,
      trend: (json['trend'] ?? 0.0).toDouble(),
    );
  }
}

class AverageRating {
  final double averageRating;
  final int totalReviews;
  final double trend;

  AverageRating({
    required this.averageRating,
    required this.totalReviews,
    required this.trend,
  });

  factory AverageRating.fromJson(Map<String, dynamic> json) {
    return AverageRating(
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      trend: (json['trend'] ?? 0.0).toDouble(),
    );
  }
}

class WeeklyOccupancyData {
  final String day;
  final int reservationCount;

  WeeklyOccupancyData({
    required this.day,
    required this.reservationCount,
  });

  factory WeeklyOccupancyData.fromJson(Map<String, dynamic> json) {
    return WeeklyOccupancyData(
      day: json['day'] ?? '',
      reservationCount: json['reservationCount'] ?? 0,
    );
  }
}

