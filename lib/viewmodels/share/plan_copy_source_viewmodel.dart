import 'package:flutter/material.dart';
import 'package:du_xuan/data/interfaces/repositories/i_plan_copy_source_repository.dart';
import 'package:du_xuan/domain/entities/plan_copy_source.dart';

class PlanCopySourceViewModel extends ChangeNotifier {
  final IPlanCopySourceRepository _repository;

  PlanCopySourceViewModel(this._repository);

  PlanCopySource? _source;
  bool _isLoading = false;

  PlanCopySource? get source => _source;
  bool get isLoading => _isLoading;

  Future<void> loadSource(int targetPlanId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _source = await _repository.getByTargetPlanId(targetPlanId);
    } catch (_) {
      _source = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
