import 'package:flutter/material.dart';
import 'package:tapsi/core/constants/colors.dart';
import 'package:tapsi/core/constants/text_styles.dart';
import 'package:tapsi/presentation/widgets/common/empty_state.dart';

class SavedLocationsScreen extends StatefulWidget {
  const SavedLocationsScreen({super.key});

  @override
  State<SavedLocationsScreen> createState() => _SavedLocationsScreenState();
}

class _SavedLocationsScreenState extends State<SavedLocationsScreen> {
  // TODO: Conectar con backend cuando esté listo
  final List<Map<String, dynamic>> _savedLocations = [
    {
      'id': '1',
      'name': 'Casa',
      'address': 'Av. Principal #123, Tarija',
      'icon': Icons.home,
      'isDefault': true,
    },
    {
      'id': '2',
      'name': 'Trabajo',
      'address': 'Calle Comercio #456, Tarija',
      'icon': Icons.work,
      'isDefault': false,
    },
  ];

  void _addLocation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar dirección'),
        content: const Text('Funcionalidad en desarrollo'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CERRAR'),
          ),
        ],
      ),
    );
  }

  void _editLocation(Map<String, dynamic> location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar dirección'),
        content: Text('Editar: ${location['name']}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implementar edición
            },
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    );
  }

  void _deleteLocation(Map<String, dynamic> location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar dirección'),
        content: Text('¿Eliminar "${location['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _savedLocations.removeWhere((l) => l['id'] == location['id']);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Dirección eliminada'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: Text(
              'ELIMINAR',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Direcciones Guardadas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _savedLocations.isEmpty
          ? EmptyState(
              title: 'Sin direcciones guardadas',
              description: 'Agrega tus lugares favoritos para acceder rápidamente',
              icon: Icons.location_off,
              onAction: _addLocation,
              actionText: 'Agregar dirección',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _savedLocations.length,
              itemBuilder: (context, index) {
                final location = _savedLocations[index];
                return _buildLocationCard(location, isDark);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addLocation,
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildLocationCard(Map<String, dynamic> location, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            location['icon'] as IconData,
            color: AppColors.primary,
          ),
        ),
        title: Row(
          children: [
            Text(
              location['name'] as String,
              style: AppTextStyles.bodyBold,
            ),
            if (location['isDefault'] == true) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Principal',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            location['address'] as String,
            style: AppTextStyles.body.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'edit') {
              _editLocation(location);
            } else if (value == 'delete') {
              _deleteLocation(location);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 12),
                  Text('Editar'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: AppColors.error),
                  const SizedBox(width: 12),
                  Text('Eliminar', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}