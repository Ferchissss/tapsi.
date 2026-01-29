import 'package:equatable/equatable.dart';

class SavedLocationModel extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final bool isDefault;
  final DateTime createdAt;

  const SavedLocationModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.isDefault = false,
    required this.createdAt,
  });

  factory SavedLocationModel.fromJson(Map<String, dynamic> json) {
    return SavedLocationModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'address': address,
      'lat': lat,
      'lng': lng,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        address,
        lat,
        lng,
        isDefault,
        createdAt,
      ];
}