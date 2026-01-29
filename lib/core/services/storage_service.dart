import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _themeKey = 'app_theme';
  static const String _localeKey = 'app_locale';
  static const String _firstLaunchKey = 'first_launch';
  static const String _fcmTokenKey = 'fcm_token';
  
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late SharedPreferences _prefs;

  static final StorageService _instance = StorageService._internal();
  
  factory StorageService() => _instance;
  
  StorageService._internal();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Token JWT
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }

  // Datos de usuario
  Future<void> saveUser(String userJson) async {
    await _prefs.setString(_userKey, userJson);
  }

  Future<String?> getUser() async {
    return _prefs.getString(_userKey);
  }

  Future<void> deleteUser() async {
    await _prefs.remove(_userKey);
  }

  // Tema de la app
  Future<void> saveTheme(String theme) async {
    await _prefs.setString(_themeKey, theme);
  }

  Future<String?> getTheme() async {
    return _prefs.getString(_themeKey);
  }

  // Primera ejecución
  Future<bool> isFirstLaunch() async {
    final firstLaunch = _prefs.getBool(_firstLaunchKey) ?? true;
    if (firstLaunch) {
      await _prefs.setBool(_firstLaunchKey, false);
    }
    return firstLaunch;
  }

  // FCM Token
  Future<void> saveFCMToken(String token) async {
    await _prefs.setString(_fcmTokenKey, token);
  }

  Future<String?> getFCMToken() async {
    return _prefs.getString(_fcmTokenKey);
  }

  // Métodos adicionales
  Future<void> saveBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  Future<bool?> getBool(String key) async {
    return _prefs.getBool(key);
  }

  Future<void> saveString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  Future<String?> getString(String key) async {
    return _prefs.getString(key);
  }

  Future<void> saveInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  Future<int?> getInt(String key) async {
    return _prefs.getInt(key);
  }

  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }
  Future<void> saveLocationCache(String key, String value) async {
    await _prefs.setString('location_$key', value);
  }

  Future<String?> getLocationCache(String key) async {
    return _prefs.getString('location_$key');
  }

  // Guardar caché de viajes
  Future<void> saveTripCache(String tripId, String tripJson) async {
    await _prefs.setString('trip_$tripId', tripJson);
    await _prefs.setString('trip_${tripId}_timestamp', 
      DateTime.now().toIso8601String());
  }

  Future<String?> getTripCache(String tripId) async {
    final timestamp = _prefs.getString('trip_${tripId}_timestamp');
    if (timestamp != null) {
      final cachedTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(cachedTime);
      
      // Cache válida por 5 minutos
      if (difference.inMinutes < 5) {
        return _prefs.getString('trip_$tripId');
      } else {
        await deleteTripCache(tripId);
      }
    }
    return null;
  }

  Future<void> deleteTripCache(String tripId) async {
    await _prefs.remove('trip_$tripId');
    await _prefs.remove('trip_${tripId}_timestamp');
  }

  // Queue para requests offline
  Future<void> saveOfflineRequest(String requestId, String requestJson) async {
    await _prefs.setString('offline_$requestId', requestJson);
  }

  Future<List<Map<String, dynamic>>> getOfflineRequests() async {
    final keys = _prefs.getKeys().where((key) => key.startsWith('offline_')).toList();
    final requests = <Map<String, dynamic>>[];
    
    for (final key in keys) {
      final json = _prefs.getString(key);
      if (json != null) {
        try {
          requests.add(jsonDecode(json));
        } catch (e) {
          await _prefs.remove(key);
        }
      }
    }
    
    return requests;
  }

  Future<void> removeOfflineRequest(String requestId) async {
    await _prefs.remove('offline_$requestId');
  }
  // Limpiar todo (logout)
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    await _prefs.clear();
  }
  Set<String> getKeys() {
    return _prefs.getKeys();
  }
}