class AppRoutes {
  // Rutas principales
  static const String splash = '/';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String home = '/home';
  static const String search = '/search';
  
  // Métodos helper para navegación
  static Map<String, String> otpArguments(String phone) => {'phone': phone};
}