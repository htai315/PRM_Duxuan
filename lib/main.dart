import 'package:flutter/material.dart';
import 'package:du_xuan/core/utils/notification_service.dart';
import 'package:du_xuan/di.dart';
import 'package:du_xuan/routes/app_routes.dart';
import 'package:du_xuan/routes/route_args.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi', null);

  final notificationService = buildNotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();

  runApp(DuXuanApp(notificationService: notificationService));
}

class DuXuanApp extends StatefulWidget {
  final NotificationService notificationService;

  const DuXuanApp({super.key, required this.notificationService});

  @override
  State<DuXuanApp> createState() => _DuXuanAppState();
}

class _DuXuanAppState extends State<DuXuanApp> {
  @override
  void initState() {
    super.initState();
    // Wire navigation callback từ notification → itinerary page
    widget.notificationService.onNavigateToPlan = (planId) {
      widget.notificationService.navigatorKey.currentState?.pushNamed(
        AppRoutes.itinerary,
        arguments: ItineraryRouteArgs(planId: planId),
      );
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.notificationService.handlePendingNavigation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Du Xuân Planner',
      debugShowCheckedModeBanner: false,
      navigatorKey: widget.notificationService.navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD32F2F),
        ),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}

