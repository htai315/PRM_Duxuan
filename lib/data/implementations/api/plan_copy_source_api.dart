import 'package:du_xuan/data/dtos/share/plan_copy_source_dto.dart';
import 'package:du_xuan/data/implementations/local/db/app_database.dart';
import 'package:du_xuan/data/interfaces/api/i_plan_copy_source_api.dart';

class PlanCopySourceApi implements IPlanCopySourceApi {
  final AppDatabase _database;

  PlanCopySourceApi(this._database);

  @override
  Future<PlanCopySourceDto?> getByTargetPlanId(int targetPlanId) async {
    final db = await _database.db;
    final rows = await db.rawQuery(
      '''
      SELECT
        pcs.id,
        pcs.source_plan_id,
        pcs.source_user_id,
        pcs.target_plan_id,
        pcs.target_user_id,
        pcs.created_at,
        u.user_name AS source_user_name,
        u.full_name AS source_user_full_name
      FROM plan_copy_sources pcs
      INNER JOIN users u ON u.id = pcs.source_user_id
      WHERE pcs.target_plan_id = ?
      LIMIT 1
      ''',
      [targetPlanId],
    );
    if (rows.isEmpty) return null;
    return PlanCopySourceDto.fromMap(rows.first);
  }
}
