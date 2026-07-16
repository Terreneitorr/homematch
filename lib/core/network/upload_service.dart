import 'dart:io';
import 'package:dio/dio.dart';
import 'package:homematch_ai/core/network/dio_client.dart';
import 'package:homematch_ai/core/constants/api_constants.dart';

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
      // Retornamos la URL relativa que viene del servidor (ej: /uploads/abc.jpg)
      return response.data['url'] as String;
    } catch (e) {
      return null;
    }
  }

  /// Convierte una ruta relativa en una URL completa usando la IP actual.
  /// Si el path ya es una URL completa, intenta corregir la IP si es necesario.
  static String getFullUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    
    String cleanPath = path;
    
    // Si es una URL completa de una IP local, extraemos solo la parte del final (/uploads/...)
    // para reconstruirla con la IP configurada actualmente.
    if (path.startsWith('http')) {
      final uri = Uri.parse(path);
      if (uri.path.contains('/uploads/')) {
        // Extraer la ruta desde /uploads/ en adelante
        final index = uri.path.indexOf('/uploads/');
        cleanPath = uri.path.substring(index);
      } else {
        return path; // Es una URL externa (ej: google avatar), dejarla igual.
      }
    }

    // Asegurarse de que el path empiece con /
    final finalPath = cleanPath.startsWith('/') ? cleanPath : '/$cleanPath';
    return '${ApiConstants.baseUrl}$finalPath';
  }
}
