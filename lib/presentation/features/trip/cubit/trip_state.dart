part of 'trip_cubit.dart';

abstract class TripState extends Equatable {
  const TripState();
  
  @override
  List<Object?> get props => [];
}

class TripInitial extends TripState {}

class TripLoading extends TripState {
  final String? message;
  
  const TripLoading({this.message});
  
  @override
  List<Object?> get props => [message];
}

// Estado cuando se está seleccionando el tipo de vehículo
class TripVehicleSelection extends TripState {
  final LocationModel origin;
  final LocationModel destination;
  final double estimatedDistance;
  final int estimatedDuration;
  
  const TripVehicleSelection({
    required this.origin,
    required this.destination,
    required this.estimatedDistance,
    required this.estimatedDuration,
  });
  
  @override
  List<Object?> get props => [origin, destination, estimatedDistance, estimatedDuration];
}

// Estado cuando el viaje fue creado y está buscando conductor
class TripSearchingDriver extends TripState {
  final TripModel trip;
  
  const TripSearchingDriver({required this.trip});
  
  @override
  List<Object?> get props => [trip];
}

// Estado cuando un conductor aceptó el viaje
class TripDriverAssigned extends TripState {
  final TripModel trip;
  final DriverModel driver;
  
  const TripDriverAssigned({
    required this.trip,
    required this.driver,
  });
  
  @override
  List<Object?> get props => [trip, driver];
}

// Estado cuando el conductor está en camino
class TripDriverArriving extends TripState {
  final TripModel trip;
  final DriverModel driver;
  final double? eta; // estimated time of arrival in minutes
  
  const TripDriverArriving({
    required this.trip,
    required this.driver,
    this.eta,
  });
  
  @override
  List<Object?> get props => [trip, driver, eta];
}

// Estado cuando el viaje está en progreso
class TripInProgress extends TripState {
  final TripModel trip;
  final DriverModel driver;
  
  const TripInProgress({
    required this.trip,
    required this.driver,
  });
  
  @override
  List<Object?> get props => [trip, driver];
}

// Estado cuando el viaje fue completado
class TripCompleted extends TripState {
  final TripModel trip;
  
  const TripCompleted({required this.trip});
  
  @override
  List<Object?> get props => [trip];
}

// Estado cuando el viaje fue cancelado
class TripCancelled extends TripState {
  final String? reason;
  
  const TripCancelled({this.reason});
  
  @override
  List<Object?> get props => [reason];
}

// Estado de error
class TripError extends TripState {
  final String message;
  
  const TripError({required this.message});
  
  @override
  List<Object?> get props => [message];
}

// Estado cuando se carga el historial
class TripHistoryLoaded extends TripState {
  final List<TripModel> trips;
  
  const TripHistoryLoaded({required this.trips});
  
  @override
  List<Object?> get props => [trips];
}
class TripDriverArrived extends TripState {
  final TripModel trip;
  final DriverModel driver;

  const TripDriverArrived({
    required this.trip,
    required this.driver,
  });

  @override
  List<Object?> get props => [trip, driver];
}