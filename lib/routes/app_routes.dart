import 'package:flutter/material.dart';
import 'package:du_xuan/di.dart';
import 'package:du_xuan/routes/route_args.dart';
import 'package:du_xuan/views/checklist/checklist_page.dart';
import 'package:du_xuan/views/home/home_page.dart';
import 'package:du_xuan/views/itinerary/activity_form_page.dart';
import 'package:du_xuan/views/plan_detail/plan_detail_page.dart';
import 'package:du_xuan/views/login/login_page.dart';
import 'package:du_xuan/views/notification/notification_page.dart';
import 'package:du_xuan/views/plan/plan_form_page.dart';
import 'package:du_xuan/views/register/register_page.dart';
import 'package:du_xuan/views/settings/change_password_page.dart';
import 'package:du_xuan/views/splash/splash_page.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String planCreate = '/plan/create';
  static const String planEdit = '/plan/edit';
  static const String itinerary = '/itinerary';
  static const String activityCreate = '/activity/create';
  static const String activityEdit = '/activity/edit';
  static const String checklist = '/checklist';
  static const String changePassword = '/change-password';
  static const String notifications = '/notifications';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _pageRoute(SplashPage(authRepo: buildAuthRepository()));
      case login:
        return _pageRoute(LoginPage(viewModel: buildLoginVM()));
      case register:
        return _pageRoute(RegisterPage(viewModel: buildRegisterVM()));
      case home:
        return _pageRoute(HomePage(viewModel: buildHomeVM()));
      case planCreate:
        return _typedArgsRoute<PlanCreateRouteArgs>(
          settings,
          expectedType: 'PlanCreateRouteArgs',
          builder: (args) =>
              PlanFormPage(viewModel: buildPlanFormVM(), userId: args.userId),
        );
      case planEdit:
        return _typedArgsRoute<PlanEditRouteArgs>(
          settings,
          expectedType: 'PlanEditRouteArgs',
          builder: (args) => PlanFormPage(
            viewModel: buildPlanFormVM(),
            userId: 0,
            editPlanId: args.planId,
          ),
        );
      case itinerary:
        return _typedArgsRoute<ItineraryRouteArgs>(
          settings,
          expectedType: 'ItineraryRouteArgs',
          builder: (args) => PlanDetailPage(
            viewModel: buildItineraryVM(),
            planId: args.planId,
          ),
        );
      case activityCreate:
        return _typedArgsRoute<ActivityCreateRouteArgs>(
          settings,
          expectedType: 'ActivityCreateRouteArgs',
          builder: (args) => ActivityFormPage(
            viewModel: buildActivityFormVM(),
            planDayId: args.planDayId,
          ),
        );
      case activityEdit:
        return _typedArgsRoute<ActivityEditRouteArgs>(
          settings,
          expectedType: 'ActivityEditRouteArgs',
          builder: (args) => ActivityFormPage(
            viewModel: buildActivityFormVM(),
            planDayId: args.activity.planDayId,
            existingActivity: args.activity,
          ),
        );
      case checklist:
        return _typedArgsRoute<ChecklistRouteArgs>(
          settings,
          expectedType: 'ChecklistRouteArgs',
          builder: (args) => ChecklistPage(
            viewModel: buildChecklistVM(),
            planId: args.planId,
            planName: args.planName,
          ),
        );
      case changePassword:
        return _typedArgsRoute<ChangePasswordRouteArgs>(
          settings,
          expectedType: 'ChangePasswordRouteArgs',
          builder: (args) => ChangePasswordPage(
            viewModel: buildChangePasswordVM(),
            userId: args.userId,
          ),
        );
      case notifications:
        return _typedArgsRoute<NotificationsRouteArgs>(
          settings,
          expectedType: 'NotificationsRouteArgs',
          builder: (args) => NotificationPage(
            viewModel: buildNotificationVM(),
            userId: args.userId,
            notificationService: buildNotificationService(),
          ),
        );
      default:
        return _pageRoute(LoginPage(viewModel: buildLoginVM()));
    }
  }

  static Route<dynamic> _pageRoute(Widget page, {RouteSettings? settings}) {
    return MaterialPageRoute(settings: settings, builder: (_) => page);
  }

  static Route<dynamic> _typedArgsRoute<T>(
    RouteSettings settings, {
    required String expectedType,
    required Widget Function(T args) builder,
  }) {
    final args = settings.arguments;
    if (args is! T) {
      return _invalidArgumentsRoute(settings, expectedType: expectedType);
    }
    return _pageRoute(builder(args), settings: settings);
  }

  static Route<dynamic> _invalidArgumentsRoute(
    RouteSettings settings, {
    required String expectedType,
  }) {
    return _pageRoute(
      Scaffold(
        appBar: AppBar(title: const Text('Route Error')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Sai kiểu arguments cho route "${settings.name}". '
            'Expected: $expectedType. '
            'Actual: ${settings.arguments.runtimeType}.',
          ),
        ),
      ),
      settings: settings,
    );
  }
}
