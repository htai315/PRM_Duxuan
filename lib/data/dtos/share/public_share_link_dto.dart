class PublicShareLinkDto {
  final int? id;
  final int planId;
  final String shareId;
  final String slug;
  final String publicUrl;
  final String ownerToken;
  final int snapshotVersion;
  final String createdAt;
  final String updatedAt;
  final String lastSyncedAt;
  final String? revokedAt;

  const PublicShareLinkDto({
    this.id,
    required this.planId,
    required this.shareId,
    required this.slug,
    required this.publicUrl,
    required this.ownerToken,
    this.snapshotVersion = 1,
    required this.createdAt,
    required this.updatedAt,
    required this.lastSyncedAt,
    this.revokedAt,
  });

  factory PublicShareLinkDto.fromMap(Map<String, dynamic> map) {
    return PublicShareLinkDto(
      id: map['id'] as int?,
      planId: map['plan_id'] as int,
      shareId: (map['share_id'] ?? '').toString(),
      slug: (map['slug'] ?? '').toString(),
      publicUrl: (map['public_url'] ?? '').toString(),
      ownerToken: (map['owner_token'] ?? '').toString(),
      snapshotVersion: (map['snapshot_version'] as int?) ?? 1,
      createdAt: (map['created_at'] ?? '').toString(),
      updatedAt: (map['updated_at'] ?? '').toString(),
      lastSyncedAt: (map['last_synced_at'] ?? '').toString(),
      revokedAt: map['revoked_at']?.toString(),
    );
  }
}
