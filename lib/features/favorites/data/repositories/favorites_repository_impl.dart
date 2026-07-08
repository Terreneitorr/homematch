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
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> addFavorite(String userId, String propertyId) async {
    try {
      await _client.dio.post('/favorites/$propertyId');
    } on DioException catch (e) {
      // Si ya existe (400), ignorar
      if (e.response?.statusCode != 400) rethrow;
    }
  }

  @override
  Future<void> removeFavorite(String userId, String propertyId) async {
    try {
      await _client.dio.delete('/favorites/$propertyId');
    } catch (_) {}
  }

  @override
  Future<bool> isFavorite(String userId, String propertyId) async {
    final ids = await getFavoriteIds(userId);
    return ids.contains(propertyId);
  }
}