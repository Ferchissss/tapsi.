class ApiConstants {
  // Base URL (cambiar según tu entorno)
  static const String baseUrl = 'http://192.168.100.112:3000';
  // Para Android emulador: 'http://10.0.2.2:3000'
  // Para iOS simulator: 'http://localhost:3000'
  // Para dispositivo físico: 'http://TU_IP_LOCAL:3000'

  // Socket.IO
  static const String socketUrl = 'ws://10.0.2.2:3000';
  
  // Auth Endpoints
  static const String sendCode = '/api/v1/auth/send-code';
  static const String verifyCode = '/api/v1/auth/verify-code';
  static const String completeProfile = '/api/v1/auth/complete-profile';
  static const String verifyToken = '/api/v1/auth/verify';
  
  // User Endpoints
  static const String userProfile = '/api/v1/users/me';
  static const String updateProfile = '/api/v1/users/me';
  
  // Trip Endpoints
  static const String createTrip = '/api/v1/trips';
  static const String tripDetail = '/api/v1/trips'; // + /{id}
  static const String tripHistory = '/api/v1/trips/history';
  static const String cancelTrip = '/api/v1/trips'; // + /{id}/cancel
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}