import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapsi/core/constants/colors.dart';
import 'package:tapsi/core/constants/text_styles.dart';
import 'package:tapsi/data/models/saved_location_model.dart';
import 'package:tapsi/presentation/widgets/common/empty_state.dart';
import 'package:tapsi/presentation/widgets/custom/map_selection_widget.dart';

class SavedLocationsScreen extends StatefulWidget {
  const SavedLocationsScreen({super.key});

  @override
  State<SavedLocationsScreen> createState() => _SavedLocationsScreenState();
}

class _SavedLocationsScreenState extends State<SavedLocationsScreen> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  late String _userId;
  
  // Variables para mantener el estado del formulario
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  String _selectedIcon = 'home';
  double? _selectedLat;
  double? _selectedLng;

  @override
  void initState() {
    super.initState();
    _userId = _auth.currentUser?.uid ?? '';
    _nameController = TextEditingController();
    _addressController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _addLocation() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Agregar dirección'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre (ej: Casa, Trabajo)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Botón para seleccionar ubicación en el mapa
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _openMapToSelectLocation((lat, lng, address) {
                    setState(() {
                      _addressController.text = address;
                      _selectedLat = lat;
                      _selectedLng = lng;
                    });
                    // Volver a abrir el diálogo
                    _addLocation();
                  });
                },
                icon: const Icon(Icons.location_on),
                label: const Text('Seleccionar en mapa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Dirección',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: 'Se completará al seleccionar en el mapa',
                ),
                maxLines: 2,
                readOnly: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedIcon,
                decoration: InputDecoration(
                  labelText: 'Tipo de lugar',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'home', child: Text('Casa')),
                  DropdownMenuItem(value: 'work', child: Text('Trabajo')),
                  DropdownMenuItem(value: 'favorite', child: Text('Favorito')),
                  DropdownMenuItem(value: 'other', child: Text('Otro')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedIcon = value ?? 'home';
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () {
              if (_nameController.text.isEmpty || _addressController.text.isEmpty) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Completa todos los campos')),
                );
                return;
              }
              _saveLocation(
                _nameController.text,
                _addressController.text,
                _selectedIcon,
                _selectedLat ?? 0.0,
                _selectedLng ?? 0.0,
              );
              Navigator.pop(dialogContext);
              // Limpiar los campos después de guardar
              _nameController.clear();
              _addressController.clear();
              _selectedIcon = 'home';
              _selectedLat = null;
              _selectedLng = null;
            },
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    );
  }

  void _openMapToSelectLocation(Function(double lat, double lng, String address) onLocationSelected) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Seleccionar ubicación'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: MapSelectionWidget(
            onLocationSelected: (lat, lng, address) {
              Navigator.pop(context);
              onLocationSelected(lat, lng, address);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _saveLocation(
    String name,
    String address,
    String icon,
    double lat,
    double lng,
  ) async {
    try {
      final docId = _db.collection('users').doc(_userId).collection('savedLocations').doc().id;
      final location = SavedLocationModel(
        id: docId,
        userId: _userId,
        name: name,
        address: address,
        lat: lat,
        lng: lng,
        isDefault: false,
        createdAt: DateTime.now(),
      );

      await _db
          .collection('users')
          .doc(_userId)
          .collection('savedLocations')
          .doc(docId)
          .set(location.toJson());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dirección guardada'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _editLocation(SavedLocationModel location) {
    final nameController = TextEditingController(text: location.name);
    final addressController = TextEditingController(text: location.address);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar dirección'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: 'Dirección',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () {
              _updateLocation(
                location.id,
                nameController.text,
                addressController.text,
              );
              Navigator.pop(context);
            },
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateLocation(String id, String name, String address) async {
    try {
      await _db
          .collection('users')
          .doc(_userId)
          .collection('savedLocations')
          .doc(id)
          .update({
        'name': name,
        'address': address,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dirección actualizada'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _deleteLocation(SavedLocationModel location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar dirección'),
        content: Text('¿Eliminar "${location.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () {
              _performDelete(location.id);
              Navigator.pop(context);
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

  Future<void> _performDelete(String id) async {
    try {
      await _db
          .collection('users')
          .doc(_userId)
          .collection('savedLocations')
          .doc(id)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dirección eliminada'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  IconData _getIconFromName(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'home':
        return Icons.home;
      case 'work':
        return Icons.work;
      case 'favorite':
        return Icons.favorite;
      default:
        return Icons.location_on;
    }
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
      body: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('users')
            .doc(_userId)
            .collection('savedLocations')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final locations = snapshot.data?.docs ?? [];

          if (locations.isEmpty) {
            return EmptyState(
              title: 'Sin direcciones guardadas',
              description: 'Agrega tus lugares favoritos para acceder rápidamente',
              icon: Icons.location_off,
              onAction: _addLocation,
              actionText: 'Agregar dirección',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: locations.length,
            itemBuilder: (context, index) {
              final location = SavedLocationModel.fromJson(
                locations[index].data() as Map<String, dynamic>,
              );
              return _buildLocationCard(location, isDark);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addLocation,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildLocationCard(SavedLocationModel location, bool isDark) {
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
            _getIconFromName(location.id),
            color: AppColors.primary,
          ),
        ),
        title: Row(
          children: [
            Text(
              location.name,
              style: AppTextStyles.bodyBold,
            ),
            if (location.isDefault) ...[
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
            location.address,
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
