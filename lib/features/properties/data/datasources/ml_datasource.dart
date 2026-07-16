import 'package:homematch_ai/core/network/dio_client.dart';

class MLDataSource {
  final DioClient _client = DioClient();

  Future<Map<String, dynamic>> classifyProperty({
    required double precio,
    required int habitaciones,
    required int banos,
    required double metros,
    required String tipo,
  }) async {
    try {
      final response = await _client.mlDio.post('/classify-property', data: {
        'precio': precio,
        'habitaciones': habitaciones,
        'banos': banos,
        'metros': metros,
        'tipo': tipo,
      });
      return response.data;
    } catch (e) {
      return {'cluster': 0, 'segmento': 'Sin clasificar'};
    }
  }

  Future<List<Map<String, dynamic>>> getRecommendations({
    required List<String> favoriteIds,
    int limit = 6,
  }) async {
    try {
      final response = await _client.mlDio.post('/recommend', data: {
        'favorite_ids': favoriteIds,
        'limit': limit,
      });
      final List<dynamic> recs = response.data['recommendations'] ?? [];
      return recs.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      return [];
    }
  }
}
