class CreatePublicShareRequestDto {
  final String title;
  final int snapshotVersion;
  final Map<String, dynamic> snapshot;

  const CreatePublicShareRequestDto({
    required this.title,
    this.snapshotVersion = 1,
    required this.snapshot,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'snapshotVersion': snapshotVersion,
    'snapshot': snapshot,
  };
}
