import 'package:ecommerce_desktop/models/dashboard_models.dart';
import 'package:ecommerce_desktop/services/dashboard_service.dart';
import 'package:flutter/foundation.dart';

class ReportsProvider with ChangeNotifier {
  final int restaurantId;
  
  ReservationsSummary? _reservationsSummary;
  List<TableUsageData> _topTables = [];
  List<TableUsageData> _bottomTables = [];
  AverageRating? _averageRating;
  List<HourlyData> _hourlyData = [];
  List<WeeklyOccupancyData> _weeklyOccupancy = [];
  bool _isLoading = false;
  String? _error;

  ReservationsSummary? get reservationsSummary => _reservationsSummary;
  List<TableUsageData> get topTables => _topTables;
  List<TableUsageData> get bottomTables => _bottomTables;
  AverageRating? get averageRating => _averageRating;
  List<HourlyData> get hourlyData => _hourlyData;
  List<WeeklyOccupancyData> get weeklyOccupancy => _weeklyOccupancy;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ReportsProvider(this.restaurantId) {
    loadReportsData();
  }

  Future<void> loadReportsData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        loadReservationsSummary(),
        loadTopTables(),
        loadBottomTables(),
        loadAverageRating(),
        loadHourlyOccupancy(),
        loadWeeklyOccupancy(),
      ]);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadReservationsSummary() async {
    try {
      _reservationsSummary = await DashboardService.getReservationsSummary(restaurantId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadTopTables() async {
    try {
      _topTables = await DashboardService.getTopTables(restaurantId, count: 3, leastUsed: false);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadBottomTables() async {
    try {
      _bottomTables = await DashboardService.getTopTables(restaurantId, count: 3, leastUsed: true);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadAverageRating() async {
    try {
      _averageRating = await DashboardService.getAverageRating(restaurantId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadHourlyOccupancy() async {
    try {
      _hourlyData = await DashboardService.getHourlyOccupancy(restaurantId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadWeeklyOccupancy() async {
    try {
      _weeklyOccupancy = await DashboardService.getWeeklyOccupancy(restaurantId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}

