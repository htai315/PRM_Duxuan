class PublicShareResponseDto {
  final String shareId;
  final String slug;
  final String publicUrl;
  final String ownerToken;
  final int snapshotVersion;

  const PublicShareResponseDto({
    required this.shareId,
    required this.slug,
    required this.publicUrl,
    required this.ownerToken,
    this.snapshotVersion = 1,
  });

  factory PublicShareResponseDto.fromJson(Map<String, dynamic> json) {
    return PublicShareResponseDto(
      shareId: (json['shareId'] ?? json['id'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      publicUrl: (json['publicUrl'] ?? '').toString(),
      ownerToken: (json['ownerToken'] ?? '').toString(),
      snapshotVersion: (json['snapshotVersion'] as int?) ?? 1,
    );
  }
}
