import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'dart:typed_data';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/image_loader_service.dart';
import '../models/venue_model.dart';
import '../models/zone_model.dart';
import '../widgets/custom_nav_bar.dart';
import '../widgets/universal_image_widget.dart';

class EditVenueScreen extends StatefulWidget {
  final VenueModel venue;

  const EditVenueScreen({Key? key, required this.venue}) : super(key: key);

  @override
  _EditVenueScreenState createState() => _EditVenueScreenState();
}

class _EditVenueScreenState extends State<EditVenueScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _ownerIdController = TextEditingController();
  String? _selectedZoneId;
  File? _mainImage;
  List<File> _galleryImages = [];
  bool _isPremium = false;
  bool _isLoading = false;

  // Widget para imagen principal
  Widget _buildMainImageWidget(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Center(child: Text('Sin imagen'));
    }

    if (kIsWeb) {
      return FutureBuilder<Uint8List?>(
        future: ImageLoaderService.loadImageBytes(imageUrl),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData && snapshot.data != null) {
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.image_not_supported);
              },
            );
          } else {
            return Icon(Icons.image_not_supported);
          }
        },
      );
    } else {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) => Icon(Icons.image_not_supported),
      );
    }
  }

  // Widget para galería
  Widget _buildGalleryImageWidget(String imageUrl) {
    if (kIsWeb) {
      return FutureBuilder<Uint8List?>(
        future: ImageLoaderService.loadImageBytes(imageUrl),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData && snapshot.data != null) {
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.image_not_supported);
              },
            );
          } else {
            return Icon(Icons.image_not_supported);
          }
        },
      );
    } else {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) => Icon(Icons.image_not_supported),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadVenueData();
  }

  void _loadVenueData() {
    _nameController.text = widget.venue.name;
    _descriptionController.text = widget.venue.description;
    _locationController.text = widget.venue.location;
    _ownerIdController.text = widget.venue.ownerId;
    _selectedZoneId = widget.venue.zoneId;
    _isPremium = widget.venue.isPremium;
  }

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
            title: 'Editar Local',
            user: user,
            showBackButton: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Información del Local',
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

                              if (_selectedZoneId != null && !zones.any((zone) => zone.id == _selectedZoneId)) {
                                _selectedZoneId = null;
                              }

                              return DropdownButtonFormField<String>(
                                value: _selectedZoneId,
                                decoration: InputDecoration(
                                  labelText: 'Zona',
                                  border: OutlineInputBorder(),
                                ),
                                items: zones.map((zone) {
                                  return DropdownMenuItem<String>(
                                    value: zone.id,
                                    child: Text(zone.name),
                                  );
                                }).toList(),
                                onChanged: (String? value) {
                                  setState(() {
                                    _selectedZoneId = value;
                                  });
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
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Imagen principal
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Imagen Principal',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFCC0000),
                            ),
                          ),
                          SizedBox(height: 12),

                          // Mostrar imagen actual o nueva
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _mainImage != null
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: UniversalImageWidget(
                                file: _mainImage,
                                fit: BoxFit.cover,
                              ),
                            )
                                : ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _buildMainImageWidget(widget.venue.mainImageUrl),
                            ),
                          ),
                          SizedBox(height: 8),

                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _pickMainImage,
                                icon: Icon(Icons.image),
                                label: Text('Cambiar Imagen'),
                              ),
                              SizedBox(width: 8),
                              if (_mainImage != null)
                                Text('✓ Nueva imagen seleccionada', style: TextStyle(color: Colors.green)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Galería
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Galería (Cartelera)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFCC0000),
                            ),
                          ),
                          SizedBox(height: 12),

                          // Mostrar galería actual
                          if (widget.venue.galleryImages.isNotEmpty || _galleryImages.isNotEmpty)
                            Container(
                              height: 120,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _galleryImages.isNotEmpty
                                    ? _galleryImages.length
                                    : widget.venue.galleryImages.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    width: 120,
                                    margin: EdgeInsets.only(right: 8),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: _galleryImages.isNotEmpty
                                          ? UniversalImageWidget(
                                        file: _galleryImages[index],
                                        fit: BoxFit.cover,
                                      )
                                          : _buildGalleryImageWidget(widget.venue.galleryImages[index]),
                                    ),
                                  );
                                },
                              ),
                            ),
                          SizedBox(height: 8),

                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _pickGalleryImages,
                                icon: Icon(Icons.photo_library),
                                label: Text('Cambiar Galería'),
                              ),
                              SizedBox(width: 8),
                              if (_galleryImages.isNotEmpty)
                                Text('✓ ${_galleryImages.length} nuevas imágenes', style: TextStyle(color: Colors.green)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _updateVenue,
                          child: _isLoading
                              ? CircularProgressIndicator()
                              : Text('Guardar Cambios'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: Size(double.infinity, 50),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _deleteVenue,
                          child: Text('Eliminar Local'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            minimumSize: Size(double.infinity, 50),
                          ),
                        ),
                      ),
                    ],
                  ),
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

  Future<void> _updateVenue() async {
    if (_selectedZoneId == null || _nameController.text.isEmpty) {
      _showSnackBar('Por favor completa todos los campos requeridos');
      return;
    }

    setState(() => _isLoading = true);

    Map<String, dynamic> updates = {
      'name': _nameController.text,
      'zoneId': _selectedZoneId,
      'description': _descriptionController.text,
      'location': _locationController.text,
      'ownerId': _ownerIdController.text,
      'isPremium': _isPremium,
    };

    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    final success = await databaseService.updateVenue(
      widget.venue.id,
      updates,
      mainImageFile: _mainImage,
      galleryFiles: _galleryImages,
    );

    setState(() => _isLoading = false);

    if (success) {
      _showSnackBar('Local actualizado exitosamente');
      Navigator.pop(context);
    } else {
      _showSnackBar('Error al actualizar el local');
    }
  }

  Future<void> _deleteVenue() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar "${widget.venue.name}"?\n\nEsta acción no se puede deshacer.'),
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
      setState(() => _isLoading = true);

      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      final success = await databaseService.deleteVenue(widget.venue.id);

      setState(() => _isLoading = false);

      if (success) {
        _showSnackBar('Local eliminado exitosamente');
        Navigator.pop(context);
      } else {
        _showSnackBar('Error al eliminar el local');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _ownerIdController.dispose();
    super.dispose();
  }
}