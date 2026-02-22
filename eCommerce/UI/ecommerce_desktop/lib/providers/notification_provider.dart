import 'package:ecommerce_desktop/models/notification_model.dart';
import 'package:ecommerce_desktop/services/notification_service.dart';
import 'package:flutter/foundation.dart';

class NotificationProvider with ChangeNotifier {
  List<NotificationModel> _items = [];
  bool _loading = false;
  String? _error;

  NotificationProvider() {
    load();
  }

  List<NotificationModel> get items => List.unmodifiable(_items);
  bool get loading => _loading;
  String? get error => _error;
  int get unreadCount => _items.where((n) => !n.isRead).length;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await NotificationService.getMyNotifications();
    } catch (e) {
      _error = e.toString();
      _items = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await NotificationService.markAsRead(id);
      final index = _items.indexWhere((n) => n.id == id);
      if (index >= 0) {
        final n = _items[index];
        _items = [..._items];
        _items[index] = NotificationModel(
          id: n.id,
          userId: n.userId,
          type: n.type,
          title: n.title,
          message: n.message,
          relatedReservationId: n.relatedReservationId,
          isRead: true,
          sentAt: n.sentAt,
          readAt: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (_) {}
  }
}
