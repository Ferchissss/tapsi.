import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:tapsi/core/constants/colors.dart';
import 'package:tapsi/core/services/location_service.dart';

class MapSelectionWidget extends StatefulWidget {
  final Function(double lat, double lng, String address) onLocationSelected;

  const MapSelectionWidget({
    super.key,
    required this.onLocationSelected,
  });

  @override
  State<MapSelectionWidget> createState() => _MapSelectionWidgetState();
}

class _MapSelectionWidgetState extends State<MapSelectionWidget> {
  late MapController mapController;
  LatLng selectedLocation = LatLng(-21.5318, -64.7311); // Centro de Tarija
  String selectedAddress = '';
  bool isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      final position = await LocationService().getCurrentPosition();
      final location = LatLng(position.latitude, position.longitude);
      setState(() => selectedLocation = location);
      _getAddressFromLocation(location);
      mapController.move(location, 15.0);
    } catch (e) {
      print('Error getting current location: $e');
      // Fallback a Tarija
      final location = LatLng(-21.5318, -64.7311);
      setState(() => selectedLocation = location);
      _getAddressFromLocation(location);
      mapController.move(location, 15.0);
    }
  }

  Future<void> _getAddressFromLocation(LatLng location) async {
    try {
      setState(() => isLoadingAddress = true);
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address =
            '${place.street ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}';
        setState(() => selectedAddress = address.replaceAll(RegExp(', +'), ', '));
      }
    } catch (e) {
      print('Error getting address: $e');
      setState(() => selectedAddress = '${location.latitude}, ${location.longitude}');
    } finally {
      setState(() => isLoadingAddress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Mapa
        Expanded(
          child: FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: selectedLocation,
              initialZoom: 15.0,
              onTap: (tapPosition, point) {
                setState(() {
                  selectedLocation = point;
                });
                _getAddressFromLocation(point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: selectedLocation,
                    width: 80,
                    height: 80,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Información de ubicación seleccionada
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ubicación seleccionada:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              if (isLoadingAddress)
                const SizedBox(
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text(
                  selectedAddress,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onLocationSelected(
                      selectedLocation.latitude,
                      selectedLocation.longitude,
                      selectedAddress,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Confirmar ubicación'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }
}
