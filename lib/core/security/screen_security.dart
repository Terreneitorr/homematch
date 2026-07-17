import 'package:flutter/services.dart';

class ScreenSecurity {
  static const _channel = MethodChannel('com.example.homematch/security');

  static Future<void> enableSecure() async {
    try {
      await _channel.invokeMethod('enableSecureScreen');
    } catch (_) {}
  }

  static Future<void> disableSecure() async {
    try {
      await _channel.invokeMethod('disableSecureScreen');
    } catch (_) {}
  }
}