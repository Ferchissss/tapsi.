import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:latlong2/latlong.dart';

class LocationService {
  
  // Coordenadas de Tarija, Bolivia como fallback
  static const double tarijaLatitude = -21.5318;
  static const double tarijaLongitude = -64.7311;
  
  Future<bool> checkPermissions() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }
    
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    
    return true;
  }
  
  Future<Position> getCurrentPosition() async {
    final hasPermission = await checkPermissions();
    if (!hasPermission) {
      throw Exception('Permisos de ubicación denegados');
    }
    
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );
  }
  
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10, // metros
      ),
    );
  }
  
  Future<String?> getAddressFromLatLng(double latitude, double longitude) async {
    try {
      final places = await geo.placemarkFromCoordinates(latitude, longitude);
      if (places.isNotEmpty) {
        final place = places.first;
        return buildAddressString(place);
      }
    } catch (e) {
      print('Error obteniendo dirección: $e');
    }
    return null;
  }
  
  // NUEVO: Buscar lugares en Tarija, Bolivia
  Future<List<geo.Location>> searchAddressInTarija(String query, {int limit = 10}) async {
    try {
      if (query.length < 3) return [];
      
      // Añadir "Tarija, Bolivia" a la búsqueda para obtener resultados locales
      final searchQuery = '$query, Tarija, Bolivia';
      
      // Buscar por nombre de lugar o dirección
      final locations = await geo.locationFromAddress(searchQuery);
      
      if (locations.isNotEmpty) {
        // Ordenar por relevancia (los que contienen Tarija primero)
        locations.sort((a, b) {
          // Aquí podríamos ordenar por distancia si tuviéramos la ubicación actual
          return 0;
        });
        
        return locations.take(limit).toList();
      }
      
      // Si no hay resultados con "Tarija, Bolivia", intentar solo la query
      final fallbackLocations = await geo.locationFromAddress(query);
      return fallbackLocations.take(limit).toList();
      
    } catch (e) {
      print('Error buscando dirección en Tarija: $e');
      return [];
    }
  }
  
  // NUEVO: Lugares populares de Tarija para búsquedas rápidas
  static final Map<String, Map<String, dynamic>> tarijaPopularPlaces = {
    'Plaza Principal': {
      'latitude': -21.5320,
      'longitude': -64.7334,
      'address': 'Plaza Luis de Fuentes, Tarija',
    },
    'Mercado Central': {
      'latitude': -21.5295,
      'longitude': -64.7328,
      'address': 'Mercado Central de Tarija',
    },
    'Aeropuerto Capitán Oriel Lea Plaza': {
      'latitude': -21.5558,
      'longitude': -64.7014,
      'address': 'Aeropuerto de Tarija',
    },
  };
  
  // NUEVO: Obtener lugares sugeridos de Tarija
  List<Map<String, dynamic>> getTarijaSuggestions(String query) {
    if (query.isEmpty) return [];
    
    final normalizedQuery = query.toLowerCase();
    final suggestions = <Map<String, dynamic>>[];
    
    for (final entry in tarijaPopularPlaces.entries) {
      final placeName = entry.key.toLowerCase();
      final placeData = entry.value;
      
      if (placeName.contains(normalizedQuery) || 
          placeData['address']!.toLowerCase().contains(normalizedQuery)) {
        suggestions.add({
          'name': entry.key,
          ...placeData,
        });
      }
    }
    
    return suggestions;
  }
  
  // NUEVO: Calcular distancia entre dos puntos
  double calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const Distance distance = Distance();
    return distance(LatLng(lat1, lon1), LatLng(lat2, lon2)) / 1000; // en km
  }
  
  // NUEVO: Ordenar lugares por cercanía
  List<Map<String, dynamic>> sortByDistance(
    List<Map<String, dynamic>> places,
    double currentLat,
    double currentLng,
  ) {
    places.sort((a, b) {
      final distA = calculateDistanceKm(
        currentLat, currentLng,
        a['latitude'], a['longitude'],
      );
      final distB = calculateDistanceKm(
        currentLat, currentLng,
        b['latitude'], b['longitude'],
      );
      return distA.compareTo(distB);
    });
    return places;
  }
  
  String buildAddressString(geo.Placemark placemark) {
    final parts = <String>[];
    
    if (placemark.street?.isNotEmpty == true) {
      parts.add(placemark.street!);
    }
    if (placemark.subLocality?.isNotEmpty == true) {
      parts.add(placemark.subLocality!);
    }
    if (placemark.locality?.isNotEmpty == true) {
      parts.add(placemark.locality!);
    }
    if (placemark.administrativeArea?.isNotEmpty == true) {
      parts.add(placemark.administrativeArea!);
    }
    if (placemark.country?.isNotEmpty == true) {
      parts.add(placemark.country!);
    }
    
    return parts.join(', ');
  }
  
  Future<List<geo.Placemark>> getNearbyPlaces(LatLng location) async {
    try {
      return await geo.placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
    } catch (e) {
      print('Error obteniendo lugares cercanos: $e');
      return [];
    }
  }
  
  double calculateDistance(LatLng start, LatLng end) {
    const Distance distance = Distance();
    return distance(start, end);
  }
  
  LatLngBounds getBoundsFromPoints(List<LatLng> points) {
    if (points.isEmpty) {
      return LatLngBounds(
        const LatLng(0, 0),
        const LatLng(0, 0),
      );
    }
    
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    
    for (final point in points) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }
    
    return LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );
  }
}

class LatLngBounds {
  final LatLng southwest;
  final LatLng northeast;
  
  const LatLngBounds(this.southwest, this.northeast);
  
  LatLng get center => LatLng(
    (southwest.latitude + northeast.latitude) / 2,
    (southwest.longitude + northeast.longitude) / 2,
  );
  
}