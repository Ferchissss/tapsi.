import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';
import '../services/storage_service.dart';

class ThemeManager extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';
  
  final StorageService _storageService;
  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeMode get themeMode => _themeMode;
  
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;
  
  ThemeManager(this._storageService) {
    _loadTheme();
  }
  
  Future<void> _loadTheme() async {
    try {
      final savedTheme = await _storageService.getString(_themeKey);
      
      if (savedTheme != null) {
        switch (savedTheme) {
          case 'light':
            _themeMode = ThemeMode.light;
            break;
          case 'dark':
            _themeMode = ThemeMode.dark;
            break;
          case 'system':
            _themeMode = ThemeMode.system;
            break;
          default:
            _themeMode = ThemeMode.system;
        }
      } else {
        _themeMode = ThemeMode.system;
      }
      notifyListeners();
    } catch (e) {
      _themeMode = ThemeMode.system;
      notifyListeners();
    }
  }
  
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    
    try {
      String themeString;
      switch (mode) {
        case ThemeMode.light:
          themeString = 'light';
          break;
        case ThemeMode.dark:
          themeString = 'dark';
          break;
        case ThemeMode.system:
          themeString = 'system';
          break;
      }
      await _storageService.saveString(_themeKey, themeString);
    } catch (e) {
      // Error guardando preferencias
    }
  }
  
  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else {
      setThemeMode(ThemeMode.light);
    }
  }
  
  ThemeData getCurrentTheme(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    
    switch (_themeMode) {
      case ThemeMode.light:
        return AppTheme.lightTheme;
      case ThemeMode.dark:
        return AppTheme.darkTheme;
      case ThemeMode.system:
        return brightness == Brightness.dark 
            ? AppTheme.darkTheme 
            : AppTheme.lightTheme;
    }
  }
}