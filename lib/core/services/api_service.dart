// lib/core/services/api_service.dart
//
// Este servicio mantiene la API pública usada por la app (get/post/put/patch +
// sendVerificationCode/verifyCode/verifyToken), pero ahora implementado con
// Firebase Auth + Cloud Firestore (sin backend externo).
import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:tapsi/core/services/storage_service.dart';

class ApiService {
  static const String _verificationIdKey = 'firebase_phone_verification_id';

  final StorageService _storageService;
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  ApiService(
    this._storageService, {
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // Auth (phone OTP)
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> sendVerificationCode(String phone) async {
    try {
      final completer = Completer<Map<String, dynamic>>();

      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (credential) async {
          // Auto-verificación (Android). Guardamos para que el flujo pueda
          // continuar si el usuario ingresa OTP igual.
          if (!completer.isCompleted) {
            completer.complete({'success': true, 'data': {'autoVerified': true}});
          }
          try {
            await _auth.signInWithCredential(credential);
          } catch (_) {
            // Ignorar: el flujo principal seguirá con verifyCode()
          }
        },
        verificationFailed: (e) {
          if (!completer.isCompleted) {
            completer.complete({
              'success': false,
              'error': e.message ?? 'Error al enviar el código',
            });
          }
        },
        codeSent: (verificationId, _) async {
          await _storageService.saveString(_verificationIdKey, verificationId);
          if (!completer.isCompleted) {
            completer.complete({'success': true});
          }
        },
        codeAutoRetrievalTimeout: (verificationId) async {
          await _storageService.saveString(_verificationIdKey, verificationId);
          if (!completer.isCompleted) {
            // No es error: el usuario puede seguir ingresando el OTP.
            completer.complete({'success': true});
          }
        },
        timeout: const Duration(seconds: 60),
      );

      return await completer.future;
    } catch (e) {
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyCode(String phone, String code) async {
    try {
      final verificationId = await _storageService.getString(_verificationIdKey);
      if (verificationId == null || verificationId.isEmpty) {
        return {
          'success': false,
          'error': 'La sesión de verificación expiró. Vuelve a enviar el código.',
        };
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: code,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        return {'success': false, 'error': 'No se pudo autenticar al usuario'};
      }

      final String? idToken = await user.getIdToken();

      // Usuario en Firestore (colección `users`)
      final userRef = _db.collection('users').doc(user.uid);
      final snap = await userRef.get();

      final now = DateTime.now();
      final phoneNumber = user.phoneNumber ?? phone;

      bool isNewUser = false;
      Map<String, dynamic> userData;

      if (!snap.exists) {
        isNewUser = true;
        final defaultName = 'Usuario ${phoneNumber.substring(phoneNumber.length - 4)}';
        userData = {
          'id': user.uid,
          'name': defaultName,
          'phone': phoneNumber,
          'email': user.email,
          'photoUrl': user.photoURL,
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        };
        await userRef.set(userData);
      } else {
        userData = Map<String, dynamic>.from(snap.data() ?? {});
        // Asegurar claves mínimas
        userData['id'] ??= user.uid;
        userData['phone'] ??= phoneNumber;
      }

      // Guardar "token" y usuario para que el resto del código siga funcionando
      await _storageService.saveToken(idToken ?? '');
      await _storageService.saveUser(jsonEncode(userData));

      return {
        'success': true,
        'data': {
          'token': idToken ?? '',
          'user': {
            ...userData,
            'isNewUser': isNewUser,
          },
        },
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'error': e.message ?? 'Código inválido'};
    } catch (e) {
      return {'success': false, 'error': 'Error al verificar el código: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'No autenticado'};
      }

      final snap = await _db.collection('users').doc(user.uid).get();
      if (!snap.exists) {
        return {'success': false, 'error': 'Usuario no encontrado'};
      }

      return {
        'success': true,
        'data': {'user': snap.data()},
      };
    } catch (e) {
      return {'success': false, 'error': 'Error validando sesión: $e'};
    }
  }

  // ---------------------------------------------------------------------------
  // Compatibilidad con endpoints usados por la app (get/post/put/patch)
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    if (path == '/api/v1/trips/history') {
      return _getTripHistory(
        page: (queryParameters?['page'] as int?) ?? 1,
        limit: (queryParameters?['limit'] as int?) ?? 20,
      );
    }

    if (path == '/api/v1/users/me') {
      return _getMe();
    }

    return {'success': false, 'error': 'Ruta no soportada: $path'};
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = false,
  }) async {
    if (path == '/api/v1/auth/complete-profile') {
      final name = (data?['name'] as String?) ?? '';
      final email = data?['email'] as String?;
      return _completeProfile(name: name, email: email);
    }

    if (path == '/api/v1/trips') {
      return _createTrip(data ?? const {});
    }

    return {'success': false, 'error': 'Ruta no soportada: $path'};
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? data,
    bool requiresAuth = true,
  }) async {
    if (path == '/api/v1/users/me') {
      final name = (data?['name'] as String?) ?? '';
      final email = data?['email'] as String?;
      return _completeProfile(name: name, email: email);
    }

    return {'success': false, 'error': 'Ruta no soportada: $path'};
  }

  /// Mantiene la misma firma que usaba Dio (TripCubit revisa statusCode).
  Future<_FakeResponse> patch(
    String path, {
    dynamic data,
    dynamic options,
  }) async {
    if (path.endsWith('/cancel')) {
      final tripId = path
          .replaceFirst('/api/v1/trips/', '')
          .replaceFirst('/cancel', '');
      final ok = await _cancelTrip(tripId);
      return _FakeResponse(statusCode: ok ? 200 : 400);
    }
    return _FakeResponse(statusCode: 400);
  }

  // ---------------------------------------------------------------------------
  // Implementaciones Firestore
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> _getMe() async {
    final user = _auth.currentUser;
    if (user == null) return {'success': false, 'error': 'No autenticado'};
    final snap = await _db.collection('users').doc(user.uid).get();
    if (!snap.exists) return {'success': false, 'error': 'Usuario no encontrado'};
    return {'success': true, 'data': {'user': snap.data()}};
  }

  Future<Map<String, dynamic>> _completeProfile({
    required String name,
    String? email,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {'success': false, 'error': 'No autenticado'};

      final now = DateTime.now().toIso8601String();
      final userRef = _db.collection('users').doc(user.uid);

      await user.updateDisplayName(name);
      if (email != null && email.isNotEmpty) {
        // No forzamos updateEmail para evitar flujos de re-auth.
      }

      await userRef.set(
        {
          'id': user.uid,
          'name': name,
          if (email != null && email.isNotEmpty) 'email': email,
          'phone': user.phoneNumber ?? '',
          'photoUrl': user.photoURL,
          'updatedAt': now,
        },
        SetOptions(merge: true),
      );

      final snap = await userRef.get();
      final userData = snap.data() ?? <String, dynamic>{};

      await _storageService.saveUser(jsonEncode(userData));

      return {'success': true, 'data': {'user': userData}};
    } catch (e) {
      return {'success': false, 'error': 'Error al completar perfil: $e'};
    }
  }

  Future<Map<String, dynamic>> _createTrip(Map<String, dynamic> data) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {'success': false, 'error': 'No autenticado'};

      final origin = Map<String, dynamic>.from(data['origin'] ?? const {});
      final destination = Map<String, dynamic>.from(data['destination'] ?? const {});
      final vehicleType = (data['vehicleType'] as String?) ?? 'standard';

      final now = DateTime.now();
      final tripRef = _db.collection('trips').doc();

      // Valores estimados básicos (para mantener UI).
      final tripJson = {
        'id': tripRef.id,
        'userId': user.uid,
        'driverId': null,
        'status': 'searching',
        'originLat': (origin['lat'] as num).toDouble(),
        'originLng': (origin['lng'] as num).toDouble(),
        'originAddress': (origin['address'] as String?) ?? '',
        'destLat': (destination['lat'] as num).toDouble(),
        'destLng': (destination['lng'] as num).toDouble(),
        'destAddress': (destination['address'] as String?) ?? '',
        'vehicleType': vehicleType,
        'estimatedFare': 10.0,
        'finalFare': null,
        'estimatedDistance': 3.5,
        'actualDistance': null,
        'estimatedDuration': 8,
        'actualDuration': null,
        'requestedAt': now.toIso8601String(),
        'acceptedAt': null,
        'arrivedAt': null,
        'startedAt': null,
        'completedAt': null,
        'cancelledAt': null,
      };

      await tripRef.set(tripJson);

      return {
        'success': true,
        'data': {
          'trip': tripJson,
          'driver': null,
        },
      };
    } catch (e) {
      return {'success': false, 'error': 'Error al crear viaje: $e'};
    }
  }

  Future<bool> _cancelTrip(String tripId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final tripRef = _db.collection('trips').doc(tripId);
      await tripRef.set(
        {
          'status': 'cancelled',
          'cancelledAt': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> _getTripHistory({
    required int page,
    required int limit,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {'success': false, 'error': 'No autenticado'};

      // Obtener viajes del usuario desde la subcolección de usuarios
      // Esto no requiere índice compuesto ya que la ruta es específica del usuario
      final fetch = page * limit;

      final querySnap = await _db
          .collection('users')
          .doc(user.uid)
          .collection('trips')
          .orderBy('requestedAt', descending: true)
          .limit(fetch)
          .get();

      final all = querySnap.docs.map((d) => d.data()).toList();
      final start = (page - 1) * limit;
      final end = (start + limit) > all.length ? all.length : (start + limit);
      final pageItems = start >= all.length ? <Map<String, dynamic>>[] : all.sublist(start, end);

      final hasMore = all.length == fetch; // aproximación

      return {
        'success': true,
        'data': {
          'trips': pageItems,
          'pagination': {
            'page': page,
            'hasMore': hasMore,
            'total': all.length, // total real requeriría contador/aggregate
          },
        },
      };
    } catch (e) {
      print('❌ Error al cargar historial: $e');
      return {'success': false, 'error': 'Error al cargar historial: $e'};
    }
  }
}

class _FakeResponse {
  final int statusCode;
  _FakeResponse({required this.statusCode});
}