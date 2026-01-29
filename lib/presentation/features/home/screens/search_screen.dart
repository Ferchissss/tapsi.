import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:latlong2/latlong.dart';
import 'package:tapsi/core/constants/colors.dart';
import 'package:tapsi/core/constants/text_styles.dart';
import 'package:tapsi/core/services/location_service.dart';
import 'package:tapsi/data/models/location_model.dart';
import 'package:tapsi/presentation/features/home/cubit/home_cubit.dart';
import 'package:tapsi/presentation/widgets/common/empty_state.dart';
import 'package:provider/provider.dart';
import 'package:tapsi/core/services/offline_service.dart';

class SearchScreen extends StatefulWidget {
  final String? selectionType; // 'origin' o 'destination'
  
  const SearchScreen({
    super.key,
    this.selectionType,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;
  List<LocationModel> _searchResults = [];
  bool _isSearching = false;
  bool _showRecentSearches = true;
  List<String> _recentSearches = [];
  
  late OfflineService _offlineService;
  late LocationService _locationService;
  double _currentLat = LocationService.tarijaLatitude;
  double _currentLng = LocationService.tarijaLongitude;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.requestFocus();
    
    _offlineService = Provider.of<OfflineService>(context, listen: false);
    _locationService = LocationService();
    
    // Cargar búsquedas recientes
    _loadRecentSearches();
    
    // Obtener ubicación actual para ordenar por cercanía
    _getCurrentLocation();
    
    // Establecer hint según el tipo de selección
    if (widget.selectionType != null) {
      _searchController.text = '';
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentPosition();
      setState(() {
        _currentLat = position.latitude;
        _currentLng = position.longitude;
      });
    } catch (e) {
      print('Error obteniendo ubicación actual: $e');
      // Usar Tarija como fallback
    }
  }

  void _loadRecentSearches() {
    // TODO: Cargar búsquedas recientes desde storage
    _recentSearches = [
      'Plaza Principal Tarija',
      'Mercado Central',
      'Aeropuerto Tarija',
      'Terminal de Buses',
      'Hospital San Juan de Dios',
    ];
  }

  void _saveRecentSearch(String query) {
    if (query.trim().isEmpty) return;
    
    setState(() {
      _recentSearches.remove(query);
      _recentSearches.insert(0, query);
      // Mantener solo las últimas 10 búsquedas
      if (_recentSearches.length > 10) {
        _recentSearches = _recentSearches.sublist(0, 10);
      }
    });
    
    // TODO: Guardar en storage
  }

  void _onSearchChanged() {
    if (_debounceTimer != null) {
      _debounceTimer!.cancel();
    }
    
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final query = _searchController.text.trim();
      
      if (query.isEmpty) {
        setState(() {
          _isSearching = false;
          _showRecentSearches = true;
          _searchResults.clear();
        });
        return;
      }
      
      setState(() {
        _isSearching = true;
        _showRecentSearches = false;
      });
      
      try {
        // 1. PRIMERO: Buscar en lugares populares de Tarija
        final tarijaSuggestions = _locationService.getTarijaSuggestions(query);
        
        if (tarijaSuggestions.isNotEmpty) {
          final results = tarijaSuggestions.map((place) {
            return LocationModel(
              latitude: place['latitude'],
              longitude: place['longitude'],
              address: place['address'],
              name: place['name'],
              placeId: 'tarija_${place['name'].hashCode}',
            );
          }).toList();
          
          // Ordenar por distancia a la ubicación actual
          _sortResultsByDistance(results);
          
          setState(() {
            _searchResults = results;
            _isSearching = false;
          });
          return;
        }
        
        // 2. SEGUNDO: Buscar usando geocoding con "Tarija, Bolivia"
        final locations = await _locationService.searchAddressInTarija(query);
        
        if (locations.isNotEmpty) {
          final results = await Future.wait(
            locations.map((location) async {
              try {
                // Obtener dirección completa
                final placemarks = await geo.placemarkFromCoordinates(
                  location.latitude,
                  location.longitude,
                );
                
                String address = query;
                if (placemarks.isNotEmpty) {
                  address = _locationService.buildAddressString(placemarks.first);
                }
                
                // Verificar si está en Tarija (aproximadamente)
                final distanceFromTarija = _locationService.calculateDistanceKm(
                  location.latitude,
                  location.longitude,
                  LocationService.tarijaLatitude,
                  LocationService.tarijaLongitude,
                );
                
                // Si está muy lejos de Tarija (> 200km), probablemente no es de Tarija
                if (distanceFromTarija > 200) {
                  return null;
                }
                
                return LocationModel(
                  latitude: location.latitude,
                  longitude: location.longitude,
                  address: address,
                  name: _getLocationNameFromAddress(address),
                  placeId: 'geo_${location.hashCode}',
                );
              } catch (e) {
                print('Error procesando ubicación: $e');
                return null;
              }
            }),
          );
          
          // Filtrar nulos
          final validResults = results.where((result) => result != null).cast<LocationModel>().toList();
          
          // Ordenar por distancia
          _sortResultsByDistance(validResults);
          
          setState(() {
            _searchResults = validResults;
            _isSearching = false;
          });
          return;
        }
        
        // 3. SI NO HAY RESULTADOS: Mostrar mensaje
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
        
      } catch (e) {
        print('❌ Error en búsqueda: $e');
        setState(() {
          _isSearching = false;
          _searchResults = [];
        });
      }
    });
  }

  // NUEVO: Ordenar resultados por distancia
  void _sortResultsByDistance(List<LocationModel> results) {
    results.sort((a, b) {
      final distA = _locationService.calculateDistanceKm(
        _currentLat, _currentLng,
        a.latitude, a.longitude,
      );
      final distB = _locationService.calculateDistanceKm(
        _currentLat, _currentLng,
        b.latitude, b.longitude,
      );
      return distA.compareTo(distB);
    });
  }

  String _getLocationNameFromAddress(String address) {
    // Extraer nombre del lugar de la dirección
    final parts = address.split(',');
    if (parts.isNotEmpty) {
      return parts.first.trim();
    }
    return 'Ubicación en Tarija';
  }

  Future<List<LocationModel>?> _getCachedSearch(String query) async {
    try {
      final cacheKey = 'search_cache_${query.toLowerCase().hashCode}';
      // TODO: Implementar obtención de caché desde storage
      return null;
    } catch (e) {
      print('Error obteniendo de caché: $e');
      return null;
    }
  }

  Future<void> _saveSearchToCache(String query, List<LocationModel> results) async {
    try {
      final cacheData = {
        'query': query,
        'results': results.map((location) => location.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await _offlineService.addToOfflineQueue(
        method: 'CACHE',
        path: 'search_cache',
        data: cacheData,
        requestId: 'search_${query.hashCode}',
      );
      
      print('💾 Búsqueda guardada en caché: $query (${results.length} resultados)');
    } catch (e) {
      print('❌ Error guardando búsqueda en caché: $e');
    }
  }

  void _selectLocation(LocationModel location) {
    final homeCubit = context.read<HomeCubit>();
    
    // Guardar como búsqueda reciente
    _saveRecentSearch(location.name ?? location.address ?? '');
    
    if (widget.selectionType == 'origin') {
      homeCubit.setOrigin(location);
    } else if (widget.selectionType == 'destination') {
      homeCubit.setDestination(location);
    } else {
      // Comportamiento anterior (para compatibilidad)
      homeCubit.selectLocation(location);
    }
    
    Navigator.pop(context);
  }

  void _useCurrentLocation() {
    final homeState = context.read<HomeCubit>().state;
    if (homeState is HomeLoaded) {
      final location = homeState.currentLocation;
      _selectLocation(location);
    }
  }

  void _selectRecentSearch(String search) {
    setState(() {
      _searchController.text = search;
      _showRecentSearches = false;
    });
    _onSearchChanged();
  }

  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Lugares frecuentes en Tarija',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        ..._recentSearches.map((search) => ListTile(
          leading: const Icon(Icons.location_on),
          title: Text(search),
          onTap: () => _selectRecentSearch(search),
        )).toList(),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Buscando en Tarija...',
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ],
      );
    }
    
    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return EmptyState(
        title: 'No se encontraron lugares',
        description: 'Intenta con otro nombre o dirección en Tarija',
        icon: Icons.location_searching,
        onAction: () {
          _searchController.clear();
          setState(() {
            _showRecentSearches = true;
          });
        },
        actionText: 'Ver lugares frecuentes',
      );
    }
    
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final location = _searchResults[index];
        final distance = _locationService.calculateDistanceKm(
          _currentLat, _currentLng,
          location.latitude, location.longitude,
        );
        
        return ListTile(
          leading: const Icon(Icons.place, color: AppColors.primary),
          title: Text(location.name ?? 'Ubicación'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                location.address ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${distance.toStringAsFixed(1)} km de distancia',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          onTap: () => _selectLocation(location),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.selectionType == 'origin'
            ? 'Buscar origen en Tarija'
            : widget.selectionType == 'destination'
              ? 'Buscar destino en Tarija'
              : 'Buscar en Tarija',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Buscar lugares en Tarija...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _showRecentSearches = true;
                            _searchResults.clear();
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDark
                    ? AppColors.darkSurface
                    : AppColors.lightSurface,
              ),
              onChanged: (_) => _onSearchChanged(),
            ),
          ),
          
          // Sugerencia de búsqueda
          if (_searchController.text.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Ejemplos: "Plaza Principal", "Mercado", "Hospital", "Aeropuerto"',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ),
          
          // Lista de resultados o búsquedas recientes
          Expanded(
            child: _showRecentSearches
                ? ListView(
                    children: [
                      // Ubicación actual
                      ListTile(
                        leading: const Icon(Icons.my_location),
                        title: const Text('Usar mi ubicación actual'),
                        subtitle: BlocBuilder<HomeCubit, HomeState>(
                          builder: (context, state) {
                            if (state is HomeLoaded) {
                              return Text(
                                '${state.currentLocation.address ?? 'Tarija'}',
                                overflow: TextOverflow.ellipsis,
                              );
                            }
                            return const Text('Tarija, Bolivia');
                          },
                        ),
                        onTap: _useCurrentLocation,
                      ),
                      const Divider(),
                      _buildRecentSearches(),
                    ],
                  )
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }
}