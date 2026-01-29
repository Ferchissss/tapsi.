import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapsi/core/constants/colors.dart';
import 'package:tapsi/core/constants/text_styles.dart';
import 'package:tapsi/core/providers/app_provider.dart';
import 'package:tapsi/presentation/features/profile/screens/profile_screen.dart';
import 'package:tapsi/presentation/features/profile/screens/saved_locations_screen.dart';
import 'package:tapsi/presentation/features/trip/screens/trip_history_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appProvider = Provider.of<AppProvider>(context);
    final user = appProvider.currentUser;

    return Drawer(
      child: Container(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        child: SafeArea(
          child: Column(
            children: [
              // Header del drawer
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                      ),
                      child: user?.photoUrl != null
                          ? ClipOval(
                              child: Image.network(
                                user!.photoUrl!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: 35,
                              color: AppColors.primary,
                            ),
                    ),
                    const SizedBox(height: 16),
                    // Nombre
                    Text(
                      user?.name ?? 'Usuario',
                      style: AppTextStyles.h3.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Teléfono
                    Text(
                      user?.phone ?? '',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              // Opciones del menú
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.history,
                      title: 'Mis viajes',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TripHistoryScreen(),
                          ),
                        );
                      },
                      isDark: isDark,
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.location_on,
                      title: 'Direcciones guardadas',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SavedLocationsScreen(),
                          ),
                        );
                      },
                      isDark: isDark,
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.person,
                      title: 'Perfil',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                      },
                      isDark: isDark,
                    ),
                    const Divider(),
                    _buildMenuItem(
                      context,
                      icon: Icons.help_outline,
                      title: 'Soporte',
                      onTap: () {
                        Navigator.pop(context);
                        _showSupport(context);
                      },
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              // Cerrar sesión
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmLogout(context),
                    icon: Icon(
                      Icons.logout,
                      color: AppColors.error,
                    ),
                    label: Text(
                      'Cerrar sesión',
                      style: TextStyle(color: AppColors.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppColors.primary,
      ),
      title: Text(
        title,
        style: AppTextStyles.body.copyWith(
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _logout(context);
            },
            child: Text(
              'CERRAR SESIÓN',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    await appProvider.logout();
    // Navegar al login
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  void _showSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Soporte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Necesitas ayuda?'),
            const SizedBox(height: 16),
            const Text('Contáctanos:'),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.email, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text('soporte@tapsi.app'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text('+591 XXX XXX XXX'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CERRAR'),
          ),
        ],
      ),
    );
  }
}