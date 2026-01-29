import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:tapsi/core/constants/colors.dart';
import 'package:tapsi/core/constants/text_styles.dart';
import 'package:tapsi/core/services/location_service.dart';
import 'package:tapsi/data/models/location_model.dart';
import 'package:tapsi/presentation/features/home/cubit/home_cubit.dart';
import 'package:tapsi/presentation/widgets/custom/open_street_map.dart';

class MapSelectionScreen extends StatefulWidget {
  final String selectionType; // 'origin' o 'destination'
  final LocationModel? initialLocation;
  final LocationModel currentLocation;

  const MapSelectionScreen({
    super.key,
    required this.selectionType,
    this.initialLocation,
    required this.currentLocation,
  });

  @override
  State<MapSelectionScreen> createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  LatLng? _selectedPosition;
  String? _selectedAddress;
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedPosition = LatLng(
        widget.initialLocation!.latitude,
        widget.initialLocation!.longitude,
      );
      _selectedAddress = widget.initialLocation!.address;
    }
  }

  Future<void> _getAddressFromPosition(LatLng position) async {
    setState(() => _isLoadingAddress = true);
    
    try {
        // Usa LocationService directamente
        final locationService = LocationService();
        final address = await locationService.getAddressFromLatLng(
        position.latitude,
        position.longitude,
        );
        
        setState(() {
        _selectedAddress = address;
        _isLoadingAddress = false;
        });
    } catch (e) {
        setState(() {
        _selectedAddress = 'Ubicación seleccionada';
        _isLoadingAddress = false;
        });
    }
    }

  void _handleMapTap(LatLng position) {
    setState(() {
      _selectedPosition = position;
    });
    _getAddressFromPosition(position);
  }

  void _confirmSelection() {
    if (_selectedPosition != null) {
      final location = LocationModel(
        latitude: _selectedPosition!.latitude,
        longitude: _selectedPosition!.longitude,
        address: _selectedAddress ?? 'Ubicación seleccionada',
        name: widget.selectionType == 'origin' ? 'Origen' : 'Destino',
      );

      final homeCubit = context.read<HomeCubit>();
      
      if (widget.selectionType == 'origin') {
        homeCubit.setOrigin(location);
      } else {
        homeCubit.setDestination(location);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.selectionType == 'origin' 
            ? 'Seleccionar origen' 
            : 'Seleccionar destino',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state is! HomeLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final initialCenter = _selectedPosition ?? 
            LatLng(
              state.currentLocation.latitude,
              state.currentLocation.longitude,
            );

          return Stack(
            children: [
              // Mapa
              OpenStreetMap(
                center: initialCenter,
                zoom: 15.0,
                currentLocation: state.currentLocation,
                selectedOrigin: null, // o podrías usar esto si quieres mostrar algo
                selectedDestination: null,
                onTap: _handleMapTap,
              ),

              // Indicador de selección
              if (_selectedPosition != null)
                Positioned(
                  top: MediaQuery.of(context).size.height / 2 - 40,
                  left: MediaQuery.of(context).size.width / 2 - 20,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary,
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),

              Positioned(
                bottom: 200, // Ajusta esta posición según necesites
                right: 16,
                child: FloatingActionButton.small(
                    heroTag: 'map_selection_location_fab',
                    onPressed: _centerOnCurrentLocation,
                    backgroundColor: isDark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                    child: Icon(
                    Icons.my_location,
                    color: AppColors.primary,
                    ),
                ),
              ),
              // Panel inferior
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.selectionType == 'origin' 
                            ? 'Origen seleccionado:' 
                            : 'Destino seleccionado:',
                          style: AppTextStyles.caption.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        if (_isLoadingAddress)
                          Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              const SizedBox(width: 12),
                              Text(
                                'Obteniendo dirección...',
                                style: AppTextStyles.body.copyWith(
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                            ],
                          )
                        else if (_selectedAddress != null)
                          Text(
                            _selectedAddress!,
                            style: AppTextStyles.bodyBold.copyWith(
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          )
                        else
                          Text(
                            'Toca en el mapa para seleccionar ubicación',
                            style: AppTextStyles.body.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        
                        const SizedBox(height: 20),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _selectedPosition != null ? _confirmSelection : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'CONFIRMAR ${widget.selectionType == 'origin' ? 'ORIGEN' : 'DESTINO'}',
                              style: AppTextStyles.button.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  void _centerOnCurrentLocation() {
    final homeCubit = context.read<HomeCubit>();
    final state = homeCubit.state;
    
    if (state is HomeLoaded) {
        // Si estamos seleccionando origen/destino, también podemos actualizar la selección
        final position = LatLng(
        state.currentLocation.latitude,
        state.currentLocation.longitude,
        );
        
        // Centrar el mapa en la ubicación actual
        // Necesitarás acceder al MapController del OpenStreetMap
        // O enviar un evento al cubit para actualizar el centro
        
        // Opción 1: Si usas cubit para manejar el centro del mapa
        homeCubit.updateMapCenter(position, 15.0);
        
        // Opción 2: También podrías seleccionar automáticamente esta ubicación
        _handleMapTap(position);
        
        // Obtener la dirección
        _getAddressFromPosition(position);
    }
    }
}