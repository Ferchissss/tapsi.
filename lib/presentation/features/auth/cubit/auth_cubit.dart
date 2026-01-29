import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tapsi/core/services/storage_service.dart';
import 'package:tapsi/data/models/user_model.dart';
import 'package:tapsi/core/services/api_service.dart'; 
import 'dart:convert';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final StorageService _storageService;
  final ApiService _apiService; // NUEVO: Agregar ApiService
  final FirebaseAuth _firebaseAuth;
  String? _verificationId;

  AuthCubit({
    required StorageService storageService,
    required ApiService apiService, // NUEVO: Agregar parámetro
    FirebaseAuth? firebaseAuth,
  })  : _storageService = storageService,
        _apiService = apiService, // NUEVO: Inicializar
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        super(AuthInitial()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    emit(AuthLoading());
    
    try {
      final token = await _storageService.getToken();
      final userJson = await _storageService.getUser();
      
      if (token != null && userJson != null) {
        try {
          final result = await _apiService.verifyToken();
          
          if (result['success'] == true) {
            final userData = result['data']['user'];
            final user = UserModel(
              id: userData['id'],
              name: userData['name'],
              phone: userData['phone'],
              email: userData['email'],
              photoUrl: userData['photoUrl'],
              createdAt: DateTime.parse(userData['createdAt'] ?? DateTime.now().toIso8601String()),
            );
            emit(AuthAuthenticated(user: user));
            return;
          }
        } catch (e) {
          // Token inválido o error
        }
        
        await _storageService.clearAll();
        emit(AuthUnauthenticated());
        
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> sendVerificationCode(String phone) async {
    emit(AuthLoading());
    
    try {
      // ✅ SOLO usar backend REAL
      final result = await _apiService.sendVerificationCode(phone);
      
      if (result['success'] == true) {
        emit(VerificationCodeSent(phone: phone));
      } else {
        emit(AuthError(message: result['error'] ?? 'Error al enviar código'));
      }
    } catch (e) {
      emit(AuthError(message: 'Error: $e'));
    }
  }

  Future<void> verifyCode(String code, String phone) async {
    emit(AuthLoading());
    
    try {
      
      final result = await _apiService.verifyCode(phone, code);
            
      if (result['success'] == true) {
        final data = result['data'];
        final token = data['token'];
        final userData = data['user'];
        
        // Guardar token
        await _storageService.saveToken(token ?? '');

        // Crear usuario
        final user = UserModel(
          id: userData['id'],
          name: userData['name'],
          phone: userData['phone'],
          email: userData['email'],
          photoUrl: userData['photoUrl'],
          createdAt: DateTime.parse(userData['createdAt'] ?? DateTime.now().toIso8601String()),
        );

        final userJson = jsonEncode(user.toJson());
        await _storageService.saveUser(userJson);

        // Verificar si necesita completar perfil
        final isNewUser = userData['isNewUser'] == true;
        final name = userData['name'] as String;
        final phoneFromUser = userData['phone'] as String;

        // Verificar si el nombre es el por defecto (misma lógica que el backend)
        final defaultName = 'Usuario ${phoneFromUser.substring(phoneFromUser.length - 4)}';
        final nameIsDefault = name == defaultName;
                
        if (isNewUser || nameIsDefault) {
          emit(ProfileSetupRequired(phone: phoneFromUser));
        } else {
          emit(AuthAuthenticated(user: user));
        }
      } else {
        emit(AuthError(message: result['error'] ?? 'Código inválido'));
      }
    } catch (e) {
      emit(AuthError(message: 'Error al verificar el código: $e'));
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;
      
      if (firebaseUser != null) {
        // Crear o actualizar usuario en nuestra base
        final user = UserModel(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? 'Usuario Tapsi',
          phone: firebaseUser.phoneNumber ?? '',
          email: firebaseUser.email,
          photoUrl: firebaseUser.photoURL,
          createdAt: DateTime.now(),
        );
        
        // Obtener token
        final token = await firebaseUser.getIdToken();
        
        // Guardar en storage
        await _storageService.saveToken(token ?? '');
        await _storageService.saveUser(user.toJson().toString());
        
        // Verificar si el perfil está completo
        if (firebaseUser.displayName == null || 
            firebaseUser.displayName!.isEmpty) {
          emit(ProfileSetupRequired(
            phone: firebaseUser.phoneNumber ?? '',
            verificationId: _verificationId,
          ));
        } else {
          emit(AuthAuthenticated(user: user));
        }
      } else {
        emit(AuthError(message: 'No se pudo obtener información del usuario'));
      }
    } catch (e) {
      emit(AuthError(message: 'Error al iniciar sesión: $e'));
    }
  }

  Future<void> completeProfile({
    required String name,
    String? email,
  }) async {
    emit(AuthLoading());
    
    try {
      print('📝 Llamando al backend para actualizar perfil...');
      
      // 1. PRIMERO: Llamar al backend para actualizar en la base de datos
      final response = await _apiService.post(
        '/api/v1/auth/complete-profile',  // ¡LLAMA AL BACKEND!
        data: {
          'name': name,
          if (email != null && email.isNotEmpty) 'email': email,
        },
        requiresAuth: true,  // Necesita token
      );
      
      if (response['success'] == true) {
        print('✅ Backend actualizado correctamente');
        
        // 2. Obtener el usuario actualizado del backend
        final updatedUserData = response['data']['user'];
        
        // 3. Crear objeto UserModel con los datos actualizados
        final updatedUser = UserModel(
          id: updatedUserData['id'],
          name: updatedUserData['name'],
          phone: updatedUserData['phone'],
          email: updatedUserData['email'],
          photoUrl: updatedUserData['photoUrl'],
          createdAt: DateTime.parse(updatedUserData['createdAt'] ?? DateTime.now().toIso8601String()),
          updatedAt: DateTime.now(),
        );
        
        // 4. Guardar en storage local
        await _storageService.saveUser(updatedUser.toJson().toString());
        print('💾 Usuario guardado en storage');
        
        // 5. Ir al Home
        emit(AuthAuthenticated(user: updatedUser));
        
      } else {
        print('❌ Error del backend: ${response['error']}');
        emit(AuthError(message: response['error'] ?? 'Error al completar perfil'));
      }
      
    } catch (e) {
      print('❌ Error en completeProfile: $e');
      emit(AuthError(message: 'Error al completar perfil: $e'));
    }
  }

  Future<void> logout() async {
    emit(AuthLoading());
    
    try {
      await _firebaseAuth.signOut();
      await _storageService.clearAll();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: 'Error al cerrar sesión: $e'));
    }
  }

  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Número de teléfono inválido';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde';
      case 'quota-exceeded':
        return 'Límite de SMS excedido. Contacta al soporte';
      case 'session-expired':
        return 'La sesión expiró. Intenta nuevamente';
      default:
        return e.message ?? 'Error desconocido';
    }
  }
}