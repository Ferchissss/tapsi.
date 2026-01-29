// lib/presentation/features/trip/screens/trip_waiting_screen_updated.dart
// ESTE ARCHIVO ACTUALIZA trip_waiting_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  // ✅ NUEVO: Simular transiciones de estados (temporal para testing)
  void _simulateTransitions(BuildContext context) {
    final cubit = context.read<TripCubit>();
    final currentState = cubit.state;

    if (currentState is TripDriverAssigned) {
      // Simular: Chofer en camino
      cubit.driverArriving(eta: 3.0);
    } else if (currentState is TripDriverArriving) {
      // Simular: Chofer llegó
      cubit.driverArrived();
    } else if (currentState is TripDriverArrived) {
      // Simular: Iniciar viaje
      cubit.startTrip();
    } else if (currentState is TripInProgress) {
      // Simular: Completar viaje
      cubit.completeTrip();
    }
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
        // ✅ BOTÓN DE TESTING (solo en desarrollo)
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _simulateTransitions(context),
          label: const Text('Siguiente Estado'),
          icon: const Icon(Icons.skip_next),
          backgroundColor: AppColors.primary,
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
        SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.all(24),
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
            ],
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
          child: _buildDriverInfoPanel(
            driver,
            trip,
            isDark,
            statusText: 'Conductor asignado',
            statusColor: AppColors.primary,
          ),
        ),
      ],
    );
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
                  '🚗 Viaje en progreso',
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