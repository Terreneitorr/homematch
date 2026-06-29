import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/repositories/favorites_repository.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  final DioClient _client = DioClient();

  @override
  Future<List<String>> getFavoriteIds(String userId) async {
    try {
      final response = await _client.dio.get('/favorites/');
      return (response.data as List)
          .map((f) => f['property_id'] as String)
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> addFavorite(String userId, String propertyId) async {
    await _client.dio.post('/favorites/$propertyId');
  }

  @override
  Future<void> removeFavorite(String userId, String propertyId) async {
    await _client.dio.delete('/favorites/$propertyId');
  }

  @override
  Future<bool> isFavorite(String userId, String propertyId) async {
    final ids = await getFavoriteIds(userId);
    return ids.contains(propertyId);
  }
}