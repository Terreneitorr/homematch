class FavoriteEntity {
  final String id;
  final String userId;
  final String propertyId;
  final DateTime savedAt;

  const FavoriteEntity({
    required this.id,
    required this.userId,
    required this.propertyId,
    required this.savedAt,
  });
}