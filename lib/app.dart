import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'package:tapsi/presentation/widgets/common/connection_indicator.dart';
import 'package:tapsi/core/constants/app_routes.dart';
import 'package:tapsi/core/constants/colors.dart';
import 'package:tapsi/core/services/api_service.dart';
import 'package:tapsi/core/services/storage_service.dart';
import 'package:tapsi/core/services/location_service.dart';
import 'package:tapsi/core/services/offline_service.dart';
import 'package:tapsi/core/theme/theme_manager.dart';

import 'package:tapsi/presentation/features/auth/cubit/auth_cubit.dart';
import 'package:tapsi/presentation/features/home/cubit/home_cubit.dart';
import 'package:tapsi/presentation/features/auth/screens/login_screen.dart';
import 'package:tapsi/presentation/features/auth/screens/otp_screen.dart';
import 'package:tapsi/presentation/features/auth/screens/profile_setup_screen.dart';
import 'package:tapsi/presentation/features/home/screens/home_screen.dart';
import 'package:tapsi/presentation/features/home/screens/search_screen.dart';
import 'package:tapsi/presentation/widgets/common/loading_indicator.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final storageService = Provider.of<StorageService>(context);
    final apiService = Provider.of<ApiService>(context);
    final themeManager = Provider.of<ThemeManager>(context);
    
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: storageService),
        RepositoryProvider.value(value: apiService),
        RepositoryProvider(create: (_) => LocationService()),
        RepositoryProvider(create: (context) => OfflineService(
          apiService: context.read<ApiService>(),
          storageService: context.read<StorageService>(),
        )),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthCubit(
              storageService: storageService,
              apiService: apiService,
            ),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: themeManager.getCurrentTheme(context),
          home: const AppContent(),
          routes: {
            AppRoutes.login: (context) => const LoginScreen(),
            AppRoutes.otp: (context) {
              final args = ModalRoute.of(context)!.settings.arguments as Map?;
              return OTPScreen(phoneNumber: args?['phone'] ?? '');
            },
            AppRoutes.home: (context) => BlocProvider(
                  create: (context) => HomeCubit(
                    locationService: context.read<LocationService>(),
                    offlineService: context.read<OfflineService>(),
                  ),
                  child: const HomeScreen(),
                ),
            AppRoutes.search: (context) => const SearchScreen(),
          },
        ),
      ),
    );
  }
}

class AppContent extends StatelessWidget {
  const AppContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          child: BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              if (state is AuthLoading || state is AuthInitial) {
                return const SplashScreen();
              } else if (state is AuthAuthenticated) {
                return BlocProvider(
                  create: (context) => HomeCubit(
                    locationService: context.read<LocationService>(),
                  ),
                  child: const HomeScreen(),
                );
              } else if (state is AuthUnauthenticated) {
                return const LoginScreen();
              } else if (state is VerificationCodeSent) {
                return OTPScreen(phoneNumber: state.phone);
              } else if (state is ProfileSetupRequired) {
                return ProfileSetupScreen(phone: state.phone);
              } else if (state is AuthError) {
                return const LoginScreen();
              } else {
                return const Scaffold(
                  body: LoadingIndicator(),
                );
              }
            },
          ),
        ),

        // Banner de conexión
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ConnectionBanner(),
        ),
      ],
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode 
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/images/logo.jfif',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Tapsi',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isDarkMode 
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tu viaje, seguro y rápido',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode 
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}