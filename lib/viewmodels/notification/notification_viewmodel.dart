import 'package:flutter/material.dart';
import 'package:du_xuan/data/interfaces/repositories/i_notification_repository.dart';
import 'package:du_xuan/domain/entities/app_notification.dart';

class NotificationViewModel extends ChangeNotifier {
  final INotificationRepository _repository;

  NotificationViewModel(this._repository);

  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  int _unreadCount = 0;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _unreadCount;

  Future<void> loadNotifications(int userId, {bool refresh = false}) async {
    if (!refresh && _isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _repository.getByUserId(userId);
      final unread = await _repository.getUnreadCount(userId);
      _notifications = data;
      _unreadCount = unread;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadUnreadCount(int userId) async {
    try {
      _unreadCount = await _repository.getUnreadCount(userId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> markAsRead(AppNotification notification) async {
    if (notification.isRead || _isSubmitting) return;

    _isSubmitting = true;
    notifyListeners();

    try {
      await _repository.markAsRead(notification.id);
      _notifications = _notifications.map((item) {
        if (item.id != notification.id) return item;
        return item.copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
      }).toList();
      _unreadCount = (_unreadCount - 1).clamp(0, 999999).toInt();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _isSubmitting = false;
    notifyListeners();
  }

  Future<bool> deleteNotification(AppNotification notification) async {
    if (_isSubmitting) return false;

    _isSubmitting = true;
    notifyListeners();

    try {
      await _repository.deleteById(notification.id);
      _notifications.removeWhere((item) => item.id == notification.id);
      if (!notification.isRead) {
        _unreadCount = (_unreadCount - 1).clamp(0, 999999).toInt();
      }
      _errorMessage = null;
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> markAllAsRead(int userId) async {
    if (_isSubmitting || _unreadCount == 0) return;

    _isSubmitting = true;
    notifyListeners();

    try {
      await _repository.markAllAsRead(userId);
      final now = DateTime.now();
      _notifications = _notifications
          .map((item) => item.copyWith(isRead: true, readAt: now))
          .toList();
      _unreadCount = 0;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _isSubmitting = false;
    notifyListeners();
  }

  Future<bool> deleteAllVisible(int userId) async {
    if (_isSubmitting || _notifications.isEmpty) return false;

    _isSubmitting = true;
    notifyListeners();

    try {
      await _repository.deleteAllVisibleByUserId(userId);
      _notifications = [];
      _unreadCount = 0;
      _errorMessage = null;
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }
}
