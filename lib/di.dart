import 'package:du_xuan/data/implementations/api/activity_api.dart';
import 'package:du_xuan/data/implementations/api/auth_api.dart';
import 'package:du_xuan/data/implementations/api/checklist_api.dart';
import 'package:du_xuan/data/implementations/api/expense_api.dart';
import 'package:du_xuan/data/implementations/api/geocoding_service.dart';
import 'package:du_xuan/data/implementations/api/notification_api.dart';
import 'package:du_xuan/data/implementations/api/openai_service.dart';
import 'package:du_xuan/data/implementations/api/plan_api.dart';
import 'package:du_xuan/data/implementations/api/public_share_link_api.dart';
import 'package:du_xuan/data/implementations/api/public_share_remote_api.dart';
import 'package:du_xuan/data/implementations/local/db/app_database.dart';
import 'package:du_xuan/data/implementations/mapper/activity_mapper.dart';
import 'package:du_xuan/data/implementations/mapper/auth_mapper.dart';
import 'package:du_xuan/data/implementations/mapper/checklist_mapper.dart';
import 'package:du_xuan/data/implementations/mapper/expense_mapper.dart';
import 'package:du_xuan/data/implementations/mapper/notification_mapper.dart';
import 'package:du_xuan/data/implementations/mapper/plan_mapper.dart';
import 'package:du_xuan/data/implementations/mapper/public_share_link_mapper.dart';
import 'package:du_xuan/data/implementations/repositories/activity_repository.dart';
import 'package:du_xuan/data/implementations/repositories/auth_repository.dart';
import 'package:du_xuan/data/implementations/repositories/checklist_repository.dart';
import 'package:du_xuan/data/implementations/repositories/expense_repository.dart';
import 'package:du_xuan/data/implementations/repositories/notification_repository.dart';
import 'package:du_xuan/data/implementations/repositories/plan_repository.dart';
import 'package:du_xuan/data/implementations/repositories/public_share_link_repository.dart';
import 'package:du_xuan/core/utils/notification_service.dart';
import 'package:du_xuan/data/interfaces/repositories/i_expense_repository.dart';
import 'package:du_xuan/data/interfaces/repositories/i_public_share_link_repository.dart';
import 'package:du_xuan/viewmodels/checklist/checklist_viewmodel.dart';
import 'package:du_xuan/viewmodels/checklist/suggestion_viewmodel.dart';
import 'package:du_xuan/viewmodels/expense/expense_viewmodel.dart';
import 'package:du_xuan/viewmodels/home/home_viewmodel.dart';
import 'package:du_xuan/viewmodels/itinerary/activity_form_viewmodel.dart';
import 'package:du_xuan/viewmodels/itinerary/itinerary_viewmodel.dart';
import 'package:du_xuan/viewmodels/login/login_viewmodel.dart';
import 'package:du_xuan/viewmodels/notification/notification_viewmodel.dart';
import 'package:du_xuan/viewmodels/plan/plan_form_viewmodel.dart';
import 'package:du_xuan/viewmodels/plan/plan_list_viewmodel.dart';
import 'package:du_xuan/viewmodels/register/register_viewmodel.dart';
import 'package:du_xuan/viewmodels/settings/change_password_viewmodel.dart';
import 'package:du_xuan/viewmodels/share/public_share_viewmodel.dart';
import 'package:du_xuan/viewmodels/map/map_viewmodel.dart';

AppDatabase get _db => AppDatabase.instance;

// ─── Auth ──────────────────────────────────────────────

AuthRepository _buildAuthRepository() {
  final api = AuthApi(_db);
  final mapper = AuthSessionMapper();
  return AuthRepository(api: api, mapper: mapper);
}

AuthRepository buildAuthRepository() => _buildAuthRepository();

LoginViewModel buildLoginVM() => LoginViewModel(_buildAuthRepository());
RegisterViewModel buildRegisterVM() =>
    RegisterViewModel(_buildAuthRepository());
HomeViewModel buildHomeVM() => HomeViewModel(_buildAuthRepository());
ChangePasswordViewModel buildChangePasswordVM() =>
    ChangePasswordViewModel(_buildAuthRepository());

// ─── Plan ──────────────────────────────────────────────

PlanRepository _buildPlanRepository() {
  final api = PlanApi(_db);
  final planMapper = PlanMapper();
  final dayMapper = PlanDayMapper();
  return PlanRepository(api: api, planMapper: planMapper, dayMapper: dayMapper);
}

PlanListViewModel buildPlanListVM() =>
    PlanListViewModel(_buildPlanRepository(), buildNotificationService());
PlanFormViewModel buildPlanFormVM() =>
    PlanFormViewModel(_buildPlanRepository(), buildNotificationService());
PlanRepository buildPlanRepository() => _buildPlanRepository();

// ─── Itinerary ─────────────────────────────────────────

ActivityRepository _buildActivityRepository() {
  final api = ActivityApi(_db);
  final mapper = ActivityMapper();
  return ActivityRepository(api: api, mapper: mapper);
}

ItineraryViewModel buildItineraryVM() => ItineraryViewModel(
  planRepo: _buildPlanRepository(),
  activityRepo: _buildActivityRepository(),
  notificationService: buildNotificationService(),
);

ActivityFormViewModel buildActivityFormVM() =>
    ActivityFormViewModel(_buildActivityRepository());
ActivityRepository buildActivityRepository() => _buildActivityRepository();

// ─── Checklist ─────────────────────────────────────────

ChecklistRepository _buildChecklistRepository() {
  final api = ChecklistApi(_db);
  final mapper = ChecklistMapper();
  return ChecklistRepository(api: api, mapper: mapper);
}

ChecklistViewModel buildChecklistVM() =>
    ChecklistViewModel(_buildChecklistRepository());
ChecklistRepository buildChecklistRepository() => _buildChecklistRepository();

// ─── Expense ───────────────────────────────────────────

ExpenseRepository _buildExpenseRepository() {
  final api = ExpenseApi(_db);
  final mapper = ExpenseMapper();
  return ExpenseRepository(api: api, mapper: mapper);
}

IExpenseRepository buildExpenseRepository() => _buildExpenseRepository();

ExpenseViewModel buildExpenseVM() =>
    ExpenseViewModel(_buildExpenseRepository());

NotificationRepository _buildNotificationRepository() {
  final api = NotificationApi(_db);
  final mapper = NotificationMapper();
  return NotificationRepository(api: api, mapper: mapper);
}

NotificationRepository buildNotificationRepository() =>
    _buildNotificationRepository();

NotificationViewModel buildNotificationVM() =>
    NotificationViewModel(_buildNotificationRepository());

NotificationService? _notificationService;

NotificationService buildNotificationService() {
  _notificationService ??= NotificationService(
    notificationRepo: _buildNotificationRepository(),
  );
  return _notificationService!;
}

// ─── AI Suggestion ─────────────────────────────────────

OpenAiService _buildOpenAiService() => OpenAiService();

SuggestionViewModel buildSuggestionVM() => SuggestionViewModel(
  planRepo: _buildPlanRepository(),
  activityRepo: _buildActivityRepository(),
  checklistRepo: _buildChecklistRepository(),
  openAiService: _buildOpenAiService(),
);

// ─── Map ───────────────────────────────────────────────

GeocodingService _buildGeocodingService() => GeocodingService();

MapViewModel buildMapVM() => MapViewModel(
  planRepo: _buildPlanRepository(),
  activityRepo: _buildActivityRepository(),
  geocodingService: _buildGeocodingService(),
);

// ─── Public Share ─────────────────────────────────────

PublicShareLinkRepository _buildPublicShareLinkRepository() {
  final api = PublicShareLinkApi(_db);
  final mapper = PublicShareLinkMapper();
  return PublicShareLinkRepository(api: api, mapper: mapper);
}

IPublicShareLinkRepository buildPublicShareLinkRepository() =>
    _buildPublicShareLinkRepository();

PublicShareRemoteApi _buildPublicShareRemoteApi() => PublicShareRemoteApi();

PublicShareViewModel buildPublicShareVM() => PublicShareViewModel(
  localRepository: _buildPublicShareLinkRepository(),
  remoteApi: _buildPublicShareRemoteApi(),
);
