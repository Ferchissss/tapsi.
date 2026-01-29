import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteService {
  // URL base de OSRM (Open Source Routing Machine)
  static const String _osrmBaseUrl = 'https://router.project-osrm.org';
  
  // Obtener ruta real usando OSRM
  Future<List<LatLng>> getRouteCoordinates({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      // Construir URL para OSRM
      final url = '$_osrmBaseUrl/route/v1/driving/'
          '${origin.longitude},${origin.latitude};'
          '${destination.longitude},${destination.latitude}'
          '?overview=full&geometries=geojson';
      
      print('🌍 Solicitando ruta a OSRM: $url');
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] == 'Ok' && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          
          if (geometry['type'] == 'LineString') {
            final coordinates = geometry['coordinates'] as List;
            
            // Convertir coordenadas GeoJSON [lng, lat] a LatLng [lat, lng]
            return coordinates.map((coord) {
              return LatLng(coord[1], coord[0]); // Invertir lng, lat a lat, lng
            }).toList();
          }
        }
      }
      
      print('⚠️  OSRM no devolvió ruta válida, usando línea recta');
      // Fallback a línea recta
      return _createStraightLine(origin, destination);
      
    } catch (e) {
      print('❌ Error calculando ruta: $e');
      // Fallback a línea recta
      return _createStraightLine(origin, destination);
    }
  }
  
  // Crear línea recta con puntos intermedios (fallback)
  List<LatLng> _createStraightLine(LatLng origin, LatLng destination) {
    final List<LatLng> points = [];
    const int numPoints = 20;
    
    for (int i = 0; i <= numPoints; i++) {
      final fraction = i / numPoints;
      final lat = origin.latitude + (destination.latitude - origin.latitude) * fraction;
      final lng = origin.longitude + (destination.longitude - origin.longitude) * fraction;
      points.add(LatLng(lat, lng));
    }
    
    return points;
  }
  
  // Calcular distancia total de la ruta
  double calculateDistance(List<LatLng> points) {
    if (points.length < 2) return 0;
    
    double totalDistance = 0;
    for (int i = 0; i < points.length - 1; i++) {
      totalDistance += _calculateHaversineDistance(points[i], points[i + 1]);
    }
    
    return totalDistance;
  }
  
  // Fórmula Haversine para distancia entre dos puntos
  double _calculateHaversineDistance(LatLng point1, LatLng point2) {
    const earthRadius = 6371.0; // Radio de la Tierra en km
    
    final lat1 = point1.latitude * pi / 180;
    final lon1 = point1.longitude * pi / 180;
    final lat2 = point2.latitude * pi / 180;
    final lon2 = point2.longitude * pi / 180;
    
    final dLat = lat2 - lat1;
    final dLon = lon2 - lon1;
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  // Calcular tiempo estimado de viaje (simplificado)
  double calculateEstimatedTime(List<LatLng> route, double averageSpeedKmh) {
    final distance = calculateDistance(route);
    return distance / averageSpeedKmh * 60; // tiempo en minutos
  }
}