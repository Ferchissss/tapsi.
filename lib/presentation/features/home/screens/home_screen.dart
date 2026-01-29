import 'map_selection_screen.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:tapsi/core/constants/colors.dart';
import 'package:tapsi/core/constants/text_styles.dart';
import 'package:tapsi/core/theme/theme_manager.dart';
import 'package:tapsi/core/services/location_service.dart';
import 'package:tapsi/data/models/location_model.dart';
import 'package:tapsi/presentation/features/home/cubit/home_cubit.dart';
import 'package:tapsi/presentation/widgets/common/loading_indicator.dart';
import 'package:tapsi/presentation/widgets/common/location_selection_button.dart';
import 'package:tapsi/presentation/widgets/custom/open_street_map.dart';
import 'package:tapsi/presentation/features/home/screens/search_screen.dart';
import 'package:tapsi/presentation/features/trip/cubit/trip_cubit.dart';
import 'package:tapsi/presentation/features/trip/screens/vehicle_selection_screen.dart';
import 'package:tapsi/core/services/api_service.dart';
import 'package:tapsi/presentation/features/trip/screens/trip_history_screen.dart';
import 'package:tapsi/presentation/widgets/common/app_drawer.dart'; // ✅ NUEVO IMPORT

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _originActive = false;
  bool _destinationActive = false;

  @override
  void initState() {
    super.initState();
  }

  void _toggleOriginActive() {
    setState(() {
      _originActive = true;
      _destinationActive = false;
    });
  }

  void _toggleDestinationActive() {
    setState(() {
      _originActive = false;
      _destinationActive = true;
    });
  }

  void _resetActive() {
    setState(() {
      _originActive = false;
      _destinationActive = false;
    });
  }

  void _selectOriginFromSearch() {
    _toggleOriginActive();
    _openSearchScreen('origin');
  }

  void _selectDestinationFromSearch() {
    _toggleDestinationActive();
    _openSearchScreen('destination');
  }

  void _selectOriginFromMap() {
    _toggleOriginActive();
    _openMapSelection('origin');
  }

  void _selectDestinationFromMap() {
    _toggleDestinationActive();
    _openMapSelection('destination');
  }

  void _openSearchScreen(String selectionType) {
    final cubit = context.read<HomeCubit>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: cubit,
          child: SearchScreen(
            selectionType: selectionType,
          ),
        ),
      ),
    ).then((_) => _resetActive());
  }

  void _openMapSelection(String selectionType) {
    final cubit = context.read<HomeCubit>();
    final state = cubit.state;

    if (state is! HomeLoaded) {
      print("⚠️ No se puede abrir selección de mapa: estado no es HomeLoaded");
      return;
    }

    LocationModel? initialLocation;
    if (selectionType == 'origin' && cubit.selectedOrigin != null) {
      initialLocation = cubit.selectedOrigin;
    } else if (selectionType == 'destination' && cubit.selectedDestination != null) {
      initialLocation = cubit.selectedDestination;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: cubit,
          child: MapSelectionScreen(
            selectionType: selectionType,
            initialLocation: initialLocation,
            currentLocation: state.currentLocation,
          ),
        ),
      ),
    ).then((_) => _resetActive());
  }

  void _clearOrigin() {
    context.read<HomeCubit>().clearOrigin();
  }

  void _clearDestination() {
    context.read<HomeCubit>().clearDestination();
  }

  void _swapLocations() {
    context.read<HomeCubit>().swapOriginDestination();
  }

  void _centerOnMyLocation() {
    final cubit = context.read<HomeCubit>();
    final state = cubit.state;
    if (state is HomeLoaded) {
      cubit.updateMapCenter(
        LatLng(
          state.currentLocation.latitude,
          state.currentLocation.longitude,
        ),
        15.0,
      );
    }
  }

  void _requestTrip() {
    final cubit = context.read<HomeCubit>();
    final origin = cubit.selectedOrigin;
    final destination = cubit.selectedDestination;

    if (origin == null || destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Selecciona origen y destino'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => TripCubit(context.read<ApiService>()),
          child: VehicleSelectionScreen(
            origin: origin,
            destination: destination,
            estimatedDistance: cubit.estimatedDistance ?? 0,
            estimatedDuration: (cubit.estimatedTime ?? 0).toInt(),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSelectionPanel(HomeLoaded state) {
    final cubit = context.read<HomeCubit>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (cubit.selectedOrigin != null || cubit.selectedDestination != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: Icon(
                      Icons.swap_vert,
                      color: AppColors.primary,
                    ),
                    onPressed: _swapLocations,
                  ),
                ),
              LocationSelectionButton(
                label: 'ORIGEN',
                hintText: '¿Dónde estás?',
                address: cubit.selectedOrigin?.address,
                isActive: _originActive,
                onTap: _selectOriginFromSearch,
                onMapTap: _selectOriginFromMap,
                onClearTap: cubit.selectedOrigin != null ? _clearOrigin : null,
                showClearButton: cubit.selectedOrigin != null,
              ),
              const SizedBox(height: 12),
              Container(
                width: 2,
                height: 20,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),
              const SizedBox(height: 12),
              LocationSelectionButton(
                label: 'DESTINO',
                hintText: '¿A dónde vas?',
                address: cubit.selectedDestination?.address,
                isActive: _destinationActive,
                onTap: _selectDestinationFromSearch,
                onMapTap: _selectDestinationFromMap,
                onClearTap: cubit.selectedDestination != null ? _clearDestination : null,
                showClearButton: cubit.selectedDestination != null,
              ),
              if (cubit.isCalculatingRoute)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Calculando ruta...',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              if (cubit.routeCoordinates.isNotEmpty && !cubit.isCalculatingRoute)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_car, size: 16, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        '${cubit.estimatedDistance?.toStringAsFixed(1) ?? '?'} km',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(Icons.timer, size: 16, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        '${cubit.estimatedTime?.toStringAsFixed(0) ?? '?'} min',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: cubit.selectedOrigin != null && cubit.selectedDestination != null
                      ? _requestTrip
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'SOLICITAR VIAJE',
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
    );
  }

  Widget _buildHomeContent(HomeLoaded state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cubit = context.read<HomeCubit>();

    return Scaffold(
      drawer: const AppDrawer(), // ✅ AGREGAR DRAWER
      body: Stack(
        children: [
          OpenStreetMap(
            center: state.mapCenter,
            zoom: state.zoom,
            currentLocation: state.currentLocation,
            selectedOrigin: cubit.selectedOrigin,
            selectedDestination: cubit.selectedDestination,
            routeCoordinates: cubit.routeCoordinates,
            onMapMoved: (center, zoom) {
              context.read<HomeCubit>().updateMapCenter(center, zoom);
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // ✅ Avatar con funcionalidad de drawer
                  Builder(
                    builder: (context) => InkWell(
                      onTap: () {
                        Scaffold.of(context).openDrawer();
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TAPSI',
                          style: AppTextStyles.bodyBold.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (state.currentLocation.address != null)
                          Text(
                            state.currentLocation.address!,
                            style: AppTextStyles.small.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Consumer<ThemeManager>(
                    builder: (context, themeManager, child) {
                      return IconButton(
                        icon: Icon(
                          isDark ? Icons.light_mode : Icons.dark_mode,
                          color: AppColors.primary,
                        ),
                        onPressed: () {
                          themeManager.toggleTheme();
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 0,
            right: 0,
            child: _buildLocationSelectionPanel(state),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading) {
          return const FullScreenLoader(message: 'Obteniendo ubicación...');
        }

        if (state is HomeError) {
          return _buildErrorState(state);
        }

        if (state is HomeLoaded) {
          return _buildHomeContent(state);
        }

        return const Scaffold(
          body: LoadingIndicator(),
        );
      },
    );
  }

  Widget _buildErrorState(HomeError state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                state.isPermissionError
                    ? Icons.location_off
                    : Icons.error_outline,
                size: 80,
                color: AppColors.error,
              ),
              const SizedBox(height: 24),
              Text(
                state.isPermissionError
                    ? 'Permisos de ubicación requeridos'
                    : 'Error',
                style: AppTextStyles.h2.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                state.message,
                style: AppTextStyles.body.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (state.isPermissionError)
                ElevatedButton(
                  onPressed: () {
                    context.read<HomeCubit>().requestLocationPermission();
                  },
                  child: const Text('Dar permisos'),
                )
              else
                ElevatedButton(
                  onPressed: () {
                    context.read<HomeCubit>().initialize();
                  },
                  child: const Text('Reintentar'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateDistance(List<LatLng> points) {
    if (points.length < 2) return 0;
    double totalDistance = 0;
    for (int i = 0; i < points.length - 1; i++) {
      final lat1 = points[i].latitude;
      final lon1 = points[i].longitude;
      final lat2 = points[i + 1].latitude;
      final lon2 = points[i + 1].longitude;

      const p = 0.017453292519943295;
      final a = 0.5 -
          cos((lat2 - lat1) * p) / 2 +
          cos(lat1 * p) *
          cos(lat2 * p) *
          (1 - cos((lon2 - lon1) * p)) / 2;
      totalDistance += 12742 * asin(sqrt(a));
    }
    return totalDistance;
  }
}