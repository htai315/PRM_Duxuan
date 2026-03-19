import 'package:flutter/material.dart';
import 'package:du_xuan/data/interfaces/repositories/i_plan_copy_repository.dart';
import 'package:du_xuan/domain/entities/plan_copy_request.dart';

class PlanCopyRequestViewModel extends ChangeNotifier {
  final IPlanCopyRepository _repository;

  PlanCopyRequestViewModel(this._repository);

  final Map<int, PlanCopyRequest> _requestsById = {};
  final Set<int> _submittingIds = <int>{};
  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  PlanCopyRequest? requestFor(int requestId) => _requestsById[requestId];

  bool isSubmitting(int requestId) => _submittingIds.contains(requestId);

  Future<void> loadRequestsByIds(List<int> requestIds) async {
    final uniqueIds = requestIds.toSet().toList();
    if (uniqueIds.isEmpty) return;

    try {
      final requests = await _repository.getRequestsByIds(uniqueIds);
      for (final request in requests) {
        _requestsById[request.id] = request;
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  Future<int?> acceptRequest({
    required int requestId,
    required int targetUserId,
  }) async {
    if (_submittingIds.contains(requestId)) return null;

    _submittingIds.add(requestId);
    _errorMessage = null;
    notifyListeners();

    try {
      final newPlanId = await _repository.acceptCopyRequest(
        requestId: requestId,
        targetUserId: targetUserId,
      );
      final updated = await _repository.getRequestById(requestId);
      if (updated != null) {
        _requestsById[requestId] = updated;
      }
      _submittingIds.remove(requestId);
      notifyListeners();
      return newPlanId;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _submittingIds.remove(requestId);
      notifyListeners();
      return null;
    }
  }

  Future<bool> rejectRequest({
    required int requestId,
    required int targetUserId,
  }) async {
    if (_submittingIds.contains(requestId)) return false;

    _submittingIds.add(requestId);
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.rejectCopyRequest(
        requestId: requestId,
        targetUserId: targetUserId,
      );
      final updated = await _repository.getRequestById(requestId);
      if (updated != null) {
        _requestsById[requestId] = updated;
      }
      _submittingIds.remove(requestId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _submittingIds.remove(requestId);
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }
}
