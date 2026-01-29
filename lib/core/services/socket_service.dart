/// SocketService (legacy)
///
/// El proyecto original dependía de Socket.IO para eventos en tiempo real.
/// Como ahora el backend será Firebase (free tier), este servicio se mantiene
/// para no romper inyección/llamadas existentes, pero por defecto es un NO-OP.
///
/// Si más adelante quieres “tiempo real” (asignación de conductor, chat, etc),
/// se reemplaza por listeners de Firestore sin tocar pantallas.
class SocketService {
  SocketService(dynamic _storageService);

  Future<void> connect() async {
    // NO-OP (Firebase reemplaza sockets)
  }

  void joinTrip(String tripId) {
    // NO-OP
  }

  void updateUserLocation({
    required String tripId,
    required double lat,
    required double lng,
    double? accuracy,
  }) {
    // NO-OP
  }

  void sendMessage({
    required String tripId,
    required String content,
  }) {
    // NO-OP
  }

  void onNewMessage(Function(Map<String, dynamic>) callback) {
    // NO-OP
  }

  void onDriverLocation(Function(Map<String, dynamic>) callback) {
    // NO-OP
  }

  void onTripAccepted(Function(Map<String, dynamic>) callback) {
    // NO-OP
  }

  void disconnect() {
    // NO-OP
  }
}