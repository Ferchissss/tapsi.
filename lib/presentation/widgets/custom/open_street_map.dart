import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:tapsi/core/constants/colors.dart';
import 'package:tapsi/data/models/location_model.dart';

class OpenStreetMap extends StatefulWidget {
  final LatLng center;
  final double zoom;
  final LocationModel? currentLocation;
  final LocationModel? selectedOrigin; 
  final LocationModel? selectedDestination;
  final List<LatLng>? routeCoordinates;
  final List<Marker>? additionalMarkers;
  final Function(LatLng, double)? onMapMoved;
  final Function(LatLng)? onTap;
  final bool interactive;

  const OpenStreetMap({
    super.key,
    required this.center,
    this.zoom = 15.0,
    this.currentLocation,
    this.selectedOrigin, 
    this.selectedDestination,
    this.routeCoordinates,
    this.additionalMarkers,
    this.onMapMoved,
    this.onTap,
    this.interactive = true,
  });

  @override
  State<OpenStreetMap> createState() => _OpenStreetMapState();
}

class _OpenStreetMapState extends State<OpenStreetMap> {
  late MapController _mapController;
  final List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _updateMarkers();
  }

  @override
  void didUpdateWidget(covariant OpenStreetMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.center != widget.center || 
        oldWidget.zoom != widget.zoom) {
      _mapController.move(widget.center, widget.zoom);
    }
    
    if (oldWidget.currentLocation != widget.currentLocation ||
        oldWidget.selectedOrigin != widget.selectedOrigin ||
        oldWidget.selectedDestination != widget.selectedDestination ||
        oldWidget.routeCoordinates != widget.routeCoordinates) {
      
      _updateMarkers();
    }
  }

  void _updateMarkers() {
    _markers.clear();

    // Marcador de ubicación actual (solo si no es origen/destino)
    if (widget.currentLocation != null) {
      final isCurrentLocationOrigin = widget.currentLocation?.latitude == widget.selectedOrigin?.latitude &&
          widget.currentLocation?.longitude == widget.selectedOrigin?.longitude;
      
      final isCurrentLocationDestination = widget.currentLocation?.latitude == widget.selectedDestination?.latitude &&
          widget.currentLocation?.longitude == widget.selectedDestination?.longitude;
      
      if (!isCurrentLocationOrigin && !isCurrentLocationDestination) {
        _markers.add(
          Marker(
            point: LatLng(
              widget.currentLocation!.latitude,
              widget.currentLocation!.longitude,
            ),
            width: 40,
            height: 40,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.my_location,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        );
      }
    }

    // Marcador de origen
    if (widget.selectedOrigin != null) {
      _markers.add(
        Marker(
          point: LatLng(
            widget.selectedOrigin!.latitude,
            widget.selectedOrigin!.longitude,
          ),
          width: 48, // Tamaño perfecto
          height: 48, // Tamaño perfecto
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Círculo de fondo
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 24, // Tamaño bueno
                ),
              ),
              // Letra A
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: Colors.white,
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'A',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Marcador de destino
    if (widget.selectedDestination != null) {
      _markers.add(
        Marker(
          point: LatLng(
            widget.selectedDestination!.latitude,
            widget.selectedDestination!.longitude,
          ),
          width: 48, // Mismo tamaño que origen
          height: 48, // Mismo tamaño que origen
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Círculo de fondo
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_pin,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              // Letra B
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: Colors.white,
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'B',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Marcadores adicionales
    if (widget.additionalMarkers != null) {
      _markers.addAll(widget.additionalMarkers!);
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: widget.center,
        zoom: widget.zoom,
        interactiveFlags: widget.interactive
            ? InteractiveFlag.all & ~InteractiveFlag.rotate
            : InteractiveFlag.none,
        onMapEvent: (mapEvent) {
          if (mapEvent is MapEventMove && widget.onMapMoved != null) {
            // Usa el mapController para obtener la posición actual
            final center = _mapController.center;
            final zoom = _mapController.zoom;
            widget.onMapMoved!(center, zoom);
          }
        },
        onTap: (tapPosition, point) {
          widget.onTap?.call(point);
        },
      ),
      children: [
        // Capa de teselas (tiles)
        TileLayer(
          urlTemplate: isDark
              ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
              : 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.example.tapsi',
          maxZoom: 19,
          minZoom: 3,
        ),
        if (widget.routeCoordinates != null && widget.routeCoordinates!.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: widget.routeCoordinates!,
                color: AppColors.primary.withOpacity(0.7),
                strokeWidth: 4.0,
              ),
            ],  
          ),
        
        // Capa de marcadores
        MarkerLayer(markers: _markers),
        
        // Capa de círculo para ubicación actual
        if (widget.currentLocation != null)
          CircleLayer(
            circles: [
              CircleMarker(
                point: LatLng(
                  widget.currentLocation!.latitude,
                  widget.currentLocation!.longitude,
                ),
                color: AppColors.primary.withOpacity(0.2),
                borderColor: AppColors.primary.withOpacity(0.5),
                borderStrokeWidth: 2,
                radius: 20,
              ),
            ],
          ),
      ],
    );
  }
}