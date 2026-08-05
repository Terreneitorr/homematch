import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Maneja el modo de tema de toda la app (claro / oscuro / automático) y lo
/// guarda en el dispositivo para que la elección persista entre sesiones.
class ThemeViewModel extends ChangeNotifier {
  static const _prefsKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  ThemeViewModel() {
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    switch (saved) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      default:
      // Si nunca ha elegido nada, o eligió 'system', usamos el tema
      // del telefono automaticamente.
        _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    switch (mode) {
      case ThemeMode.light:
        await prefs.setString(_prefsKey, 'light');
        break;
      case ThemeMode.dark:
        await prefs.setString(_prefsKey, 'dark');
        break;
      case ThemeMode.system:
        await prefs.setString(_prefsKey, 'system');
        break;
    }
  }
}