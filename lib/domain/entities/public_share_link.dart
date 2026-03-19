class PublicShareLink {
  final int id;
  final int planId;
  final String shareId;
  final String slug;
  final String publicUrl;
  final String ownerToken;
  final int snapshotVersion;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastSyncedAt;
  final DateTime? revokedAt;

  const PublicShareLink({
    required this.id,
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

  bool get isRevoked => revokedAt != null;

  PublicShareLink copyWith({
    int? id,
    int? planId,
    String? shareId,
    String? slug,
    String? publicUrl,
    String? ownerToken,
    int? snapshotVersion,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSyncedAt,
    DateTime? revokedAt,
  }) {
    return PublicShareLink(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      shareId: shareId ?? this.shareId,
      slug: slug ?? this.slug,
      publicUrl: publicUrl ?? this.publicUrl,
      ownerToken: ownerToken ?? this.ownerToken,
      snapshotVersion: snapshotVersion ?? this.snapshotVersion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      revokedAt: revokedAt ?? this.revokedAt,
    );
  }
}
