import 'dart:io';
import 'package:dio/dio.dart';
import 'dio_client.dart';
import '../constants/api_constants.dart';

class UploadService {
  final DioClient _client = DioClient();

  Future<String?> uploadImage(File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });
      final response = await _client.dio.post('/uploads/', data: formData);
      final url = response.data['url'] as String;
      return '${ApiConstants.baseUrl}$url';
    } catch (e) {
      return null;
    }
  }

  String getFullUrl(String path) {
    if (path.startsWith('http')) return path;
    return '${ApiConstants.baseUrl}$path';
  }
}