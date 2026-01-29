// lib/presentation/features/trip/cubit/trip_history_state.dart

part of 'trip_history_cubit.dart';

abstract class TripHistoryState extends Equatable {
  const TripHistoryState();

  @override
  List<Object?> get props => [];
}

class TripHistoryInitial extends TripHistoryState {}

class TripHistoryLoading extends TripHistoryState {}

class TripHistoryLoaded extends TripHistoryState {
  final List<TripModel> trips;
  final int currentPage;
  final bool hasMore;
  final int totalTrips;
  final bool isLoadingMore;

  const TripHistoryLoaded({
    required this.trips,
    required this.currentPage,
    required this.hasMore,
    required this.totalTrips,
    this.isLoadingMore = false,
  });

  TripHistoryLoaded copyWith({
    List<TripModel>? trips,
    int? currentPage,
    bool? hasMore,
    int? totalTrips,
    bool? isLoadingMore,
  }) {
    return TripHistoryLoaded(
      trips: trips ?? this.trips,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      totalTrips: totalTrips ?? this.totalTrips,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [trips, currentPage, hasMore, totalTrips, isLoadingMore];
}

class TripHistoryError extends TripHistoryState {
  final String message;

  const TripHistoryError({required this.message});

  @override
  List<Object?> get props => [message];
}