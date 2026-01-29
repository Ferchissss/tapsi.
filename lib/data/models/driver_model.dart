import 'package:equatable/equatable.dart';

// Este archivo va en lib/data/models/driver_model.dart

class DriverModel extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? photoUrl;
  final String licenseNumber;
  final String status; // 'offline', 'available', 'busy', 'on_break'
  final double rating;
  final int totalTrips;
  final VehicleModel? vehicle;
  final double? currentLat;
  final double? currentLng;

  const DriverModel({
    required this.id,
    required this.userId,
    required this.name,
    this.photoUrl,
    required this.licenseNumber,
    required this.status,
    required this.rating,
    required this.totalTrips,
    this.vehicle,
    this.currentLat,
    this.currentLng,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String? ?? json['user']?['name'] as String? ?? 'Conductor',
      photoUrl: json['photoUrl'] as String? ?? json['user']?['photoUrl'] as String?,
      licenseNumber: json['licenseNumber'] as String,
      status: json['status'] as String,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      totalTrips: (json['totalTrips'] as num?)?.toInt() ?? 0,
      vehicle: json['vehicle'] != null 
          ? VehicleModel.fromJson(json['vehicle'] as Map<String, dynamic>)
          : null,
      currentLat: (json['currentLat'] as num?)?.toDouble(),
      currentLng: (json['currentLng'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'photoUrl': photoUrl,
      'licenseNumber': licenseNumber,
      'status': status,
      'rating': rating,
      'totalTrips': totalTrips,
      'vehicle': vehicle?.toJson(),
      'currentLat': currentLat,
      'currentLng': currentLng,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        photoUrl,
        licenseNumber,
        status,
        rating,
        totalTrips,
        vehicle,
        currentLat,
        currentLng,
      ];
}

class VehicleModel extends Equatable {
  final String id;
  final String type; // 'standard', 'premium', 'van'
  final String plate;
  final String color;
  final String brand;
  final String model;
  final int year;
  final int capacity;

  const VehicleModel({
    required this.id,
    required this.type,
    required this.plate,
    required this.color,
    required this.brand,
    required this.model,
    required this.year,
    required this.capacity,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] as String,
      type: json['type'] as String,
      plate: json['plate'] as String,
      color: json['color'] as String,
      brand: json['brand'] as String,
      model: json['model'] as String,
      year: (json['year'] as num).toInt(),
      capacity: (json['capacity'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'plate': plate,
      'color': color,
      'brand': brand,
      'model': model,
      'year': year,
      'capacity': capacity,
    };
  }

  String get displayName => '$brand $model ($year)';
  
  String get typeDisplay {
    switch (type) {
      case 'standard':
        return 'Estándar';
      case 'premium':
        return 'Premium';
      case 'van':
        return 'Van';
      default:
        return type;
    }
  }

  @override
  List<Object?> get props => [id, type, plate, color, brand, model, year, capacity];
}