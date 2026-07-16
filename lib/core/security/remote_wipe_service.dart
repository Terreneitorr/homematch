import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class RemoteWipeService {
  static const _storage = FlutterSecureStorage();

  /// Realiza la limpieza total de datos locales.
  static Future<void> performWipe() async {
    try {
      developer.log('Iniciando Wipe Remoto...', name: 'RemoteWipeService');

      // 1. Limpiar Secure Storage (tokens, llaves sensibles)
      await _storage.deleteAll();
      
      // 2. Limpiar SharedPreferences (preferencias de usuario, caché)
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      developer.log('Wipe Remoto completado con éxito.', name: 'RemoteWipeService');
    } catch (e) {
      developer.log('Error durante el Wipe Remoto: $e', name: 'RemoteWipeService', error: e);
    }
  }
}
