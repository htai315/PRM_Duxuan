import 'package:du_xuan/core/utils/plan_share_snapshot_builder.dart';
import 'package:du_xuan/data/dtos/share/create_public_share_request_dto.dart';
import 'package:du_xuan/data/dtos/share/update_public_share_request_dto.dart';
import 'package:du_xuan/data/interfaces/api/i_public_share_remote_api.dart';
import 'package:du_xuan/data/interfaces/repositories/i_public_share_link_repository.dart';
import 'package:du_xuan/domain/entities/public_share_link.dart';
import 'package:flutter/material.dart';

class PublicShareViewModel extends ChangeNotifier {
  final IPublicShareLinkRepository _localRepository;
  final IPublicShareRemoteApi _remoteApi;

  PublicShareViewModel({
    required IPublicShareLinkRepository localRepository,
    required IPublicShareRemoteApi remoteApi,
  }) : _localRepository = localRepository,
       _remoteApi = remoteApi;

  PublicShareLink? _link;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  int? _loadedPlanId;

  PublicShareLink? get link => _link;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  bool get hasActiveLink => _link != null && !_link!.isRevoked;

  Future<void> loadLink(int planId, {bool refresh = false}) async {
    if (_isLoading && !refresh && _loadedPlanId == planId) return;

    _isLoading = true;
    notifyListeners();

    try {
      _link = await _localRepository.getByPlanId(planId);
      _loadedPlanId = planId;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = _normalizeError(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<PublicShareLink?> createLink(int planId) async {
    if (_isSubmitting) return null;

    _isSubmitting = true;
    notifyListeners();

    try {
      final snapshot = await PlanShareSnapshotBuilder.buildJson(planId);
      if (snapshot == null) {
        throw Exception('Không tìm thấy kế hoạch để tạo link công khai.');
      }

      final title = _extractTitle(snapshot);
      final response = await _remoteApi.create(
        CreatePublicShareRequestDto(title: title, snapshot: snapshot),
      );
      final now = DateTime.now();

      final existing = await _localRepository.getByPlanId(planId);
      if (existing == null) {
        _link = await _localRepository.create(
          PublicShareLink(
            id: 0,
            planId: planId,
            shareId: response.shareId,
            slug: response.slug,
            publicUrl: response.publicUrl,
            ownerToken: response.ownerToken,
            snapshotVersion: response.snapshotVersion,
            createdAt: now,
            updatedAt: now,
            lastSyncedAt: now,
          ),
        );
      } else {
        final updated = PublicShareLink(
          id: existing.id,
          planId: existing.planId,
          shareId: response.shareId,
          slug: response.slug,
          publicUrl: response.publicUrl,
          ownerToken: response.ownerToken,
          snapshotVersion: response.snapshotVersion,
          createdAt: existing.createdAt,
          updatedAt: now,
          lastSyncedAt: now,
          revokedAt: null,
        );
        await _localRepository.update(updated);
        _link = updated;
      }

      _errorMessage = null;
      return _link;
    } catch (e) {
      _errorMessage = _normalizeError(e);
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<PublicShareLink?> updateLink(int planId) async {
    if (_isSubmitting) return null;

    final existing = _link ?? await _localRepository.getByPlanId(planId);
    if (existing == null || existing.isRevoked) {
      return createLink(planId);
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      final snapshot = await PlanShareSnapshotBuilder.buildJson(planId);
      if (snapshot == null) {
        throw Exception('Không tìm thấy kế hoạch để cập nhật link.');
      }

      final title = _extractTitle(snapshot);
      final response = await _remoteApi.update(
        existing,
        UpdatePublicShareRequestDto(title: title, snapshot: snapshot),
      );
      final now = DateTime.now();

      final updated = PublicShareLink(
        id: existing.id,
        planId: existing.planId,
        shareId: response.shareId,
        slug: response.slug,
        publicUrl: response.publicUrl,
        ownerToken: response.ownerToken,
        snapshotVersion: response.snapshotVersion,
        createdAt: existing.createdAt,
        updatedAt: now,
        lastSyncedAt: now,
        revokedAt: null,
      );
      await _localRepository.update(updated);
      _link = updated;
      _errorMessage = null;
      return updated;
    } catch (e) {
      _errorMessage = _normalizeError(e);
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> revokeLink(int planId) async {
    if (_isSubmitting) return false;

    final existing = _link ?? await _localRepository.getByPlanId(planId);
    if (existing == null || existing.isRevoked) {
      _errorMessage = 'Kế hoạch này chưa có link công khai đang hoạt động.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      await _remoteApi.revoke(existing);
      final now = DateTime.now();
      final revoked = PublicShareLink(
        id: existing.id,
        planId: existing.planId,
        shareId: existing.shareId,
        slug: existing.slug,
        publicUrl: existing.publicUrl,
        ownerToken: existing.ownerToken,
        snapshotVersion: existing.snapshotVersion,
        createdAt: existing.createdAt,
        updatedAt: now,
        lastSyncedAt: now,
        revokedAt: now,
      );
      await _localRepository.update(revoked);
      _link = revoked;
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = _normalizeError(e);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _extractTitle(Map<String, dynamic> snapshot) {
    final plan = snapshot['plan'];
    if (plan is Map<String, dynamic>) {
      final title = plan['name']?.toString().trim() ?? '';
      if (title.isNotEmpty) return title;
    }
    return 'Kế hoạch chuyến đi';
  }

  String _normalizeError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
