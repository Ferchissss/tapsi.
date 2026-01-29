// lib/core/providers/app_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tapsi/core/services/api_service.dart';
import 'package:tapsi/core/services/storage_service.dart';
import 'package:tapsi/core/services/socket_service.dart';
import 'package:tapsi/core/services/offline_service.dart';
import 'package:tapsi/data/models/user_model.dart';
import 'package:tapsi/data/models/trip_model.dart';
import 'package:tapsi/core/utils/logger.dart';

class AppProvider with ChangeNotifier {
  final StorageService _storageService;
  final ApiService _apiService;
  final SocketService _socketService;
  final OfflineService _offlineService;

  UserModel? _currentUser;
  TripModel? _activeTrip;
  bool _isLoading = false;
  String? _error;
  bool _isConnected = true;

  AppProvider({
    required StorageService storageService,
    required ApiService apiService,
    required SocketService socketService,
    required OfflineService offlineService,
  })  : _storageService = storageService,
        _apiService = apiService,
        _socketService = socketService,
        _offlineService = offlineService {
    _initialize();
  }

  // Getters
  UserModel? get currentUser => _currentUser;
  TripModel? get activeTrip => _activeTrip;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isConnected => _isConnected;
  bool get isAuthenticated => _currentUser != null;

  // Inicializar
  Future<void> _initialize() async {
    _setupConnectionListener();
    await _loadUser();
  }

  // Configurar listener de conexión
  void _setupConnectionListener() {
    _offlineService.connectionStream.listen((connected) {
      if (_isConnected != connected) {
        _isConnected = connected;
        if (connected) {
          // Reconectar socket y procesar cola offline
          _socketService.connect();
          _offlineService.processOfflineQueue();
        }
        notifyListeners();
      }
    });
  }

  // Cargar usuario desde storage
  Future<void> _loadUser() async {
    try {
      final userJson = await _storageService.getUser();
      if (userJson != null) {
        final userMap = json.decode(userJson);
        _currentUser = UserModel.fromJson(userMap);
        
        // Conectar socket si hay usuario
        if (_isConnected) {
          _socketService.connect();
        }
      }
    } catch (e) {
      Logger.e('Error loading user: $e');
    }
  }

  // Login
  Future<bool> login(String phone, String code) async {
    try {
      _setLoading(true);
      _error = null;

      final result = await _apiService.verifyCode(phone, code);
      
      if (result['success'] == true) {
        final data = result['data'];
        final token = data['token'];
        final userData = data['user'];
        
        // Guardar token y usuario
        await _storageService.saveToken(token);
        await _storageService.saveUser(json.encode(userData));
        
        _currentUser = UserModel.fromJson(userData);
        
        // Conectar socket
        if (_isConnected) {
          _socketService.connect();
        }
        
        return true;
      } else {
        _error = result['error'] ?? 'Error en el login';
        return false;
      }
    } catch (e) {
      _error = 'Error de conexión';
      return false;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      _setLoading(true);
      
      // Desconectar socket
      _socketService.disconnect();
      
      // Limpiar storage
      await _storageService.clearAll();
      
      _currentUser = null;
      _activeTrip = null;
      _error = null;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Actualizar perfil
  Future<bool> updateProfile(String name, {String? email}) async {
    try {
      _setLoading(true);
      
      final response = await _apiService.put(
        '/api/v1/users/me',
        data: {
          'name': name,
          if (email != null && email.isNotEmpty) 'email': email,
        },
      );
      
      if (response['success'] == true) {
        final userData = response['data']['user'];
        await _storageService.saveUser(json.encode(userData));
        _currentUser = UserModel.fromJson(userData);
        return true;
      } else {
        _error = response['error'] ?? 'Error al actualizar perfil';
        return false;
      }
    } catch (e) {
      _error = 'Error de conexión';
      return false;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Limpiar error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Helper para loading
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}