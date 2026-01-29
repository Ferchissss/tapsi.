import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tapsi/core/constants/colors.dart';
import 'package:tapsi/core/constants/text_styles.dart';
import 'package:tapsi/data/models/location_model.dart';
import 'package:tapsi/presentation/features/trip/cubit/trip_cubit.dart';
import 'package:tapsi/presentation/features/trip/screens/trip_waiting_screen.dart';

class VehicleSelectionScreen extends StatefulWidget {
  final LocationModel origin;
  final LocationModel destination;
  final double estimatedDistance;
  final int estimatedDuration;

  const VehicleSelectionScreen({
    super.key,
    required this.origin,
    required this.destination,
    required this.estimatedDistance,
    required this.estimatedDuration,
  });

  @override
  State<VehicleSelectionScreen> createState() => _VehicleSelectionScreenState();
}

class _VehicleSelectionScreenState extends State<VehicleSelectionScreen> {
  String _selectedVehicleType = 'standard';

  // Calcular tarifas por tipo de vehículo
  Map<String, double> get _fares {
    const baseFare = 5.0;
    const perKmRate = 2.5;
    final distanceInKm = widget.estimatedDistance / 1000;
    final basePrice = baseFare + (distanceInKm * perKmRate);

    return {
      'standard': basePrice,
      'premium': basePrice * 1.5,
      'van': basePrice * 2.0,
    };
  }

  void _requestTrip() {
    final tripCubit = context.read<TripCubit>();
    
    tripCubit.createTrip(
      originLat: widget.origin.latitude,
      originLng: widget.origin.longitude,
      originAddress: widget.origin.address ?? '',
      destLat: widget.destination.latitude,
      destLng: widget.destination.longitude,
      destAddress: widget.destination.address ?? '',
      vehicleType: _selectedVehicleType,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecciona tu vehículo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocListener<TripCubit, TripState>(
        listener: (context, state) {
          if (state is TripSearchingDriver || state is TripDriverAssigned) {
            final tripCubit = context.read<TripCubit>();
            // Navegar a pantalla de búsqueda/conductor
            Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => BlocProvider<TripCubit>.value(
                value: tripCubit,
                child: TripWaitingScreen(
                    trip: state is TripSearchingDriver 
                    ? state.trip 
                    : (state as TripDriverAssigned).trip,
                ),
                ),
            ),
            );
          } else if (state is TripError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: Column(
          children: [
            // Información del viaje
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Origen
                  _buildLocationRow(
                    icon: Icons.circle,
                    color: Colors.green,
                    text: widget.origin.address ?? 'Origen',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  // Destino
                  _buildLocationRow(
                    icon: Icons.location_on,
                    color: Colors.red,
                    text: widget.destination.address ?? 'Destino',
                    isDark: isDark,
                  ),
                  const Divider(height: 24),
                  // Info del viaje
                  Row(
                    children: [
                      Icon(Icons.route, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        '${(widget.estimatedDistance / 1000).toStringAsFixed(1)} km',
                        style: AppTextStyles.body,
                      ),
                      const SizedBox(width: 20),
                      Icon(Icons.timer, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.estimatedDuration} min',
                        style: AppTextStyles.body,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Opciones de vehículos
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Elige tu tipo de vehículo',
                    style: AppTextStyles.h3.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Estándar
                  _buildVehicleOption(
                    type: 'standard',
                    icon: '🚗',
                    title: 'Estándar',
                    description: 'Vehículo estándar, económico',
                    capacity: '4 pasajeros',
                    fare: _fares['standard']!,
                    isDark: isDark,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Con parrilla (Premium)
                  _buildVehicleOption(
                    type: 'premium',
                    icon: '🚙',
                    title: 'Con parrilla',
                    description: 'Vehículo con espacio para equipaje',
                    capacity: '4 pasajeros + equipaje',
                    fare: _fares['premium']!,
                    isDark: isDark,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Van
                  _buildVehicleOption(
                    type: 'van',
                    icon: '🚐',
                    title: 'Van',
                    description: 'Para grupos grandes',
                    capacity: '6+ pasajeros',
                    fare: _fares['van']!,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            
            // Botón de confirmar
            Container(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: BlocBuilder<TripCubit, TripState>(
                builder: (context, state) {
                  final isLoading = state is TripLoading;
                  
                  return SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _requestTrip,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'CONFIRMAR VIAJE - Bs ${_fares[_selectedVehicleType]!.toStringAsFixed(2)}',
                              style: AppTextStyles.button.copyWith(
                                color: Colors.white,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color color,
    required String text,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.body.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleOption({
    required String type,
    required String icon,
    required String title,
    required String description,
    required String capacity,
    required double fare,
    required bool isDark,
  }) {
    final isSelected = _selectedVehicleType == type;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedVehicleType = type;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // Icono del vehículo
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.primary.withOpacity(0.1)
                    : (isDark ? AppColors.darkDisabled : AppColors.lightDisabled).withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Info del vehículo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.bodyBold.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTextStyles.caption.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 14,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        capacity,
                        style: AppTextStyles.small.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Precio
            Text(
              'Bs ${fare.toStringAsFixed(2)}',
              style: AppTextStyles.bodyBold.copyWith(
                color: isSelected ? AppColors.primary : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}