import 'dart:io';
import 'package:dio/dio.dart';
import 'package:homematch_ai/core/network/dio_client.dart';
import 'package:homematch_ai/core/constants/api_constants.dart';

class UploadService {
  final DioClient _client = DioClient();

  /// context: pasa 'property' cuando subas fotos de una propiedad, para
  /// que el backend también revise que la imagen parezca ser de una
  /// propiedad (además del filtro de contenido inapropiado, que aplica
  /// siempre). Déjalo null para fotos de perfil.
  Future<String?> uploadImage(File file, {String? context}) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
        if (context != null) 'context': context,
      });
      final response = await _client.dio.post('/uploads/', data: formData);
      // Retornamos la URL relativa que viene del servidor (ej: /uploads/abc.jpg)
      return response.data['url'] as String;
    } on DioException catch (e) {
      // Si el backend rechazó la imagen (contenido inapropiado, no parece
      // propiedad, tipo/tamaño inválido), propagamos el mensaje exacto
      // para que la pantalla que llama pueda mostrárselo al usuario.
      final detail = e.response?.data is Map
          ? e.response?.data['detail']
          : null;
      throw Exception(detail ?? 'No se pudo subir la imagen');
    } catch (e) {
      throw Exception('No se pudo subir la imagen');
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