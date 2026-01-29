part of 'home_cubit.dart';

@immutable
abstract class HomeState {
  const HomeState();
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final LocationModel currentLocation;
  final LatLng mapCenter;
  final double zoom;
  final LocationModel? selectedLocation;
  final List<LocationModel> nearbyTaxis;

  const HomeLoaded({
    required this.currentLocation,
    required this.mapCenter,
    this.zoom = 15.0,
    this.selectedLocation,
    this.nearbyTaxis = const [],
  });

  HomeLoaded copyWith({
    LocationModel? currentLocation,
    LatLng? mapCenter,
    double? zoom,
    LocationModel? selectedLocation,
    List<LocationModel>? nearbyTaxis,
  }) {
    return HomeLoaded(
      currentLocation: currentLocation ?? this.currentLocation,
      mapCenter: mapCenter ?? this.mapCenter,
      zoom: zoom ?? this.zoom,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      nearbyTaxis: nearbyTaxis ?? this.nearbyTaxis,
    );
  }
}

class HomeError extends HomeState {
  final String message;
  final bool isPermissionError;

  const HomeError({
    required this.message,
    this.isPermissionError = false,
  });
}
class LocationSelectionState {
  final LocationModel? origin;
  final LocationModel? destination;
  
  const LocationSelectionState({
    this.origin,
    this.destination,
  });
  
  LocationSelectionState copyWith({
    LocationModel? origin,
    LocationModel? destination,
  }) {
    return LocationSelectionState(
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
    );
  }
}