import 'package:flutter/material.dart';
import 'package:du_xuan/di.dart';
import 'package:du_xuan/domain/entities/activity.dart';
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
        return MaterialPageRoute(
          builder: (_) => SplashPage(authRepo: buildAuthRepository()),
        );
      case login:
        return MaterialPageRoute(
          builder: (_) => LoginPage(viewModel: buildLoginVM()),
        );
      case register:
        return MaterialPageRoute(
          builder: (_) => RegisterPage(viewModel: buildRegisterVM()),
        );
      case home:
        return MaterialPageRoute(
          builder: (_) => HomePage(viewModel: buildHomeVM()),
        );
      case planCreate:
        final userId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => PlanFormPage(
            viewModel: buildPlanFormVM(),
            userId: userId,
          ),
        );
      case planEdit:
        final planId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => PlanFormPage(
            viewModel: buildPlanFormVM(),
            userId: 0,
            editPlanId: planId,
          ),
        );
      case itinerary:
        final planId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => PlanDetailPage(
            viewModel: buildItineraryVM(),
            planId: planId,
          ),
        );
      case activityCreate:
        final planDayId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => ActivityFormPage(
            viewModel: buildActivityFormVM(),
            planDayId: planDayId,
          ),
        );
      case activityEdit:
        final activity = settings.arguments as Activity;
        return MaterialPageRoute(
          builder: (_) => ActivityFormPage(
            viewModel: buildActivityFormVM(),
            planDayId: activity.planDayId,
            existingActivity: activity,
          ),
        );
      case checklist:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ChecklistPage(
            viewModel: buildChecklistVM(),
            planId: args['planId'] as int,
            planName: args['planName'] as String,
          ),
        );
      case changePassword:
        final userId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => ChangePasswordPage(
            viewModel: buildChangePasswordVM(),
            userId: userId,
          ),
        );
      case notifications:
        final userId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => NotificationPage(
            viewModel: buildNotificationVM(),
            userId: userId,
            notificationService: buildNotificationService(),
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => LoginPage(viewModel: buildLoginVM()),
        );
    }
  }
}
