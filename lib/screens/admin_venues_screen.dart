import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/zone_model.dart';
import '../models/venue_model.dart';
import '../widgets/custom_nav_bar.dart';
import 'edit_venue_screen.dart';

class AdminVenuesScreen extends StatefulWidget {
  @override
  _AdminVenuesScreenState createState() => _AdminVenuesScreenState();
}

class _AdminVenuesScreenState extends State<AdminVenuesScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _ownerIdController = TextEditingController();
  String? _selectedZoneId;
  File? _mainImage;
  List<File> _galleryImages = [];
  bool _isPremium = false;
  bool _isLoading = false;

  // Para manejar qué paneles están expandidos
  List<bool> _expandedPanels = [];

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final databaseService = Provider.of<DatabaseService>(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          CustomNavBar(
            title: 'Gestionar Locales',
            user: user,
            showBackButton: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Formulario para agregar venue
                  Card(
                    margin: EdgeInsets.all(16),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Agregar Nuevo Local',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFCC0000),
                            ),
                          ),
                          SizedBox(height: 16),

                          // Selector de zona
                          StreamBuilder<List<ZoneModel>>(
                            stream: databaseService.getZones(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return CircularProgressIndicator();
                              }
                              final zones = snapshot.data!;

                              // Verificar si la zona seleccionada aún existe
                              if (_selectedZoneId != null &&
                                  !zones.any((zone) => zone.id == _selectedZoneId)) {
                                _selectedZoneId = null;
                              }
                              return DropdownButtonFormField<String>(
                                value: _selectedZoneId,
                                decoration: InputDecoration(
                                  labelText: 'Zona',
                                  border: OutlineInputBorder(),
                                ),
                                items: [
                                  DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('Selecciona una zona'),
                                  ),
                                  ...zones.map((zone) {
                                    return DropdownMenuItem<String>(
                                      value: zone.id,
                                      child: Text(zone.name),
                                    );
                                  }).toList(),
                                ],
                                onChanged: (String? value) {
                                  setState(() {
                                    _selectedZoneId = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Por favor selecciona una zona';
                                  }
                                  return null;
                                },
                              );
                            },
                          ),
                          SizedBox(height: 16),

                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Nombre del local',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          SizedBox(height: 16),

                          TextField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              labelText: 'Descripción',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                          SizedBox(height: 16),

                          TextField(
                            controller: _locationController,
                            decoration: InputDecoration(
                              labelText: 'Ubicación',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          SizedBox(height: 16),

                          TextField(
                            controller: _ownerIdController,
                            decoration: InputDecoration(
                              labelText: 'ID del propietario',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          SizedBox(height: 16),

                          CheckboxListTile(
                            title: Text('Local Premium'),
                            value: _isPremium,
                            onChanged: (value) {
                              setState(() {
                                _isPremium = value ?? false;
                              });
                            },
                          ),
                          SizedBox(height: 16),

                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _pickMainImage,
                                icon: Icon(Icons.image),
                                label: Text('Imagen Principal'),
                              ),
                              SizedBox(width: 8),
                              if (_mainImage != null)
                                Text('✓', style: TextStyle(color: Colors.green)),
                            ],
                          ),
                          SizedBox(height: 8),

                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _pickGalleryImages,
                                icon: Icon(Icons.photo_library),
                                label: Text('Galería'),
                              ),
                              SizedBox(width: 8),
                              if (_galleryImages.isNotEmpty)
                                Text('${_galleryImages.length} imágenes',
                                    style: TextStyle(color: Colors.green)),
                            ],
                          ),
                          SizedBox(height: 16),

                          ElevatedButton(
                            onPressed: _isLoading ? null : _addVenue,
                            child: _isLoading
                                ? CircularProgressIndicator()
                                : Text('Agregar Local'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFCC0000),
                              foregroundColor: Colors.white,
                              minimumSize: Size(double.infinity, 50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Lista de zonas para ver venues - VERSIÓN CORREGIDA
                  Card(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Locales Existentes por Zona',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFCC0000),
                            ),
                          ),
                          SizedBox(height: 16),

                          StreamBuilder<List<ZoneModel>>(
                            stream: databaseService.getZones(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return Center(child: CircularProgressIndicator());
                              }

                              final zones = snapshot.data!;

                              return Column(
                                children: zones.map((zone) {
                                  return Card(
                                    margin: EdgeInsets.only(bottom: 16),
                                    elevation: 2,
                                    child: Column(
                                      children: [
                                        // Header de la zona
                                        Container(
                                          width: double.infinity,
                                          padding: EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Color(0xFFCC0000),
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(4),
                                              topRight: Radius.circular(4),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.location_city, color: Colors.white),
                                              SizedBox(width: 8),
                                              Text(
                                                zone.name,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Spacer(),
                                              Text(
                                                'ID: ${zone.id}',
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Contenido de venues
                                        StreamBuilder<List<VenueModel>>(
                                          stream: databaseService.getVenuesByZone(zone.id),
                                          builder: (context, venueSnapshot) {
                                            if (venueSnapshot.connectionState == ConnectionState.waiting) {
                                              return Padding(
                                                padding: EdgeInsets.all(20),
                                                child: CircularProgressIndicator(),
                                              );
                                            }

                                            if (venueSnapshot.hasError) {
                                              return Padding(
                                                padding: EdgeInsets.all(20),
                                                child: Text(
                                                  'Error: ${venueSnapshot.error}',
                                                  style: TextStyle(color: Colors.red),
                                                ),
                                              );
                                            }

                                            if (!venueSnapshot.hasData || venueSnapshot.data!.isEmpty) {
                                              return Padding(
                                                padding: EdgeInsets.all(20),
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.info_outline, color: Colors.grey),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'No hay locales en esta zona',
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontStyle: FontStyle.italic,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }

                                            final venues = venueSnapshot.data!;
                                            print('Renderizando ${venues.length} venues para zona ${zone.name}');

                                            return Padding(
                                              padding: EdgeInsets.all(8),
                                              child: Column(
                                                children: venues.map((venue) {
                                                  print('Renderizando venue: ${venue.name}');
                                                  return Container(
                                                    margin: EdgeInsets.only(bottom: 8),
                                                    padding: EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[50],
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(color: Colors.grey[300]!),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        // Icono del local
                                                        Container(
                                                          width: 40,
                                                          height: 40,
                                                          decoration: BoxDecoration(
                                                            color: venue.isPremium ? Colors.amber : Colors.blue,
                                                            shape: BoxShape.circle,
                                                          ),
                                                          child: Icon(
                                                            venue.isPremium ? Icons.star : Icons.store,
                                                            color: Colors.white,
                                                            size: 20,
                                                          ),
                                                        ),
                                                        SizedBox(width: 12),

                                                        // Información del local
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                venue.name,
                                                                style: TextStyle(
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 16,
                                                                ),
                                                              ),
                                                              if (venue.description.isNotEmpty)
                                                                Text(
                                                                  venue.description,
                                                                  style: TextStyle(
                                                                    color: Colors.grey[600],
                                                                    fontSize: 12,
                                                                  ),
                                                                  maxLines: 1,
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                              Text(
                                                                'Orden: ${venue.order} | Premium: ${venue.isPremium ? 'Sí' : 'No'}',
                                                                style: TextStyle(
                                                                  color: Colors.grey[500],
                                                                  fontSize: 11,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),

                                                        // Botones de acción
                                                        Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            // Botones de orden
                                                            Column(
                                                              children: [
                                                                Container(
                                                                  width: 32,
                                                                  height: 32,
                                                                  child: IconButton(
                                                                    padding: EdgeInsets.zero,
                                                                    icon: Icon(Icons.keyboard_arrow_up, size: 20),
                                                                    onPressed: venue.order > 1
                                                                        ? () => _changeVenueOrder(venue, venue.order - 1)
                                                                        : null,
                                                                    tooltip: 'Subir orden',
                                                                  ),
                                                                ),
                                                                Container(
                                                                  width: 32,
                                                                  height: 32,
                                                                  child: IconButton(
                                                                    padding: EdgeInsets.zero,
                                                                    icon: Icon(Icons.keyboard_arrow_down, size: 20),
                                                                    onPressed: () => _changeVenueOrder(venue, venue.order + 1),
                                                                    tooltip: 'Bajar orden',
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            SizedBox(width: 8),

                                                            // Botones principales
                                                            IconButton(
                                                              icon: Icon(Icons.edit, color: Colors.blue),
                                                              onPressed: () {
                                                                print('Editando venue: ${venue.name}');
                                                                Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                    builder: (context) => EditVenueScreen(venue: venue),
                                                                  ),
                                                                );
                                                              },
                                                              tooltip: 'Editar',
                                                            ),
                                                            IconButton(
                                                              icon: Icon(Icons.delete, color: Colors.red),
                                                              onPressed: () {
                                                                print('Eliminando venue: ${venue.name}');
                                                                _deleteVenue(venue.id);
                                                              },
                                                              tooltip: 'Eliminar',
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickMainImage() async {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    final image = await databaseService.pickImage();
    setState(() {
      _mainImage = image;
    });
  }

  Future<void> _pickGalleryImages() async {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    final images = await databaseService.pickMultipleImages();
    setState(() {
      _galleryImages = images;
    });
  }

  Future<void> _addVenue() async {
    if (_selectedZoneId == null || _nameController.text.isEmpty || _ownerIdController.text.isEmpty) {
      _showSnackBar('Por favor completa todos los campos requeridos');
      return;
    }

    setState(() => _isLoading = true);

    final venue = VenueModel(
      id: '',
      name: _nameController.text,
      zoneId: _selectedZoneId!,
      description: _descriptionController.text,
      mainImageUrl: '',
      galleryImages: [],
      location: _locationController.text,
      socialMedia: {},
      isPremium: _isPremium,
      order: 0,
      createdAt: DateTime.now(),
      ownerId: _ownerIdController.text,
    );

    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    final success = await databaseService.addVenue(venue, _mainImage, _galleryImages);

    setState(() => _isLoading = false);

    if (success) {
      _clearForm();
      _showSnackBar('Local agregado exitosamente');
    } else {
      _showSnackBar('Error al agregar el local');
    }
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _locationController.clear();
    _ownerIdController.clear();
    setState(() {
      _selectedZoneId = null;
      _mainImage = null;
      _galleryImages = [];
      _isPremium = false;
    });
  }

  Future<void> _deleteVenue(String venueId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar este local?\n\nEsta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      final success = await databaseService.deleteVenue(venueId);
      _showSnackBar(success ? 'Local eliminado exitosamente' : 'Error al eliminar el local');
    }
  }

  Future<void> _changeVenueOrder(VenueModel venue, int newOrder) async {
    print('Cambiando orden de ${venue.name} de ${venue.order} a $newOrder');

    final databaseService = Provider.of<DatabaseService>(context, listen: false);

    // Obtener todos los venues de la misma zona
    final venuesStream = databaseService.getVenuesByZone(venue.zoneId);
    final allVenuesInZone = await venuesStream.first;

    // Verificar que el nuevo orden sea válido
    if (newOrder < 1) {
      _showSnackBar('No se puede subir más');
      return;
    }

    // Encontrar si hay un venue con el orden destino
    final venueWithTargetOrder = allVenuesInZone.where((v) => v.order == newOrder && v.id != venue.id).isNotEmpty
        ? allVenuesInZone.firstWhere((v) => v.order == newOrder && v.id != venue.id)
        : null;

    try {
      if (venueWithTargetOrder != null) {
        // Hay un venue en esa posición, intercambiar órdenes
        await databaseService.updateVenueOrder(venueWithTargetOrder.id, venue.order);
        await databaseService.updateVenueOrder(venue.id, newOrder);
        _showSnackBar('Orden cambiado exitosamente');
      } else {
        // No hay venue en esa posición, solo cambiar el orden
        await databaseService.updateVenueOrder(venue.id, newOrder);
        _showSnackBar('Orden cambiado exitosamente');
      }
    } catch (e) {
      print('Error al cambiar orden: $e');
      _showSnackBar('Error al cambiar el orden');
    }
  }


  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}