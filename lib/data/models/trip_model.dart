import 'package:equatable/equatable.dart';
import 'package:tapsi/data/models/driver_model.dart';

class TripModel extends Equatable {
  final String id;
  final String userId;
  final String? driverId;
  final String status;
  final double originLat;
  final double originLng;
  final String originAddress;
  final double destLat;
  final double destLng;
  final String destAddress;
  final String vehicleType;
  final double estimatedFare;
  final double? finalFare;
  final double estimatedDistance;
  final double? actualDistance;
  final int estimatedDuration;
  final int? actualDuration;
  final DateTime requestedAt;
  final DateTime? acceptedAt;
  final DateTime? arrivedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  
  const TripModel({
    required this.id,
    required this.userId,
    this.driverId,
    required this.status,
    required this.originLat,
    required this.originLng,
    required this.originAddress,
    required this.destLat,
    required this.destLng,
    required this.destAddress,
    required this.vehicleType,
    required this.estimatedFare,
    this.finalFare,
    required this.estimatedDistance,
    this.actualDistance,
    required this.estimatedDuration,
    this.actualDuration,
    required this.requestedAt,
    this.acceptedAt,
    this.arrivedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
  });
  
  factory TripModel.fromJson(Map<String, dynamic> json) {
    // Helper para parsear DateTime desde string o Timestamp de Firestore
    DateTime _parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      // Firestore Timestamp tiene método toDate()
      if (value.runtimeType.toString() == 'Timestamp') {
        return value.toDate() as DateTime;
      }
      return DateTime.now();
    }

    return TripModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      driverId: json['driverId'],
      status: json['status'] ?? 'unknown',
      originLat: (json['originLat'] as num?)?.toDouble() ?? 0.0,
      originLng: (json['originLng'] as num?)?.toDouble() ?? 0.0,
      originAddress: json['originAddress'] ?? '',
      destLat: (json['destLat'] as num?)?.toDouble() ?? 0.0,
      destLng: (json['destLng'] as num?)?.toDouble() ?? 0.0,
      destAddress: json['destAddress'] ?? '',
      vehicleType: json['vehicleType'] ?? 'standard',
      estimatedFare: (json['estimatedFare'] as num?)?.toDouble() ?? 0.0,
      finalFare: json['finalFare'] != null ? (json['finalFare'] as num).toDouble() : null,
      estimatedDistance: (json['estimatedDistance'] as num?)?.toDouble() ?? 0.0,
      actualDistance: json['actualDistance'] != null ? (json['actualDistance'] as num).toDouble() : null,
      estimatedDuration: (json['estimatedDuration'] as num?)?.toInt() ?? 0,
      actualDuration: json['actualDuration'] != null ? (json['actualDuration'] as num).toInt() : null,
      requestedAt: _parseDateTime(json['requestedAt']),
      acceptedAt: json['acceptedAt'] != null ? _parseDateTime(json['acceptedAt']) : null,
      arrivedAt: json['arrivedAt'] != null ? _parseDateTime(json['arrivedAt']) : null,
      startedAt: json['startedAt'] != null ? _parseDateTime(json['startedAt']) : null,
      completedAt: json['completedAt'] != null ? _parseDateTime(json['completedAt']) : null,
      cancelledAt: json['cancelledAt'] != null ? _parseDateTime(json['cancelledAt']) : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'driverId': driverId,
      'status': status,
      'originLat': originLat,
      'originLng': originLng,
      'originAddress': originAddress,
      'destLat': destLat,
      'destLng': destLng,
      'destAddress': destAddress,
      'vehicleType': vehicleType,
      'estimatedFare': estimatedFare,
      'finalFare': finalFare,
      'estimatedDistance': estimatedDistance,
      'actualDistance': actualDistance,
      'estimatedDuration': estimatedDuration,
      'actualDuration': actualDuration,
      'requestedAt': requestedAt.toIso8601String(),
      'acceptedAt': acceptedAt?.toIso8601String(),
      'arrivedAt': arrivedAt?.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
    };
  }
  
  @override
  List<Object?> get props => [
    id,
    userId,
    driverId,
    status,
    originLat,
    originLng,
    originAddress,
    destLat,
    destLng,
    destAddress,
    vehicleType,
    estimatedFare,
    finalFare,
    estimatedDistance,
    actualDistance,
    estimatedDuration,
    actualDuration,
    requestedAt,
    acceptedAt,
    arrivedAt,
    startedAt,
    completedAt,
    cancelledAt,
  ];
}