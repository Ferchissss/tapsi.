import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:tapsi/core/services/location_service.dart';
import 'package:tapsi/core/services/offline_service.dart'; 
import 'package:tapsi/core/services/route_service.dart';
import 'package:tapsi/data/models/location_model.dart';
import 'package:geolocator/geolocator.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final LocationService _locationService;
  final OfflineService? _offlineService;
  StreamSubscription<Position>? _positionStream;
  Timer? _locationUpdateTimer;

  LocationModel? _currentLocation;

  HomeCubit({required LocationService locationService, OfflineService? offlineService,})
      : _locationService = locationService,
      _offlineService = offlineService,
        super(HomeInitial()) {
    initialize();
  }

  Future<void> initialize() async {
    emit(HomeLoading());
    
    try {
      final hasPermission = await _locationService.checkPermissions();
      if (!hasPermission) {
        emit(HomeError(
          message: 'Permisos de ubicación requeridos',
          isPermissionError: true,
        ));
        return;
      }
      
      final position = await _locationService.getCurrentPosition();
      final address = await _locationService.getAddressFromLatLng(
        position.latitude,
        position.longitude,
      );
      _saveLocationToCache(position, address);
      final currentLocation = LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        name: 'Mi ubicación',
      );
      _currentLocation = currentLocation;
    
      // Establecer ubicación actual como origen por defecto
      _selectedOrigin = currentLocation;  
      _locationSelection = LocationSelectionState(origin: currentLocation);
      
      emit(HomeLoaded(
        currentLocation: currentLocation,
        mapCenter: LatLng(position.latitude, position.longitude),
        zoom: 15.0,
      ));

      _startLocationTracking();
      _startPeriodicUpdates();
    } catch (e) {
      emit(HomeError(message: 'Error al obtener ubicación: $e'));
    }
  }

  void _startLocationTracking() {
    _positionStream = _locationService.getPositionStream().listen((position) {
      final state = this.state;
      if (state is HomeLoaded) {
        emit(state.copyWith(
          currentLocation: LocationModel(
            latitude: position.latitude,
            longitude: position.longitude,
            address: state.currentLocation.address,
            name: 'Mi ubicación',
          ),
        ));
      }
    }, onError: (error) {
      print('Error en seguimiento de ubicación: $error');
    });
  }

  void _startPeriodicUpdates() {
    _locationUpdateTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) async {
        try {
          final position = await _locationService.getCurrentPosition();
          final address = await _locationService.getAddressFromLatLng(
            position.latitude,
            position.longitude,
          );
          _saveLocationToCache(position, address);
          final state = this.state;
          if (state is HomeLoaded) {
            emit(state.copyWith(
              currentLocation: LocationModel(
                latitude: position.latitude,
                longitude: position.longitude,
                address: address,
                name: 'Mi ubicación',
              ),
            ));
          }
        } catch (e) {
          print('Error en actualización periódica: $e');
        }
      },
    );
  }

  void updateMapCenter(LatLng center, double zoom) {
    final state = this.state;
    if (state is HomeLoaded) {
      emit(state.copyWith(
        mapCenter: center,
        zoom: zoom,
      ));
    }
  }

  void selectLocation(LocationModel location) {
    final state = this.state;
    if (state is HomeLoaded) {
      emit(state.copyWith(
        selectedLocation: location,
      ));
    }
  }

  void clearSelectedLocation() {
    final state = this.state;
    if (state is HomeLoaded) {
      emit(state.copyWith(
        selectedLocation: null,
      ));
    }
  }

  Future<void> requestLocationPermission() async {
    emit(HomeLoading());
    await initialize();
  }
  // Agrega esto AL FINAL de tu HomeCubit, ANTES del último }
  Future<void> _saveLocationToCache(Position position, String? address) async {
    // Si no tenemos OfflineService, no hacemos nada
    if (_offlineService == null) return;
    
    try {
      // Crear los datos que vamos a guardar
      final locationData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'address': address ?? 'Ubicación desconocida',
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Guardar en caché
      await _offlineService!.addToOfflineQueue(
        method: 'CACHE', 
        path: 'user_location_cache',
        data: locationData,
        requestId: 'location_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      if (kDebugMode) {
        print('📍 Ubicación guardada en caché: ${position.latitude}, ${position.longitude}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error guardando ubicación en caché: $e');
      }
    }
  }
  // Agregar estas variables en la clase HomeCubit:
  LocationModel? _selectedOrigin;
  LocationModel? _selectedDestination;
  LocationSelectionState _locationSelection = const LocationSelectionState();

  // Agregar getters:
  LocationModel? get selectedOrigin => _selectedOrigin;
  LocationModel? get selectedDestination => _selectedDestination;
  LocationSelectionState get locationSelection => _locationSelection;

  // Agregar estos métodos ANTES del método close():
  void setOrigin(LocationModel location) {
    _selectedOrigin = location;
    _locationSelection = _locationSelection.copyWith(origin: location);
    
    // Calcular ruta si hay destino
    if (_selectedDestination != null) {
      calculateRoute();
    }
    
    final state = this.state;
    if (state is HomeLoaded) {
      emit(state.copyWith(
        selectedLocation: location,
      ));
    }
  }

  // MODIFICAR EL PRIMER setDestination (línea ~203):
  void setDestination(LocationModel location) {
    _selectedDestination = location;
    _locationSelection = _locationSelection.copyWith(destination: location);
    
    // Calcular ruta si hay origen
    if (_selectedOrigin != null) {
      calculateRoute();
    }
    
    final state = this.state;
    if (state is HomeLoaded) {
      emit(state.copyWith(
        selectedLocation: location,
      ));
    }
  }

  void swapOriginDestination() {
    final temp = _selectedOrigin;
    _selectedOrigin = _selectedDestination;
    _selectedDestination = temp;
    
    _locationSelection = LocationSelectionState(
      origin: _selectedOrigin,
      destination: _selectedDestination,
    );
    
    final state = this.state;
    if (state is HomeLoaded) {
      emit(state.copyWith());
    }
  }

  void clearOrigin() {
    _selectedOrigin = null;
    _routeCoordinates.clear(); // LIMPIAR RUTA
    _estimatedTime = null;     // LIMPIAR TIEMPO
    _estimatedDistance = null;
    _locationSelection = _locationSelection.copyWith(origin: null);
    final state = this.state;
    if (state is HomeLoaded) {
      emit(state.copyWith(selectedLocation: null));
    }
  }

  void clearDestination() {
    _selectedDestination = null;
    _routeCoordinates.clear(); // LIMPIAR RUTA
    _estimatedTime = null;     // LIMPIAR TIEMPO
    _estimatedDistance = null;
    _locationSelection = _locationSelection.copyWith(destination: null);
    final state = this.state;
    if (state is HomeLoaded) {
      emit(state.copyWith(selectedLocation: null));
    }
  }

  void clearAllSelections() {
    _selectedOrigin = null;
    _selectedDestination = null;
    _routeCoordinates.clear(); // LIMPIAR RUTA
    _estimatedTime = null;     // LIMPIAR TIEMPO
    _estimatedDistance = null;
    _locationSelection = const LocationSelectionState();
    final state = this.state;
    if (state is HomeLoaded) {
      emit(state.copyWith(selectedLocation: null));
    }
  }
  // Agregar estas variables:
  List<LatLng> _routeCoordinates = [];
  final RouteService _routeService = RouteService();
  bool _isCalculatingRoute = false;

  // Agregar getters:
  List<LatLng> get routeCoordinates => _routeCoordinates;
  bool get isCalculatingRoute => _isCalculatingRoute;

  // Agrega estas variables:
  double? _estimatedTime; // en minutos
  double? _estimatedDistance; // en km

  // Getters:
  double? get estimatedTime => _estimatedTime;
  double? get estimatedDistance => _estimatedDistance;

  // Modifica calculateRoute para calcular tiempo y distancia:
  Future<void> calculateRoute() async {
    if (_selectedOrigin == null || _selectedDestination == null) {
      _routeCoordinates.clear();
      _estimatedTime = null;
      _estimatedDistance = null;
      final state = this.state;
      if (state is HomeLoaded) {
        emit(state.copyWith());
      }
      return;
    }

    _isCalculatingRoute = true;
    final state = this.state;
    if (state is HomeLoaded) {
      emit(state.copyWith());
    }

    try {
      _routeCoordinates = await _routeService.getRouteCoordinates(
        origin: LatLng(_selectedOrigin!.latitude, _selectedOrigin!.longitude),
        destination: LatLng(_selectedDestination!.latitude, _selectedDestination!.longitude),
      );
      
      // Calcular distancia y tiempo estimado
      _estimatedDistance = _routeService.calculateDistance(_routeCoordinates);
      _estimatedTime = _routeService.calculateEstimatedTime(_routeCoordinates, 40.0); // 40 km/h promedio
      
      print('📍 Ruta calculada: ${_estimatedDistance?.toStringAsFixed(2)} km, ${_estimatedTime?.toStringAsFixed(0)} min');
      
    } catch (e) {
      print('Error calculando ruta: $e');
      _routeCoordinates = [];
      _estimatedTime = null;
      _estimatedDistance = null;
    }

    _isCalculatingRoute = false;
    final newState = this.state;
    if (newState is HomeLoaded) {
      emit(newState.copyWith());
    }
  }

  @override
  Future<void> close() {
    _positionStream?.cancel();
    _locationUpdateTimer?.cancel();
    return super.close();
  }
}