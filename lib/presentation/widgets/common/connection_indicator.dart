// lib/presentation/widgets/common/connection_indicator.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapsi/core/providers/app_provider.dart';

class ConnectionIndicator extends StatelessWidget {
  final double size;
  
  const ConnectionIndicator({
    super.key,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context, listen: true);
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: appProvider.isConnected
          ? Container(
              key: const ValueKey('connected'),
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi,
                color: Colors.white,
                size: size * 0.6,
              ),
            )
          : Container(
              key: const ValueKey('disconnected'),
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off,
                color: Colors.white,
                size: size * 0.6,
              ),
            ),
    );
  }
}

class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context, listen: true);
    
    if (appProvider.isConnected) {
      return const SizedBox.shrink();
    }
    
    return Material(
      color: Colors.orange,
      elevation: 4,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.wifi_off, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Modo offline - Algunas funciones pueden estar limitadas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.info, color: Colors.white, size: 16),
                onPressed: () {
                  _showOfflineInfo(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOfflineInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modo Offline'),
        content: const Text(
          'Estás trabajando sin conexión a internet:\n\n'
          '• Puedes ver tu historial reciente\n'
          '• Las direcciones guardadas están disponibles\n'
          '• Los viajes se guardarán y enviarán cuando tengas conexión\n'
          '• El mapa muestra datos cacheados',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ENTENDIDO'),
          ),
        ],
      ),
    );
  }
}