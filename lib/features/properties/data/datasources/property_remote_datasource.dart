import '../../../../core/network/dio_client.dart';
import '../models/property_model.dart';
import '../../domain/entities/property_entity.dart';

abstract class PropertyRemoteDataSource {
  Future<List<PropertyModel>> getProperties();
  Future<PropertyModel> getPropertyById(String id);
  Future<PropertyModel> createProperty(Map<String, dynamic> data);
  Future<void> deleteProperty(String id);
}

class PropertyRemoteDataSourceImpl implements PropertyRemoteDataSource {
  final DioClient _client = DioClient();

  @override
  Future<List<PropertyModel>> getProperties() async {
    final response = await _client.dio.get('/properties/');
    return (response.data as List)
        .map((json) => PropertyModel.fromJson(json))
        .toList();
  }

  @override
  Future<PropertyModel> getPropertyById(String id) async {
    final response = await _client.dio.get('/properties/$id');
    return PropertyModel.fromJson(response.data);
  }

  @override
  Future<PropertyModel> createProperty(Map<String, dynamic> data) async {
    final response = await _client.dio.post('/properties/', data: data);
    return PropertyModel.fromJson(response.data);
  }

  @override
  Future<void> deleteProperty(String id) async {
    await _client.dio.delete('/properties/$id');
  }
}