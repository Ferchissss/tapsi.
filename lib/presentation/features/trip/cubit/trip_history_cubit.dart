// lib/presentation/features/trip/cubit/trip_history_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tapsi/core/services/api_service.dart';
import 'package:tapsi/data/models/trip_model.dart';

part 'trip_history_state.dart';

class TripHistoryCubit extends Cubit<TripHistoryState> {
  final ApiService _apiService;

  TripHistoryCubit(this._apiService) : super(TripHistoryInitial());

  // Cargar historial de viajes
  Future<void> loadTripHistory({int page = 1, int limit = 20}) async {
    try {
      // Si es la primera página, mostrar loading
      if (page == 1) {
        emit(TripHistoryLoading());
      } else {
        // Si es paginación, mantener el estado actual con isLoadingMore
        if (state is TripHistoryLoaded) {
          final currentState = state as TripHistoryLoaded;
          emit(currentState.copyWith(isLoadingMore: true));
        }
      }

      final response = await _apiService.get(
        '/api/v1/trips/history',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
        requiresAuth: true,
      );

      if (response['success'] == true) {
        final data = response['data'];
        final tripsData = data['trips'] as List;
        final trips = tripsData.map((json) => TripModel.fromJson(json)).toList();
        
        final pagination = data['pagination'];

        // Si estamos en paginación, agregar a la lista existente
        if (page > 1 && state is TripHistoryLoaded) {
          final currentState = state as TripHistoryLoaded;
          emit(TripHistoryLoaded(
            trips: [...currentState.trips, ...trips],
            currentPage: pagination['page'],
            hasMore: pagination['hasMore'],
            totalTrips: pagination['total'],
          ));
        } else {
          emit(TripHistoryLoaded(
            trips: trips,
            currentPage: pagination['page'],
            hasMore: pagination['hasMore'],
            totalTrips: pagination['total'],
          ));
        }
      } else {
        emit(TripHistoryError(message: response['error'] ?? 'Error al cargar historial'));
      }
    } catch (e) {
      print('❌ Error loading trip history: $e');
      emit(TripHistoryError(message: 'Error al cargar historial: $e'));
    }
  }

  // Recargar (pull to refresh)
  Future<void> refresh() async {
    await loadTripHistory(page: 1);
  }

  // Cargar más (paginación)
  Future<void> loadMore() async {
    if (state is TripHistoryLoaded) {
      final currentState = state as TripHistoryLoaded;
      if (currentState.hasMore && !currentState.isLoadingMore) {
        await loadTripHistory(page: currentState.currentPage + 1);
      }
    }
  }
}