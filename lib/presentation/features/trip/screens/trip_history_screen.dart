// lib/presentation/features/trip/screens/trip_history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tapsi/core/constants/colors.dart';
import 'package:tapsi/core/constants/text_styles.dart';
import 'package:tapsi/core/services/api_service.dart';
import 'package:tapsi/data/models/trip_model.dart';
import 'package:tapsi/presentation/features/trip/cubit/trip_history_cubit.dart';
import 'package:tapsi/presentation/widgets/common/loading_indicator.dart';
import 'package:tapsi/presentation/widgets/common/empty_state.dart';
import 'package:intl/intl.dart';

class TripHistoryScreen extends StatelessWidget {
  const TripHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TripHistoryCubit(context.read<ApiService>())
        ..loadTripHistory(),
      child: const TripHistoryView(),
    );
  }
}

class TripHistoryView extends StatefulWidget {
  const TripHistoryView({super.key});

  @override
  State<TripHistoryView> createState() => _TripHistoryViewState();
}

class _TripHistoryViewState extends State<TripHistoryView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      context.read<TripHistoryCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Viajes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<TripHistoryCubit, TripHistoryState>(
        builder: (context, state) {
          if (state is TripHistoryLoading) {
            return const FullScreenLoader(message: 'Cargando historial...');
          }

          if (state is TripHistoryError) {
            return Center(
              child: EmptyState(
                title: 'Error al cargar',
                description: state.message,
                icon: Icons.error_outline,
                iconColor: AppColors.error,
                onAction: () => context.read<TripHistoryCubit>().refresh(),
                actionText: 'Reintentar',
              ),
            );
          }

          if (state is TripHistoryLoaded) {
            if (state.trips.isEmpty) {
              return EmptyState(
                title: 'Sin viajes aún',
                description: 'Tus viajes aparecerán aquí',
                icon: Icons.directions_car_outlined,
                onAction: () => Navigator.pop(context),
                actionText: 'Solicitar viaje',
              );
            }

            return RefreshIndicator(
              onRefresh: () => context.read<TripHistoryCubit>().refresh(),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: state.trips.length + (state.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= state.trips.length) {
                    // Mostrar indicador de carga al final
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final trip = state.trips[index];
                  return TripHistoryCard(
                    trip: trip,
                    isDark: isDark,
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class TripHistoryCard extends StatelessWidget {
  final TripModel trip;
  final bool isDark;

  const TripHistoryCard({
    super.key,
    required this.trip,
    required this.isDark,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      case 'ongoing':
        return AppColors.info;
      default:
        return AppColors.warning;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return 'Completado';
      case 'cancelled':
        return 'Cancelado';
      case 'ongoing':
        return 'En progreso';
      case 'searching':
        return 'Buscando';
      case 'accepted':
        return 'Aceptado';
      case 'arriving':
        return 'Llegando';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hoy ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Ayer ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} días atrás';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navegar a detalles del viaje
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Estado y Fecha
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Estado
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(trip.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(trip.status),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: _getStatusColor(trip.status),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getStatusText(trip.status),
                          style: AppTextStyles.caption.copyWith(
                            color: _getStatusColor(trip.status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Fecha
                  Text(
                    _formatDate(trip.requestedAt),
                    style: AppTextStyles.caption.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Origen y Destino
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Iconos de ubicación
                  Column(
                    children: [
                      Icon(
                        Icons.circle,
                        color: Colors.green,
                        size: 16,
                      ),
                      Container(
                        width: 2,
                        height: 30,
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                      Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Direcciones
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.originAddress,
                          style: AppTextStyles.body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 28),
                        Text(
                          trip.destAddress,
                          style: AppTextStyles.body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Footer: Precio, Distancia, Duración
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Precio
                  if (trip.finalFare != null || trip.estimatedFare > 0)
                    Row(
                      children: [
                        Icon(
                          Icons.payments,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Bs ${(trip.finalFare ?? trip.estimatedFare).toStringAsFixed(2)}',
                          style: AppTextStyles.bodyBold.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  // Distancia
                  Row(
                    children: [
                      Icon(
                        Icons.route,
                        size: 16,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${(trip.actualDistance ?? trip.estimatedDistance) / 1000} km',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                  // Duración
                  if (trip.actualDuration != null ||
                      trip.estimatedDuration > 0)
                    Row(
                      children: [
                        Icon(
                          Icons.timer,
                          size: 16,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${trip.actualDuration ?? trip.estimatedDuration} min',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}