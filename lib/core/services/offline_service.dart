// lib/core/services/offline_service.dart
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:tapsi/core/services/api_service.dart';
import 'package:tapsi/core/services/storage_service.dart';
import 'package:tapsi/core/utils/logger.dart';

class OfflineService {
  final ApiService _apiService;
  final StorageService _storageService;
  final Connectivity _connectivity = Connectivity();
  
  OfflineService({
    required ApiService apiService,
    required StorageService storageService,
  })  : _apiService = apiService,
        _storageService = storageService;

  // Verificar conexión
  Future<bool> isConnected() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // Obtener datos con estrategia cache-first
  Future<Map<String, dynamic>> getWithCache(
    String path, {
    Map<String, dynamic>? queryParameters,
    String? cacheKey,
    bool forceRefresh = false,
  }) async {
    final key = cacheKey ?? _generateCacheKey(path, queryParameters);
    
    // Si no forzar refresh, intentar con cache
    if (!forceRefresh) {
      final cached = await _storageService.getString('cache_$key');
      if (cached != null) {
        try {
          final data = jsonDecode(cached);
          final timestamp = DateTime.parse(data['timestamp']);
          final now = DateTime.now();
          
          // Cache válida por 5 minutos
          if (now.difference(timestamp).inMinutes < 5) {
            Logger.i('📦 Returning cached data for: $path');
            return data['data'];
          }
        } catch (e) {
          // Cache corrupta, eliminar
          await _storageService.remove('cache_$key');
        }
      }
    }
    
    // Si hay conexión, obtener datos frescos
    if (await isConnected()) {
      try {
        final response = await _apiService.get(path, queryParameters: queryParameters);
        
        // Guardar en cache
        final cacheData = {
          'data': response,
          'timestamp': DateTime.now().toIso8601String(),
        };
        await _storageService.saveString('cache_$key', jsonEncode(cacheData));
        
        Logger.i('💾 Cached fresh data for: $path');
        return response;
      } catch (e) {
        Logger.e('❌ Error fetching fresh data: $e');
        
        // Intentar con cache como fallback
        final cached = await _storageService.getString('cache_$key');
        if (cached != null) {
          try {
            final data = jsonDecode(cached);
            Logger.i('🔄 Falling back to cached data');
            return data['data'];
          } catch (_) {
            // Cache corrupta
          }
        }
        rethrow;
      }
    }
    
    // No hay conexión y no hay cache
    throw Exception('No connection and no cached data available');
  }

  // Agregar request a cola offline
  Future<void> addToOfflineQueue({
    required String method,
    required String path,
    required Map<String, dynamic> data,
    String? requestId,
  }) async {
    final request = {
      'id': requestId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'method': method,
      'path': path,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
      'retryCount': 0,
    };

    await _storageService.saveOfflineRequest(request['id'].toString(), jsonEncode(request));
    Logger.i('📥 Added to offline queue: $method $path');
  }

  // Procesar cola offline
  Future<void> processOfflineQueue() async {
    if (!await isConnected()) return;
    
    final requests = await _storageService.getOfflineRequests();
    
    for (final request in requests) {
      try {
        Logger.i('🔄 Processing queued request: ${request['method']} ${request['path']}');
        
        // Aquí implementarías el envío real
        // Por ahora solo simulamos
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Eliminar de la cola si fue exitoso
        await _storageService.removeOfflineRequest(request['id']);
        Logger.i('✅ Successfully processed: ${request['id']}');
      } catch (e) {
        final retryCount = request['retryCount'] ?? 0;
        if (retryCount >= 3) {
          // Máximo de reintentos, eliminar
          await _storageService.removeOfflineRequest(request['id']);
          Logger.e('❌ Max retries exceeded for request: ${request['id']}');
        } else {
          // Incrementar contador de reintentos
          request['retryCount'] = retryCount + 1;
          await _storageService.saveOfflineRequest(
            request['id'].toString(), 
            jsonEncode(request)
          );
          Logger.w('⚠️ Failed to process, will retry: ${request['id']}');
        }
      }
    }
  }

  // Helper para generar cache key
  String _generateCacheKey(String path, Map<String, dynamic>? queryParameters) {
    final params = queryParameters?.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    
    return params != null ? '$path?$params' : path;
  }

  // Stream de estado de conexión
  Stream<bool> get connectionStream => _connectivity.onConnectivityChanged
      .map((result) => result != ConnectivityResult.none);
}