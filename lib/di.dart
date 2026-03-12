import 'package:du_xuan/data/implementations/api/activity_api.dart';
import 'package:du_xuan/data/implementations/api/auth_api.dart';
import 'package:du_xuan/data/implementations/api/checklist_api.dart';
import 'package:du_xuan/data/implementations/api/openai_service.dart';
import 'package:du_xuan/data/implementations/api/plan_api.dart';
import 'package:du_xuan/data/implementations/local/db/app_database.dart';
import 'package:du_xuan/data/implementations/mapper/activity_mapper.dart';
import 'package:du_xuan/data/implementations/mapper/auth_mapper.dart';
import 'package:du_xuan/data/implementations/mapper/checklist_mapper.dart';
import 'package:du_xuan/data/implementations/mapper/plan_mapper.dart';
import 'package:du_xuan/data/implementations/repositories/activity_repository.dart';
import 'package:du_xuan/data/implementations/repositories/auth_repository.dart';
import 'package:du_xuan/data/implementations/repositories/checklist_repository.dart';
import 'package:du_xuan/data/implementations/repositories/plan_repository.dart';
import 'package:du_xuan/viewmodels/checklist/checklist_viewmodel.dart';
import 'package:du_xuan/viewmodels/checklist/suggestion_viewmodel.dart';
import 'package:du_xuan/viewmodels/home/home_viewmodel.dart';
import 'package:du_xuan/viewmodels/itinerary/activity_form_viewmodel.dart';
import 'package:du_xuan/viewmodels/itinerary/itinerary_viewmodel.dart';
import 'package:du_xuan/viewmodels/login/login_viewmodel.dart';
import 'package:du_xuan/viewmodels/plan/plan_form_viewmodel.dart';
import 'package:du_xuan/viewmodels/plan/plan_list_viewmodel.dart';
import 'package:du_xuan/viewmodels/register/register_viewmodel.dart';
import 'package:du_xuan/viewmodels/settings/change_password_viewmodel.dart';
import 'package:du_xuan/data/implementations/api/geocoding_service.dart';
import 'package:du_xuan/viewmodels/map/map_viewmodel.dart';

// ─── Auth ──────────────────────────────────────────────

AuthRepository buildAuthRepository() {
  // Sử dụng SQLite Auth local
  final api = AuthApi(AppDatabase.instance);
  final mapper = AuthSessionMapper();
  return AuthRepository(api: api, mapper: mapper);
}

LoginViewModel buildLoginVM() => LoginViewModel(buildAuthRepository());
RegisterViewModel buildRegisterVM() => RegisterViewModel(buildAuthRepository());
HomeViewModel buildHomeVM() => HomeViewModel(buildAuthRepository());
ChangePasswordViewModel buildChangePasswordVM() =>
    ChangePasswordViewModel(buildAuthRepository());

// ─── Plan ──────────────────────────────────────────────

PlanRepository _buildPlanRepository() {
  final api = PlanApi(AppDatabase.instance);
  final planMapper = PlanMapper();
  final dayMapper = PlanDayMapper();
  return PlanRepository(api: api, planMapper: planMapper, dayMapper: dayMapper);
}

PlanListViewModel buildPlanListVM() => PlanListViewModel(_buildPlanRepository());
PlanFormViewModel buildPlanFormVM() => PlanFormViewModel(_buildPlanRepository());
PlanRepository buildPlanRepository() => _buildPlanRepository();

// ─── Itinerary ─────────────────────────────────────────

ActivityRepository _buildActivityRepository() {
  final api = ActivityApi(AppDatabase.instance);
  final mapper = ActivityMapper();
  return ActivityRepository(api: api, mapper: mapper);
}

ItineraryViewModel buildItineraryVM() => ItineraryViewModel(
      planRepo: _buildPlanRepository(),
      activityRepo: _buildActivityRepository(),
    );

ActivityFormViewModel buildActivityFormVM() =>
    ActivityFormViewModel(_buildActivityRepository());
ActivityRepository buildActivityRepository() => _buildActivityRepository();

// ─── Checklist ─────────────────────────────────────────

ChecklistRepository _buildChecklistRepository() {
  final api = ChecklistApi(AppDatabase.instance);
  final mapper = ChecklistMapper();
  return ChecklistRepository(api: api, mapper: mapper);
}

ChecklistViewModel buildChecklistVM() =>
    ChecklistViewModel(_buildChecklistRepository());
ChecklistRepository buildChecklistRepository() => _buildChecklistRepository();

// ─── AI Suggestion ─────────────────────────────────────

SuggestionViewModel buildSuggestionVM() => SuggestionViewModel(
      planRepo: _buildPlanRepository(),
      activityRepo: _buildActivityRepository(),
      checklistRepo: _buildChecklistRepository(),
      openAiService: OpenAiService(),
    );

// ─── Map ───────────────────────────────────────────────

MapViewModel buildMapVM() => MapViewModel(
      planRepo: _buildPlanRepository(),
      activityRepo: _buildActivityRepository(),
      geocodingService: GeocodingService(),
    );

