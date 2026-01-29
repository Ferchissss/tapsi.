// lib/presentation/features/trip/cubit/trip_cubit_updated.dart
// ESTE ARCHIVO REEMPLAZA A trip_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tapsi/core/services/api_service.dart';
import 'package:tapsi/data/models/trip_model.dart';
import 'package:tapsi/data/models/driver_model.dart';
import 'package:tapsi/data/models/location_model.dart';

part 'trip_state.dart';

class TripCubit extends Cubit<TripState> {
  final ApiService _apiService;
  TripModel? _currentTrip;
  DriverModel? _currentDriver;

  TripCubit(this._apiService) : super(TripInitial());

  TripModel? get currentTrip => _currentTrip;
  DriverModel? get currentDriver => _currentDriver;

  // ========== FLUJO COMPLETO DEL VIAJE ==========

  // 1. CREAR VIAJE (searching o accepted si hay chofer)
  Future<void> createTrip({
    required double originLat,
    required double originLng,
    required String originAddress,
    required double destLat,
    required double destLng,
    required String destAddress,
    required String vehicleType,
  }) async {
    try {
      emit(TripLoading(message: 'Creando viaje...'));
      
      final response = await _apiService.post(
        '/api/v1/trips',
        data: {
          'origin': {
            'lat': originLat,
            'lng': originLng,
            'address': originAddress,
          },
          'destination': {
            'lat': destLat,
            'lng': destLng,
            'address': destAddress,
          },
          'vehicleType': vehicleType,
        },
        requiresAuth: true,
      );

      if (response['success'] == true) {
        final data = response['data'];
        final tripData = data['trip'];
        
        _currentTrip = TripModel.fromJson(tripData);

        // ✅ Si viene chofer asignado inmediatamente
        if (data['driver'] != null) {
          print('✅ Chofer asignado desde el backend');
          _currentDriver = DriverModel.fromJson(data['driver']);
          emit(TripDriverAssigned(trip: _currentTrip!, driver: _currentDriver!));
        } else {
          // ⏳ Buscando chofer
          print('⏳ Buscando chofer disponible...');
          emit(TripSearchingDriver(trip: _currentTrip!));
        }
      } else {
        emit(TripError(message: response['error'] ?? 'Error al crear viaje'));
      }
    } catch (e) {
      print('❌ Error creating trip: $e');
      emit(TripError(message: 'Error al crear el viaje: $e'));
    }
  }

  // 2. CHOFER ASIGNADO (viene del socket o polling)
  void onDriverAssigned(DriverModel driver) {
    if (_currentTrip != null) {
      _currentDriver = driver;
      _currentTrip = TripModel(
        id: _currentTrip!.id,
        userId: _currentTrip!.userId,
        driverId: driver.id,
        status: 'accepted',
        originLat: _currentTrip!.originLat,
        originLng: _currentTrip!.originLng,
        originAddress: _currentTrip!.originAddress,
        destLat: _currentTrip!.destLat,
        destLng: _currentTrip!.destLng,
        destAddress: _currentTrip!.destAddress,
        vehicleType: _currentTrip!.vehicleType,
        estimatedFare: _currentTrip!.estimatedFare,
        finalFare: _currentTrip!.finalFare,
        estimatedDistance: _currentTrip!.estimatedDistance,
        actualDistance: _currentTrip!.actualDistance,
        estimatedDuration: _currentTrip!.estimatedDuration,
        actualDuration: _currentTrip!.actualDuration,
        requestedAt: _currentTrip!.requestedAt,
        acceptedAt: DateTime.now(),
        arrivedAt: _currentTrip!.arrivedAt,
        startedAt: _currentTrip!.startedAt,
        completedAt: _currentTrip!.completedAt,
        cancelledAt: _currentTrip!.cancelledAt,
      );
      emit(TripDriverAssigned(trip: _currentTrip!, driver: _currentDriver!));
    }
  }

  // 3. CONDUCTOR EN CAMINO (llegando al origen)
  Future<void> driverArriving({double? eta}) async {
    if (_currentTrip == null || _currentDriver == null) return;
    
    try {
      _currentTrip = TripModel(
        id: _currentTrip!.id,
        userId: _currentTrip!.userId,
        driverId: _currentTrip!.driverId,
        status: 'arriving',
        originLat: _currentTrip!.originLat,
        originLng: _currentTrip!.originLng,
        originAddress: _currentTrip!.originAddress,
        destLat: _currentTrip!.destLat,
        destLng: _currentTrip!.destLng,
        destAddress: _currentTrip!.destAddress,
        vehicleType: _currentTrip!.vehicleType,
        estimatedFare: _currentTrip!.estimatedFare,
        finalFare: _currentTrip!.finalFare,
        estimatedDistance: _currentTrip!.estimatedDistance,
        actualDistance: _currentTrip!.actualDistance,
        estimatedDuration: _currentTrip!.estimatedDuration,
        actualDuration: _currentTrip!.actualDuration,
        requestedAt: _currentTrip!.requestedAt,
        acceptedAt: _currentTrip!.acceptedAt,
        arrivedAt: _currentTrip!.arrivedAt,
        startedAt: _currentTrip!.startedAt,
        completedAt: _currentTrip!.completedAt,
        cancelledAt: _currentTrip!.cancelledAt,
      );

      emit(TripDriverArriving(
        trip: _currentTrip!,
        driver: _currentDriver!,
        eta: eta ?? 5.0,
      ));
    } catch (e) {
      print('❌ Error updating trip to arriving: $e');
    }
  }

  // 4. CONDUCTOR LLEGÓ AL ORIGEN (esperando al pasajero)
  Future<void> driverArrived() async {
    if (_currentTrip == null || _currentDriver == null) return;
    
    try {
      _currentTrip = TripModel(
        id: _currentTrip!.id,
        userId: _currentTrip!.userId,
        driverId: _currentTrip!.driverId,
        status: 'arrived',
        originLat: _currentTrip!.originLat,
        originLng: _currentTrip!.originLng,
        originAddress: _currentTrip!.originAddress,
        destLat: _currentTrip!.destLat,
        destLng: _currentTrip!.destLng,
        destAddress: _currentTrip!.destAddress,
        vehicleType: _currentTrip!.vehicleType,
        estimatedFare: _currentTrip!.estimatedFare,
        finalFare: _currentTrip!.finalFare,
        estimatedDistance: _currentTrip!.estimatedDistance,
        actualDistance: _currentTrip!.actualDistance,
        estimatedDuration: _currentTrip!.estimatedDuration,
        actualDuration: _currentTrip!.actualDuration,
        requestedAt: _currentTrip!.requestedAt,
        acceptedAt: _currentTrip!.acceptedAt,
        arrivedAt: DateTime.now(),
        startedAt: _currentTrip!.startedAt,
        completedAt: _currentTrip!.completedAt,
        cancelledAt: _currentTrip!.cancelledAt,
      );

      emit(TripDriverArrived(trip: _currentTrip!, driver: _currentDriver!));
    } catch (e) {
      print('❌ Error updating trip to arrived: $e');
    }
  }

  // 5. INICIAR VIAJE (cuando el pasajero sube al vehículo)
  Future<void> startTrip() async {
    if (_currentTrip == null || _currentDriver == null) return;
    
    try {
      _currentTrip = TripModel(
        id: _currentTrip!.id,
        userId: _currentTrip!.userId,
        driverId: _currentTrip!.driverId,
        status: 'ongoing',
        originLat: _currentTrip!.originLat,
        originLng: _currentTrip!.originLng,
        originAddress: _currentTrip!.originAddress,
        destLat: _currentTrip!.destLat,
        destLng: _currentTrip!.destLng,
        destAddress: _currentTrip!.destAddress,
        vehicleType: _currentTrip!.vehicleType,
        estimatedFare: _currentTrip!.estimatedFare,
        finalFare: _currentTrip!.finalFare,
        estimatedDistance: _currentTrip!.estimatedDistance,
        actualDistance: _currentTrip!.actualDistance,
        estimatedDuration: _currentTrip!.estimatedDuration,
        actualDuration: _currentTrip!.actualDuration,
        requestedAt: _currentTrip!.requestedAt,
        acceptedAt: _currentTrip!.acceptedAt,
        arrivedAt: _currentTrip!.arrivedAt,
        startedAt: DateTime.now(),
        completedAt: _currentTrip!.completedAt,
        cancelledAt: _currentTrip!.cancelledAt,
      );

      emit(TripInProgress(trip: _currentTrip!, driver: _currentDriver!));
    } catch (e) {
      print('❌ Error starting trip: $e');
      emit(TripError(message: 'Error al iniciar viaje'));
    }
  }

  // 6. COMPLETAR VIAJE
  Future<void> completeTrip() async {
    if (_currentTrip == null) return;

    try {
      emit(TripLoading(message: 'Finalizando viaje...'));

      _currentTrip = TripModel(
        id: _currentTrip!.id,
        userId: _currentTrip!.userId,
        driverId: _currentTrip!.driverId,
        status: 'completed',
        originLat: _currentTrip!.originLat,
        originLng: _currentTrip!.originLng,
        originAddress: _currentTrip!.originAddress,
        destLat: _currentTrip!.destLat,
        destLng: _currentTrip!.destLng,
        destAddress: _currentTrip!.destAddress,
        vehicleType: _currentTrip!.vehicleType,
        estimatedFare: _currentTrip!.estimatedFare,
        finalFare: _currentTrip!.estimatedFare, // En producción vendría del backend
        estimatedDistance: _currentTrip!.estimatedDistance,
        actualDistance: _currentTrip!.estimatedDistance,
        estimatedDuration: _currentTrip!.estimatedDuration,
        actualDuration: _currentTrip!.estimatedDuration,
        requestedAt: _currentTrip!.requestedAt,
        acceptedAt: _currentTrip!.acceptedAt,
        arrivedAt: _currentTrip!.arrivedAt,
        startedAt: _currentTrip!.startedAt,
        completedAt: DateTime.now(),
        cancelledAt: _currentTrip!.cancelledAt,
      );

      emit(TripCompleted(trip: _currentTrip!));
    } catch (e) {
      print('❌ Error completing trip: $e');
      emit(TripError(message: 'Error al completar viaje'));
    }
  }

  // 7. CANCELAR VIAJE
  Future<void> cancelTrip({String? reason}) async {
    if (_currentTrip == null) return;

    try {
      emit(TripLoading(message: 'Cancelando viaje...'));
      
      final response = await _apiService.patch(
        '/api/v1/trips/${_currentTrip!.id}/cancel',
      );

      if (response.statusCode == 200) {
        emit(TripCancelled(reason: reason));
        _resetTrip();
      } else {
        emit(TripError(message: 'Error al cancelar el viaje'));
      }
    } catch (e) {
      print('❌ Error cancelling trip: $e');
      emit(TripError(message: 'Error al cancelar el viaje'));
    }
  }

  // ========== MÉTODOS AUXILIARES ==========

  // Actualizar ubicación del conductor (llamado desde WebSocket)
  void updateDriverLocation(double lat, double lng) {
    if (_currentDriver != null) {
      _currentDriver = DriverModel(
        id: _currentDriver!.id,
        userId: _currentDriver!.userId,
        name: _currentDriver!.name,
        photoUrl: _currentDriver!.photoUrl,
        licenseNumber: _currentDriver!.licenseNumber,
        status: _currentDriver!.status,
        rating: _currentDriver!.rating,
        totalTrips: _currentDriver!.totalTrips,
        vehicle: _currentDriver!.vehicle,
        currentLat: lat,
        currentLng: lng,
      );

      // Re-emitir el estado actual con la nueva ubicación
      final currentState = state;
      if (currentState is TripDriverAssigned) {
        emit(TripDriverAssigned(trip: _currentTrip!, driver: _currentDriver!));
      } else if (currentState is TripDriverArriving) {
        emit(TripDriverArriving(
          trip: _currentTrip!,
          driver: _currentDriver!,
          eta: currentState.eta,
        ));
      } else if (currentState is TripInProgress) {
        emit(TripInProgress(trip: _currentTrip!, driver: _currentDriver!));
      }
    }
  }

  // Resetear viaje
  void _resetTrip() {
    _currentTrip = null;
    _currentDriver = null;
  }

  // Volver al estado inicial
  void reset() {
    _resetTrip();
    emit(TripInitial());
  }
}