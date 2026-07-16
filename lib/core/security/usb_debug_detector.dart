import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class UsbDebugDetector {
  static const _channel = MethodChannel('com.example.homematch/security');

  static Future<bool> isUsbDebuggingEnabled() async {
    // IMPORTANTE: En modo debug de desarrollo (cuando corres desde Android Studio)
    // nunca bloqueamos la app para que puedas seguir trabajando.
    // PARA PROBAR EL BLOQUEO: Debes correr la app con 'flutter run --release'
    if (kDebugMode) {
      // Intentamos llamar al método solo para ver si hay errores en la consola
      _channel.invokeMethod<bool>('isAdbEnabled').then((value) {
        print('USB Debug Detector (Mock): ADB is ${value == true ? 'ON' : 'OFF'}');
      }).catchError((e) => print('USB Debug Detector Error: $e'));
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>('isAdbEnabled');
      return result ?? false;
    } catch (e) {
      print('Error al detectar depuración USB: $e');
      return false;
    }
  }
}