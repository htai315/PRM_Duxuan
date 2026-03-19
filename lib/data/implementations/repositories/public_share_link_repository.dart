import 'package:du_xuan/data/dtos/share/create_public_share_link_request_dto.dart';
import 'package:du_xuan/data/dtos/share/public_share_link_dto.dart';
import 'package:du_xuan/data/dtos/share/update_public_share_link_request_dto.dart';
import 'package:du_xuan/data/interfaces/api/i_public_share_link_api.dart';
import 'package:du_xuan/data/interfaces/mapper/imapper.dart';
import 'package:du_xuan/data/interfaces/repositories/i_public_share_link_repository.dart';
import 'package:du_xuan/domain/entities/public_share_link.dart';

class PublicShareLinkRepository implements IPublicShareLinkRepository {
  final IPublicShareLinkApi _api;
  final IMapper<PublicShareLinkDto, PublicShareLink> _mapper;

  PublicShareLinkRepository({
    required IPublicShareLinkApi api,
    required IMapper<PublicShareLinkDto, PublicShareLink> mapper,
  }) : _api = api,
       _mapper = mapper;

  @override
  Future<PublicShareLink?> getByPlanId(int planId) async {
    final dto = await _api.getByPlanId(planId);
    if (dto == null) return null;
    return _mapper.map(dto);
  }

  @override
  Future<PublicShareLink?> getByShareId(String shareId) async {
    final dto = await _api.getByShareId(shareId);
    if (dto == null) return null;
    return _mapper.map(dto);
  }

  @override
  Future<PublicShareLink> create(PublicShareLink link) async {
    final req = CreatePublicShareLinkRequestDto(
      planId: link.planId,
      shareId: link.shareId,
      slug: link.slug,
      publicUrl: link.publicUrl,
      ownerToken: link.ownerToken,
      snapshotVersion: link.snapshotVersion,
      createdAt: link.createdAt.toIso8601String(),
      updatedAt: link.updatedAt.toIso8601String(),
      lastSyncedAt: link.lastSyncedAt.toIso8601String(),
      revokedAt: link.revokedAt?.toIso8601String(),
    );

    final id = await _api.create(req);
    final created = await _api.getById(id);
    return _mapper.map(created!);
  }

  @override
  Future<void> update(PublicShareLink link) async {
    final req = UpdatePublicShareLinkRequestDto(
      id: link.id,
      planId: link.planId,
      shareId: link.shareId,
      slug: link.slug,
      publicUrl: link.publicUrl,
      ownerToken: link.ownerToken,
      snapshotVersion: link.snapshotVersion,
      updatedAt: link.updatedAt.toIso8601String(),
      lastSyncedAt: link.lastSyncedAt.toIso8601String(),
      revokedAt: link.revokedAt?.toIso8601String(),
    );

    await _api.update(req);
  }

  @override
  Future<void> deleteByPlanId(int planId) async {
    await _api.deleteByPlanId(planId);
  }
}
