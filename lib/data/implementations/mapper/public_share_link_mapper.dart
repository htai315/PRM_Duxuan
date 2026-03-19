import 'package:du_xuan/data/dtos/share/public_share_link_dto.dart';
import 'package:du_xuan/data/interfaces/mapper/imapper.dart';
import 'package:du_xuan/domain/entities/public_share_link.dart';

class PublicShareLinkMapper
    implements IMapper<PublicShareLinkDto, PublicShareLink> {
  @override
  PublicShareLink map(PublicShareLinkDto input) {
    return PublicShareLink(
      id: input.id ?? 0,
      planId: input.planId,
      shareId: input.shareId,
      slug: input.slug,
      publicUrl: input.publicUrl,
      ownerToken: input.ownerToken,
      snapshotVersion: input.snapshotVersion,
      createdAt: DateTime.parse(input.createdAt),
      updatedAt: DateTime.parse(input.updatedAt),
      lastSyncedAt: DateTime.parse(input.lastSyncedAt),
      revokedAt: input.revokedAt != null
          ? DateTime.parse(input.revokedAt!)
          : null,
    );
  }
}
