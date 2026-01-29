// lib/presentation/features/trip/screens/trip_waiting_screen_updated.dart
// ESTE ARCHIVO ACTUALIZA trip_waiting_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tapsi/core/constants/colors.dart';
import 'package:tapsi/core/constants/text_styles.dart';
import 'package:tapsi/data/models/driver_model.dart';
import 'package:tapsi/data/models/trip_model.dart';
import 'package:tapsi/presentation/features/trip/cubit/trip_cubit.dart';
import 'package:tapsi/presentation/features/trip/screens/trip_rating_screen.dart';
import 'package:tapsi/presentation/widgets/custom/open_street_map.dart';

class TripWaitingScreen extends StatefulWidget {
  final TripModel trip;

  const TripWaitingScreen({
    super.key,
    required this.trip,
  });

  @override
  State<TripWaitingScreen> createState() => _TripWaitingScreenState();
}

class _TripWaitingScreenState extends State<TripWaitingScreen> {
  void _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se puede realizar la llamada')),
        );
      }
    }
  }

  void _openChat(BuildContext context) {
    // TODO: Implementar chat
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat en desarrollo')),
    );
  }

  void _cancelTrip(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Cancelar viaje?'),
        content: const Text('¿Estás seguro de que deseas cancelar este viaje?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('NO'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<TripCubit>().cancelTrip();
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: Text(
              'SÍ, CANCELAR',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async => false, // Prevenir salida con botón atrás
      child: Scaffold(
        body: BlocConsumer<TripCubit, TripState>(
          listener: (context, state) {
            if (state is TripCancelled) {
              Navigator.popUntil(context, (route) => route.isFirst);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Viaje cancelado')),
              );
            } else if (state is TripCompleted) {
              // Navegar a pantalla de calificación
              final driver = context.read<TripCubit>().currentDriver;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => TripRatingScreen(
                    trip: state.trip,
                    driver: driver,
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
          builder: (context, state) {
            // 1️⃣ BUSCANDO CONDUCTOR
            if (state is TripSearchingDriver) {
              return _buildSearchingDriver(state.trip, isDark);
            }
            
            // 2️⃣ CONDUCTOR ASIGNADO
            else if (state is TripDriverAssigned) {
              return _buildDriverAssigned(state.trip, state.driver, isDark);
            }
            
            // 3️⃣ CONDUCTOR EN CAMINO
            else if (state is TripDriverArriving) {
              return _buildDriverArriving(
                state.trip,
                state.driver,
                state.eta,
                isDark,
              );
            }
            
            // 4️⃣ CONDUCTOR LLEGÓ (esperando)
            else if (state is TripDriverArrived) {
              return _buildDriverArrived(state.trip, state.driver, isDark);
            }
            
            // 5️⃣ VIAJE EN PROGRESO
            else if (state is TripInProgress) {
              return _buildTripInProgress(state.trip, state.driver, isDark);
            }
            
            // LOADING
            else if (state is TripLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(state.message ?? 'Cargando...'),
                  ],
                ),
              );
            }

            // Estado por defecto
            return _buildSearchingDriver(widget.trip, isDark);
          },
        ),
      ),
    );
  }

  // ========== VISTAS POR ESTADO ==========

  // 1️⃣ BUSCANDO CONDUCTOR
  Widget _buildSearchingDriver(TripModel trip, bool isDark) {
    return Stack(
      children: [
        OpenStreetMap(
          center: LatLng(trip.originLat, trip.originLng),
          zoom: 14.0,
          selectedOrigin: null,
          selectedDestination: null,
        ),
        Container(color: Colors.black.withOpacity(0.3)),
        Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        strokeWidth: 6,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Buscando conductor',
                      style: AppTextStyles.h2.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Esto puede tomar unos segundos...',
                      style: AppTextStyles.body.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => _cancelTrip(context),
                      child: Text(
                        'Cancelar búsqueda',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 2️⃣ CONDUCTOR ASIGNADO
  Widget _buildDriverAssigned(TripModel trip, DriverModel driver, bool isDark) {
    return Stack(
      children: [
        OpenStreetMap(
          center: LatLng(
            (trip.originLat + (driver.currentLat ?? trip.originLat)) / 2,
            (trip.originLng + (driver.currentLng ?? trip.originLng)) / 2,
          ),
          zoom: 14.0,
          selectedOrigin: null,
          selectedDestination: null,
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Título
                  Text(
                    'Tu conductor está aquí',
                    style: AppTextStyles.h2.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Foto grande del conductor
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: driver.photoUrl != null
                        ? ClipOval(
                            child: Image.network(
                              driver.photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 70,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 70,
                          ),
                  ),
                  const SizedBox(height: 20),

                  // Información del conductor
                  Text(
                    driver.name,
                    style: AppTextStyles.h2.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Rating y viajes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '${driver.rating.toStringAsFixed(1)}',
                        style: AppTextStyles.bodyBold.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        ' • ${driver.totalTrips} viajes',
                        style: AppTextStyles.body.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Información del vehículo con imagen
                  if (driver.vehicle != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface.withOpacity(0.5)
                            : AppColors.lightSurface.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Imagen del vehículo
                          Container(
                            width: 120,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey.withOpacity(0.3),
                            ),
                            child: Image.asset(
                              _getVehicleImage(driver.vehicle!.type),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Icon(
                                  Icons.directions_car,
                                  size: 40,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Detalles del vehículo
                          Text(
                            driver.vehicle!.displayName,
                            style: AppTextStyles.bodyBold.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${driver.vehicle!.plate} • ${driver.vehicle!.color}',
                            style: AppTextStyles.caption.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Botones de aceptar/rechazar
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _cancelTrip(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: AppColors.error,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Rechazar',
                            style: AppTextStyles.button.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Aceptar el viaje - transicionar al siguiente estado
                            context.read<TripCubit>().driverArriving(eta: 5.0);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Aceptar viaje',
                            style: AppTextStyles.button.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Método para obtener imagen del vehículo según el tipo
  String _getVehicleImage(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'standard':
      case 'sedan':
        return 'assets/images/honda.jfif';
      case 'premium':
      case 'suv':
        return 'assets/images/toyota.jpg';
      default:
        return 'assets/images/toyota.jpg';
    }
  }

  // 3️⃣ CONDUCTOR EN CAMINO
  Widget _buildDriverArriving(
    TripModel trip,
    DriverModel driver,
    double? eta,
    bool isDark,
  ) {
    return Stack(
      children: [
        OpenStreetMap(
          center: LatLng(
            (trip.originLat + (driver.currentLat ?? trip.originLat)) / 2,
            (trip.originLng + (driver.currentLng ?? trip.originLng)) / 2,
          ),
          zoom: 14.0,
          selectedOrigin: null,
          selectedDestination: null,
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildDriverInfoPanel(
            driver,
            trip,
            isDark,
            statusText: 'Llegando en ${eta?.toInt() ?? 5} min',
            statusColor: AppColors.warning,
            showEta: true,
            eta: eta,
            showVehicleImage: true,
          ),
        ),
      ],
    );
  }

  // 4️⃣ CONDUCTOR LLEGÓ
  Widget _buildDriverArrived(TripModel trip, DriverModel driver, bool isDark) {
    return Stack(
      children: [
        OpenStreetMap(
          center: LatLng(trip.originLat, trip.originLng),
          zoom: 15.0,
          selectedOrigin: null,
          selectedDestination: null,
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildDriverInfoPanel(
            driver,
            trip,
            isDark,
            statusText: ' Conductor llegó - Esperándote',
            statusColor: AppColors.success,
            showStartTripButton: true,
            showVehicleImage: true,
          ),
        ),
      ],
    );
  }

  // 5️⃣ VIAJE EN PROGRESO
  Widget _buildTripInProgress(TripModel trip, DriverModel driver, bool isDark) {
    return Stack(
      children: [
        OpenStreetMap(
          center: LatLng(trip.originLat, trip.originLng),
          zoom: 14.0,
          selectedOrigin: null,
          selectedDestination: null,
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Viaje en progreso',
                  style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.chat,
                      label: 'Chat',
                      onPressed: () => _openChat(context),
                      isDark: isDark,
                    ),
                    _buildActionButton(
                      icon: Icons.phone,
                      label: 'Llamar',
                      onPressed: () => _makePhoneCall('+591 12345678'),
                      isDark: isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ========== COMPONENTES COMPARTIDOS ==========

  Widget _buildDriverInfoPanel(
    DriverModel driver,
    TripModel trip,
    bool isDark, {
    required String statusText,
    required Color statusColor,
    bool showEta = false,
    double? eta,
    bool showStartTripButton = false,
    bool showVehicleImage = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicador de estado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusText,
              style: AppTextStyles.bodyBold.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          // Información del conductor
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: driver.photoUrl != null
                    ? ClipOval(
                        child: Image.network(
                          driver.photoUrl!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 35,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.name,
                      style: AppTextStyles.h3.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${driver.rating.toStringAsFixed(1)} • ${driver.totalTrips} viajes',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (driver.vehicle != null) ...[
                      Text(
                        '${driver.vehicle!.displayName}',
                        style: AppTextStyles.body,
                      ),
                      Text(
                        'Placa: ${driver.vehicle!.plate} • ${driver.vehicle!.color}',
                        style: AppTextStyles.caption.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Imagen del vehículo (si aplica)
          if (showVehicleImage && driver.vehicle != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurface.withOpacity(0.5)
                    : AppColors.lightSurface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Imagen del vehículo
                  Container(
                    width: 120,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.withOpacity(0.3),
                    ),
                    child: Image.asset(
                      _getVehicleImage(driver.vehicle!.type),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(
                          Icons.directions_car,
                          size: 40,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Detalles del vehículo
                  Text(
                    driver.vehicle!.displayName,
                    style: AppTextStyles.bodyBold.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${driver.vehicle!.plate} • ${driver.vehicle!.color}',
                    style: AppTextStyles.caption.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          if (showVehicleImage) const SizedBox(height: 16),
          // Botones de acción
          if (showStartTripButton)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  context.read<TripCubit>().startTrip();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'INICIAR VIAJE',
                  style: AppTextStyles.button.copyWith(color: Colors.white),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.chat,
                    label: 'Chat',
                    onPressed: () => _openChat(context),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.phone,
                    label: 'Llamar',
                    onPressed: () => _makePhoneCall('+591 12345678'),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.close,
                    label: 'Cancelar',
                    onPressed: () => _cancelTrip(context),
                    isDark: isDark,
                    isDestructive: true,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isDark,
    bool isDestructive = false,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: isDestructive ? AppColors.error : AppColors.primary,
          width: 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isDestructive ? AppColors.error : AppColors.primary,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: isDestructive ? AppColors.error : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}