import 'package:equatable/equatable.dart';

class LocationModel extends Equatable {
  final double latitude;
  final double longitude;
  final String? address;
  final String? name;
  final String? placeId;

  const LocationModel({
    required this.latitude,
    required this.longitude,
    this.address,
    this.name,
    this.placeId,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      name: json['name'] as String?,
      placeId: json['placeId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'name': name,
      'placeId': placeId,
    };
  }

  static LocationModel empty() {
    return const LocationModel(latitude: 0, longitude: 0);
  }

  @override
  List<Object?> get props => [
    latitude, 
    longitude, 
    address, 
    name, 
    placeId
  ];
}