import '../entities/favorite_entity.dart';

abstract class FavoritesRepository {
  Future<List<String>> getFavoriteIds(String userId);
  Future<void> addFavorite(String userId, String propertyId);
  Future<void> removeFavorite(String userId, String propertyId);
  Future<bool> isFavorite(String userId, String propertyId);
}