import 'package:flutter/foundation.dart';
part of 'auth_cubit.dart';

@immutable
abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthUnauthenticated extends AuthState {}

class VerificationCodeSent extends AuthState {
  final String phone;
  
  const VerificationCodeSent({required this.phone});
}

class ProfileSetupRequired extends AuthState {
  final String phone;
  final String? verificationId;
  
  const ProfileSetupRequired({
    required this.phone,
    this.verificationId,
  });
}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  
  const AuthAuthenticated({required this.user});
}

class AuthError extends AuthState {
  final String message;
  
  const AuthError({required this.message});
}