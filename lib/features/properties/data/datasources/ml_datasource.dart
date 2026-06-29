import '../../../../core/network/dio_client.dart';

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
}