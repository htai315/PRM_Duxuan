import 'package:du_xuan/data/implementations/api/activity_api.dart';
import 'package:du_xuan/data/implementations/api/auth_api.dart';
import 'package:du_xuan/data/implementations/api/checklist_api.dart';
import 'package:du_xuan/data/implementations/api/expense_api.dart';
import 'package:du_xuan/data/implementations/api/geocoding_service.dart';
import 'package:du_xuan/data/implementations/api/notification_api.dart';
import 'package:du_xuan/data/implementations/api/openai_service.dart';
import 'package:du_xuan/data/implementations/api/plan_api.dart';
import 'package:du_xuan/data/implementations/api/plan_copy_api.dart';
import 'package:du_xuan/data/implementations/api/plan_copy_source_api.dart';
import 'package:du_xuan/data/implementations/api/public_share_link_api.dart';
import 'package:du_xuan/data/implementations/api/public_share_remote_api.dart';
import 'package:du_xuan/data/implementations/api/user_api.dart';
import 'package:du_xuan/data/implementations/local/db/app_database.dart';
import 'package:du_xuan/data/implementations/mapper/activity_mapper.dart';
import 'package:du_xuan/data/implementations/mapper/auth_mapper.dart';
import 'package:du_xuan/data/implementations/mapper/checklist_mapper.dart';
import 'package:du_xuan/data/implementations/mapper/expense_mapper.dart';
import 'package:du_xuan/data/implementations/mapper/notification_mapper.dart';
import 'package:du_xuan/data/implementations/mapper/plan_copy_request_mapper.dart';
import 'package:du_xuan/data/implementations/mapper/plan_mapper.dart';
import 'package:du_xuan/data/implementations/mapper/plan_copy_source_mapper.dart';
import 'package:du_xuan/data/implementations/mapper/public_share_link_mapper.dart';
import 'package:du_xuan/data/implementations/mapper/user_mapper.dart';
import 'package:du_xuan/data/implementations/repositories/activity_repository.dart';
import 'package:du_xuan/data/implementations/repositories/auth_repository.dart';
import 'package:du_xuan/data/implementations/repositories/checklist_repository.dart';
import 'package:du_xuan/data/implementations/repositories/expense_repository.dart';
import 'package:du_xuan/data/implementations/repositories/notification_repository.dart';
import 'package:du_xuan/data/implementations/repositories/plan_copy_repository.dart';
import 'package:du_xuan/data/implementations/repositories/plan_copy_source_repository.dart';
import 'package:du_xuan/data/implementations/repositories/plan_repository.dart';
import 'package:du_xuan/data/implementations/repositories/public_share_link_repository.dart';
import 'package:du_xuan/data/implementations/repositories/user_repository.dart';
import 'package:du_xuan/core/utils/notification_service.dart';
import 'package:du_xuan/data/interfaces/repositories/i_expense_repository.dart';
import 'package:du_xuan/data/interfaces/repositories/i_plan_copy_repository.dart';
import 'package:du_xuan/data/interfaces/repositories/i_plan_copy_source_repository.dart';
import 'package:du_xuan/data/interfaces/repositories/i_public_share_link_repository.dart';
import 'package:du_xuan/data/interfaces/repositories/i_user_repository.dart';
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
import 'package:du_xuan/viewmodels/share/plan_copy_share_viewmodel.dart';
import 'package:du_xuan/viewmodels/share/plan_copy_request_viewmodel.dart';
import 'package:du_xuan/viewmodels/share/plan_copy_source_viewmodel.dart';
import 'package:du_xuan/viewmodels/settings/change_password_viewmodel.dart';
import 'package:du_xuan/viewmodels/share/public_share_viewmodel.dart';
import 'package:du_xuan/viewmodels/map/map_viewmodel.dart';

AppDatabase get _db => AppDatabase.instance;

// ─── Auth ──────────────────────────────────────────────

AuthRepository? _authRepository;

AuthRepository _buildAuthRepository() {
  _authRepository ??= AuthRepository(
    api: AuthApi(_db),
    mapper: AuthSessionMapper(),
  );
  return _authRepository!;
}

AuthRepository buildAuthRepository() => _buildAuthRepository();

LoginViewModel buildLoginVM() => LoginViewModel(_buildAuthRepository());
RegisterViewModel buildRegisterVM() =>
    RegisterViewModel(_buildAuthRepository());
HomeViewModel buildHomeVM() => HomeViewModel(_buildAuthRepository());
ChangePasswordViewModel buildChangePasswordVM() =>
    ChangePasswordViewModel(_buildAuthRepository());

UserRepository? _userRepository;

UserRepository _buildUserRepository() {
  _userRepository ??= UserRepository(api: UserApi(_db), mapper: UserMapper());
  return _userRepository!;
}

IUserRepository buildUserRepository() => _buildUserRepository();

// ─── Plan ──────────────────────────────────────────────

PlanRepository? _planRepository;

PlanRepository _buildPlanRepository() {
  _planRepository ??= PlanRepository(
    api: PlanApi(_db),
    planMapper: PlanMapper(),
    dayMapper: PlanDayMapper(),
  );
  return _planRepository!;
}

PlanListViewModel buildPlanListVM() =>
    PlanListViewModel(_buildPlanRepository(), buildNotificationService());
PlanFormViewModel buildPlanFormVM() =>
    PlanFormViewModel(_buildPlanRepository(), buildNotificationService());
PlanRepository buildPlanRepository() => _buildPlanRepository();

PlanCopyRepository? _planCopyRepository;

PlanCopyRepository _buildPlanCopyRepository() {
  _planCopyRepository ??= PlanCopyRepository(
    api: PlanCopyApi(_db),
    mapper: PlanCopyRequestMapper(),
  );
  return _planCopyRepository!;
}

IPlanCopyRepository buildPlanCopyRepository() => _buildPlanCopyRepository();

PlanCopySourceRepository? _planCopySourceRepository;

PlanCopySourceRepository _buildPlanCopySourceRepository() {
  _planCopySourceRepository ??= PlanCopySourceRepository(
    api: PlanCopySourceApi(_db),
    mapper: PlanCopySourceMapper(),
  );
  return _planCopySourceRepository!;
}

IPlanCopySourceRepository buildPlanCopySourceRepository() =>
    _buildPlanCopySourceRepository();

// ─── Itinerary ─────────────────────────────────────────

ActivityRepository? _activityRepository;

ActivityRepository _buildActivityRepository() {
  _activityRepository ??= ActivityRepository(
    api: ActivityApi(_db),
    mapper: ActivityMapper(),
  );
  return _activityRepository!;
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

ChecklistRepository? _checklistRepository;

ChecklistRepository _buildChecklistRepository() {
  _checklistRepository ??= ChecklistRepository(
    api: ChecklistApi(_db),
    mapper: ChecklistMapper(),
  );
  return _checklistRepository!;
}

ChecklistViewModel buildChecklistVM() =>
    ChecklistViewModel(_buildChecklistRepository());
ChecklistRepository buildChecklistRepository() => _buildChecklistRepository();

// ─── Expense ───────────────────────────────────────────

ExpenseRepository? _expenseRepository;

ExpenseRepository _buildExpenseRepository() {
  _expenseRepository ??= ExpenseRepository(
    api: ExpenseApi(_db),
    mapper: ExpenseMapper(),
  );
  return _expenseRepository!;
}

IExpenseRepository buildExpenseRepository() => _buildExpenseRepository();

ExpenseViewModel buildExpenseVM() =>
    ExpenseViewModel(_buildExpenseRepository());

NotificationRepository? _notificationRepository;

NotificationRepository _buildNotificationRepository() {
  _notificationRepository ??= NotificationRepository(
    api: NotificationApi(_db),
    mapper: NotificationMapper(),
  );
  return _notificationRepository!;
}

NotificationRepository buildNotificationRepository() =>
    _buildNotificationRepository();

NotificationViewModel buildNotificationVM() =>
    NotificationViewModel(_buildNotificationRepository());

NotificationService? _notificationService;

NotificationService buildNotificationService() {
  _notificationService ??= NotificationService(
    notificationRepo: _buildNotificationRepository(),
    planRepository: _buildPlanRepository(),
    activityRepository: _buildActivityRepository(),
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

PublicShareLinkRepository? _publicShareLinkRepository;

PublicShareLinkRepository _buildPublicShareLinkRepository() {
  _publicShareLinkRepository ??= PublicShareLinkRepository(
    api: PublicShareLinkApi(_db),
    mapper: PublicShareLinkMapper(),
  );
  return _publicShareLinkRepository!;
}

IPublicShareLinkRepository buildPublicShareLinkRepository() =>
    _buildPublicShareLinkRepository();

PublicShareRemoteApi _buildPublicShareRemoteApi() => PublicShareRemoteApi();

PublicShareViewModel buildPublicShareVM() => PublicShareViewModel(
  localRepository: _buildPublicShareLinkRepository(),
  remoteApi: _buildPublicShareRemoteApi(),
  planRepository: _buildPlanRepository(),
  activityRepository: _buildActivityRepository(),
  checklistRepository: _buildChecklistRepository(),
  expenseRepository: _buildExpenseRepository(),
);

PlanCopyShareViewModel buildPlanCopyShareVM() => PlanCopyShareViewModel(
  userRepository: _buildUserRepository(),
  planCopyRepository: _buildPlanCopyRepository(),
);

PlanCopyRequestViewModel buildPlanCopyRequestVM() =>
    PlanCopyRequestViewModel(_buildPlanCopyRepository());

PlanCopySourceViewModel buildPlanCopySourceVM() =>
    PlanCopySourceViewModel(_buildPlanCopySourceRepository());
