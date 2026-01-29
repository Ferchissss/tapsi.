import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.photoUrl,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      photoUrl: json['photoUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static UserModel empty() {
    return UserModel(
      id: '',
      name: '',
      phone: '',
      createdAt: DateTime.now(),
    );
  }

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  @override
  List<Object?> get props => [
    id, 
    name, 
    phone, 
    email, 
    photoUrl, 
    createdAt, 
    updatedAt
  ];
}