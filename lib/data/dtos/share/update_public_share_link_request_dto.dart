class UpdatePublicShareLinkRequestDto {
  final int id;
  final int planId;
  final String shareId;
  final String slug;
  final String publicUrl;
  final String ownerToken;
  final int snapshotVersion;
  final String updatedAt;
  final String lastSyncedAt;
  final String? revokedAt;

  const UpdatePublicShareLinkRequestDto({
    required this.id,
    required this.planId,
    required this.shareId,
    required this.slug,
    required this.publicUrl,
    required this.ownerToken,
    this.snapshotVersion = 1,
    required this.updatedAt,
    required this.lastSyncedAt,
    this.revokedAt,
  });

  Map<String, dynamic> toMap() => {
    'plan_id': planId,
    'share_id': shareId,
    'slug': slug,
    'public_url': publicUrl,
    'owner_token': ownerToken,
    'snapshot_version': snapshotVersion,
    'updated_at': updatedAt,
    'last_synced_at': lastSyncedAt,
    'revoked_at': revokedAt,
  };
}
