import 'package:ecommerce_desktop/models/dashboard_models.dart';
import 'package:ecommerce_desktop/services/dashboard_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class DashboardProvider with ChangeNotifier {
  final int restaurantId;
  
  TodayReservations? _todayReservations;
  OccupancyData? _occupancyData;
  List<HourlyData> _hourlyData = [];
  bool _isLoading = false;
  String? _error;
  Timer? _occupancyTimer;

  TodayReservations? get todayReservations => _todayReservations;
  OccupancyData? get occupancyData => _occupancyData;
  List<HourlyData> get hourlyData => _hourlyData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  DashboardProvider(this.restaurantId) {
    loadDashboardData();
    _startOccupancyUpdates();
  }

  void _startOccupancyUpdates() {
    _occupancyTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      loadOccupancy();
    });
  }

  Future<void> loadDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        loadTodayReservations(),
        loadOccupancy(),
        loadHourlyOccupancy(),
      ]);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTodayReservations() async {
    try {
      _todayReservations = await DashboardService.getTodayReservations(restaurantId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadOccupancy() async {
    try {
      _occupancyData = await DashboardService.getCurrentOccupancy(restaurantId);
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

  @override
  void dispose() {
    _occupancyTimer?.cancel();
    super.dispose();
  }
}

