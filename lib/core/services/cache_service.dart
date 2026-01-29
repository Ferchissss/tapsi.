// lib/core/services/cache_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:tapsi/core/services/storage_service.dart';

class CacheService {
  final StorageService _storageService;

  CacheService(this._storageService);

  // Guardar datos en caché
  Future<void> saveData(String key, Map<String, dynamic> data, {
    Duration duration = const Duration(minutes: 5),
  }) async {
    final cacheData = {
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
      'expiresIn': duration.inSeconds,
    };
    
    await _storageService.saveString('cache_$key', jsonEncode(cacheData));
  }

  // Obtener datos de caché
  Future<Map<String, dynamic>?> getData(String key) async {
    final json = await _storageService.getString('cache_$key');
    if (json == null) return null;

    try {
      final cacheData = jsonDecode(json);
      final timestamp = DateTime.parse(cacheData['timestamp']);
      final expiresIn = Duration(seconds: cacheData['expiresIn']);
      final now = DateTime.now();

      if (now.difference(timestamp) < expiresIn) {
        return cacheData['data'];
      } else {
        // Cache expirada
        await deleteData(key);
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error reading cache: $e');
      }
      await deleteData(key);
      return null;
    }
  }

  // Eliminar datos de caché
  Future<void> deleteData(String key) async {
    await _storageService.remove('cache_$key');
  }

  // Limpiar toda la caché
  Future<void> clearAll() async {
    final keys = await _storageService.getKeys();
    final cacheKeys = keys.where((key) => key.startsWith('cache_')).toList();
    
    for (final key in cacheKeys) {
      await _storageService.remove(key);
    }
  }

  // Obtener estadísticas
  Future<Map<String, dynamic>> getStats() async {
    final keys = await _storageService.getKeys();
    final cacheKeys = keys.where((key) => key.startsWith('cache_')).toList();
    
    return {
      'totalItems': cacheKeys.length,
      'keys': cacheKeys,
    };
  }
}