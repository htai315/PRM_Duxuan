import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:du_xuan/core/enums/plan_status.dart';
import 'package:du_xuan/core/enums/notification_type.dart';
import 'package:du_xuan/data/interfaces/repositories/i_notification_repository.dart';
import 'package:du_xuan/domain/entities/app_notification.dart';
import 'package:du_xuan/domain/entities/plan.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  NotificationService.instance?._handleNotificationTap(response);
}

class NotificationService {
  static const String _channelId = 'plan_reminder_channel';
  static const String _channelName = 'Nhắc lịch kế hoạch';
  static const String _channelDescription =
      'Thông báo nhắc trước ngày diễn ra kế hoạch';

  static NotificationService? instance;

  final FlutterLocalNotificationsPlugin _plugin;
  final INotificationRepository _notificationRepo;
  void Function(int planId)? onNavigateToPlan;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  bool _initialized = false;
  int? _pendingPlanId;

  NotificationService({
    required INotificationRepository notificationRepo,
    this.onNavigateToPlan,
    FlutterLocalNotificationsPlugin? plugin,
  }) : _notificationRepo = notificationRepo,
       _plugin = plugin ?? FlutterLocalNotificationsPlugin() {
    instance = this;
  }

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    await _configureLocalTimezone();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final response = launchDetails?.notificationResponse;
      if (response != null) {
        await _handleNotificationTap(response);
      }
    }

    _initialized = true;
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
    } catch (e) {
      debugPrint('Notification timezone init fallback: $e');
      // Fallback giữ timezone mặc định của package nếu không resolve được.
    }
  }

  Future<void> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    final canExact = await android?.canScheduleExactNotifications();
    if (canExact == false) {
      await android?.requestExactAlarmsPermission();
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);

    final macos = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    await macos?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> schedulePlanReminder(Plan plan) async {
    if (!_initialized) await initialize();

    await cancelPlanReminder(plan.id);

    if (!_shouldSchedule(plan)) {
      return;
    }

    final reminders = <_ReminderSpec>[
      const _ReminderSpec(
        code: 'D_MINUS_1',
        title: 'Nhắc chuyến đi ngày mai',
        bodyTemplate: 'Kế hoạch "{name}" sẽ bắt đầu vào ngày mai.',
        dayOffset: -1,
        hour: 14,
        minute: 40,
      ),
      const _ReminderSpec(
        code: 'D0',
        title: 'Hôm nay khởi hành',
        bodyTemplate: 'Đến ngày bắt đầu kế hoạch "{name}". Chúc bạn đi vui!',
        dayOffset: 0,
        hour: 7,
      ),
    ];

    final start = DateTime(
      plan.startDate.year,
      plan.startDate.month,
      plan.startDate.day,
    );
    final now = DateTime.now();

    for (final spec in reminders) {
      final triggerDate = start.add(Duration(days: spec.dayOffset));
      final trigger = DateTime(
        triggerDate.year,
        triggerDate.month,
        triggerDate.day,
        spec.hour,
        spec.minute,
        0,
      );

      if (!trigger.isAfter(now)) {
        continue;
      }

      final eventKey = _eventKey(plan.id, spec.code);
      final payloadMap = {'planId': plan.id, 'eventKey': eventKey};
      final payload = jsonEncode(payloadMap);
      final body = spec.bodyTemplate.replaceAll('{name}', plan.name);

      await _notificationRepo.deleteByEventKey(eventKey);
      await _notificationRepo.create(
        AppNotification(
          id: 0,
          userId: plan.userId,
          planId: plan.id,
          title: spec.title,
          body: body,
          isRead: false,
          type: NotificationType.reminder,
          eventKey: eventKey,
          scheduledAt: trigger,
          createdAt: now,
          payload: payload,
        ),
      );

      final detail = NotificationDetails(
        android: const AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
        macOS: const DarwinNotificationDetails(),
      );
      final scheduleMode = await _resolveAndroidScheduleMode();

      await _plugin.zonedSchedule(
        _notificationId(plan.id, spec.code),
        spec.title,
        body,
        tz.TZDateTime.from(trigger, tz.local),
        detail,
        payload: payload,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: scheduleMode,
      );
    }
  }

  Future<void> syncPlanReminders(Iterable<Plan> plans) async {
    if (!_initialized) await initialize();

    for (final plan in plans) {
      try {
        if (_shouldSchedule(plan)) {
          await schedulePlanReminder(plan);
        } else {
          await cancelPlanReminder(plan.id);
        }
      } catch (e) {
        debugPrint('Sync reminder error (plan ${plan.id}): $e');
      }
    }
  }

  Future<void> scheduleTestNotification({
    required int userId,
    int delaySeconds = 10,
  }) async {
    if (!_initialized) await initialize();
    final now = DateTime.now();
    final trigger = now.add(Duration(seconds: delaySeconds));
    final eventKey = 'test:${now.millisecondsSinceEpoch}';
    final notificationId = _buildTestNotificationId(now);
    final title = 'Thông báo kiểm thử';
    final body =
        'Nếu bạn thấy thông báo này, lịch nhắc đang hoạt động bình thường.';
    final payload = jsonEncode({'eventKey': eventKey});

    await _notificationRepo.deleteByEventKey(eventKey);
    await _notificationRepo.create(
      AppNotification(
        id: 0,
        userId: userId,
        planId: null,
        title: title,
        body: body,
        isRead: false,
        type: NotificationType.system,
        eventKey: eventKey,
        scheduledAt: trigger,
        createdAt: now,
        payload: payload,
      ),
    );
    final detail = _buildDefaultDetails();
    final scheduleMode = await _resolveAndroidScheduleMode();

    await _plugin.zonedSchedule(
      notificationId,
      title,
      body,
      tz.TZDateTime.from(trigger, tz.local),
      detail,
      payload: payload,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: scheduleMode,
    );
  }

  Future<void> showInstantTestNotification({required int userId}) async {
    if (!_initialized) await initialize();
    final now = DateTime.now();
    final eventKey = 'test_instant:${now.millisecondsSinceEpoch}';
    final notificationId = _buildTestNotificationId(now);
    final title = 'Thông báo test ngay';
    final body = 'Thông báo này dùng để kiểm tra hiển thị ngoài hệ thống.';
    final payload = jsonEncode({'eventKey': eventKey});

    await _notificationRepo.create(
      AppNotification(
        id: 0,
        userId: userId,
        planId: null,
        title: title,
        body: body,
        isRead: false,
        type: NotificationType.system,
        eventKey: eventKey,
        scheduledAt: now,
        createdAt: now,
        payload: payload,
      ),
    );

    await _plugin.show(
      notificationId,
      title,
      body,
      _buildDefaultDetails(),
      payload: payload,
    );
  }

  Future<bool> canScheduleExactAlarms() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final canExact = await android?.canScheduleExactNotifications();
    return canExact ?? true;
  }

  Future<bool> areNotificationsEnabled() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final enabled = await android?.areNotificationsEnabled();
    return enabled ?? true;
  }

  Future<void> cancelPlanReminder(int planId) async {
    if (!_initialized) await initialize();

    await _plugin.cancel(_notificationId(planId, 'D_MINUS_1'));
    await _plugin.cancel(_notificationId(planId, 'D0'));

    await _notificationRepo.deleteReminderByPlanId(planId);
  }

  Future<void> cancelAll() async {
    if (!_initialized) await initialize();
    await _plugin.cancelAll();
  }

  void handlePendingNavigation() {
    final planId = _pendingPlanId;
    if (planId == null) return;
    _pendingPlanId = null;
    _navigateToPlan(planId);
  }

  bool _shouldSchedule(Plan plan) {
    if (plan.status != PlanStatus.active) return false;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final start = DateTime(
      plan.startDate.year,
      plan.startDate.month,
      plan.startDate.day,
    );
    return !start.isBefore(todayDate);
  }

  int _notificationId(int planId, String code) {
    final suffix = code == 'D_MINUS_1' ? 1 : 2;
    return (planId * 10) + suffix;
  }

  int _buildTestNotificationId(DateTime now) {
    return 1000000000 + (now.millisecondsSinceEpoch % 1000000);
  }

  Future<AndroidScheduleMode> _resolveAndroidScheduleMode() async {
    final canExact = await canScheduleExactAlarms();
    return canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  NotificationDetails _buildDefaultDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );
  }

  String _eventKey(int planId, String code) => 'plan:$planId:$code';

  void _navigateToPlan(int planId) {
    final callback = onNavigateToPlan;
    if (callback != null) {
      callback(planId);
    } else {
      _pendingPlanId = planId;
    }
  }

  Future<void> _handleNotificationTap(NotificationResponse response) async {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return;

      final map = Map<String, dynamic>.from(decoded);
      final rawPlanId = map['planId'];
      int? planId;
      if (rawPlanId is int) {
        planId = rawPlanId;
      } else if (rawPlanId is num) {
        planId = rawPlanId.toInt();
      } else if (rawPlanId is String) {
        planId = int.tryParse(rawPlanId);
      }
      final eventKey = map['eventKey']?.toString();

      if (eventKey != null && eventKey.isNotEmpty) {
        final record = await _notificationRepo.getByEventKey(eventKey);
        if (record != null && !record.isRead) {
          await _notificationRepo.markAsRead(record.id);
        }
      }

      if (planId != null) {
        _navigateToPlan(planId);
      }
    } catch (_) {
      // Ignore payload parse errors.
    }
  }
}

class _ReminderSpec {
  final String code;
  final String title;
  final String bodyTemplate;
  final int dayOffset;
  final int hour;
  final int minute;

  const _ReminderSpec({
    required this.code,
    required this.title,
    required this.bodyTemplate,
    required this.dayOffset,
    required this.hour,
    this.minute = 0,
  });
}
