// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:tapsi/app.dart';
import 'package:tapsi/core/services/api_service.dart';
import 'package:tapsi/core/services/storage_service.dart';
import 'package:tapsi/core/services/socket_service.dart';
import 'package:tapsi/core/services/cache_service.dart';
import 'package:tapsi/core/services/offline_service.dart';
import 'package:tapsi/core/providers/app_provider.dart';
import 'package:tapsi/core/theme/theme_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");
  
  // Configuración de orientación
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Status bar transparente
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  
  // Inicializar servicios
  final storageService = StorageService();
  await storageService.init();
  
  runApp(
    MultiProvider(
      providers: [
        // Servicios
        Provider<StorageService>(
          create: (_) => storageService,
        ),
        Provider<ApiService>(
          create: (context) => ApiService(context.read<StorageService>()),
        ),
        Provider<SocketService>(
          create: (context) => SocketService(context.read<StorageService>()),
        ),
        Provider<CacheService>(
          create: (context) => CacheService(context.read<StorageService>()),
        ),
        Provider<OfflineService>(
          create: (context) => OfflineService(
            apiService: context.read<ApiService>(),
            storageService: context.read<StorageService>(),
          ),
        ),
        
        // Proveedores de estado
        ChangeNotifierProvider<ThemeManager>(
          create: (context) => ThemeManager(context.read<StorageService>()),
        ),
        ChangeNotifierProvider<AppProvider>(
          create: (context) => AppProvider(
            storageService: context.read<StorageService>(),
            apiService: context.read<ApiService>(),
            socketService: context.read<SocketService>(),
            offlineService: context.read<OfflineService>(),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return MaterialApp(
          title: 'Tapsi',
          debugShowCheckedModeBanner: false,
          theme: themeManager.getCurrentTheme(context),
          home: const App(),
        );
      },
    );
  }
}