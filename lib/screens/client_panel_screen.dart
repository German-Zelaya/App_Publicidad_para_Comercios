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
import '../widgets/custom_nav_bar.dart';
import '../widgets/universal_image_widget.dart';

class ClientPanelScreen extends StatefulWidget {
  @override
  _ClientPanelScreenState createState() => _ClientPanelScreenState();
}

class _ClientPanelScreenState extends State<ClientPanelScreen> {
  VenueModel? _venue;
  bool _isLoading = true;
  final _locationController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _socialControllers = <String, TextEditingController>{};
  File? _mainImage;
  List<File> _galleryImages = [];

  // Widget para imagen principal
  Widget _buildMainImageWidget(String imageUrl) {
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
    _loadVenue();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _whatsappController.dispose();
    for (final c in _socialControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadVenue() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final databaseService = Provider.of<DatabaseService>(context, listen: false);

    print('=== DEBUG PANEL CLIENTE ===');
    print('Usuario actual ID: ${authService.currentUser?.id}');
    print('Usuario rol: ${authService.currentUser?.role}');
    print('Usuario venueId: ${authService.currentUser?.venueId}');

    if (authService.currentUser?.id != null) {
      try {
        final venuesStream = databaseService.getAllVenues();
        final allVenues = await venuesStream.first;

        print('Total venues encontrados: ${allVenues.length}');

        final userVenues = allVenues.where((venue) {
          print('Venue: ${venue.name} - OwnerID: ${venue.ownerId} - ¿Es del usuario?: ${venue.ownerId == authService.currentUser!.id}');
          return venue.ownerId == authService.currentUser!.id;
        }).toList();

        print('Venues filtrados para este usuario: ${userVenues.length}');

        setState(() {
          if (userVenues.isNotEmpty) {
            _venue = userVenues.first;
            print('Venue asignado: ${_venue!.name}');
            _locationController.text = _venue!.location;
            _whatsappController.text =
                _venue!.socialMedia['WhatsApp'] ?? _venue!.socialMedia['whatsapp'] ?? '';
            _venue!.socialMedia.forEach((key, value) {
              if (key.toLowerCase() != 'whatsapp') {
                _socialControllers[key] = TextEditingController(text: value);
              }
            });
          } else {
            _venue = null;
            print('No se encontraron venues para este usuario');
          }
          _isLoading = false;
        });
      } catch (e) {
        print('Error cargando venue: $e');
        setState(() {
          _venue = null;
          _isLoading = false;
        });
      }
    } else {
      print('Usuario no autenticado');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          CustomNavBar(
            title: 'Panel de Cliente',
            user: user,
            showBackButton: true,
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _venue == null
                ? _buildNoVenueMessage()
                : _buildVenueEditor(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoVenueMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store_mall_directory,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No tienes un local asignado',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Contacta al administrador para que te asigne un local',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVenueEditor() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información del local
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _venue!.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A148C),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _venue!.description,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
                      color: Color(0xFF4A148C),
                    ),
                  ),
                  SizedBox(height: 12),
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
                      child: _buildMainImageWidget(_venue!.mainImageUrl),
                    ),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _pickMainImage,
                    icon: Icon(Icons.camera_alt),
                    label: Text('Cambiar Imagen Principal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4A148C),
                      foregroundColor: Colors.white,
                    ),
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
                    'Cartelera / Galería',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A148C),
                    ),
                  ),
                  SizedBox(height: 12),
                  if (_venue!.galleryImages.isNotEmpty || _galleryImages.isNotEmpty)
                    Container(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _galleryImages.isNotEmpty
                            ? _galleryImages.length
                            : _venue!.galleryImages.length,
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
                                  : _buildGalleryImageWidget(_venue!.galleryImages[index]),
                            ),
                          );
                        },
                      ),
                    ),
                  SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _pickGalleryImages,
                    icon: Icon(Icons.photo_library),
                    label: Text('Cambiar Cartelera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Ubicación
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ubicación',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A148C),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: 'Dirección o coordenadas',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // WhatsApp
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.message, color: Color(0xFF25D366)),
                      SizedBox(width: 8),
                      Text(
                        'WhatsApp',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A148C),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _whatsappController,
                    keyboardType: TextInputType.phone,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Número de contacto',
                      hintText: 'Ej: 59170123456',
                      helperText: 'Ingresa tu número con código de país (591 para Bolivia)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.message, color: Color(0xFF25D366)),
                    ),
                  ),
                  if (_whatsappController.text.trim().isNotEmpty) ...[
                    SizedBox(height: 8),
                    Text(
                      'Enlace: wa.me/${_whatsappController.text.trim()}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Redes sociales
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Redes Sociales',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A148C),
                        ),
                      ),
                      IconButton(
                        onPressed: _addSocialMedia,
                        icon: Icon(Icons.add),
                        color: Color(0xFF4A148C),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  ..._socialControllers.entries.map((entry) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: entry.value,
                              decoration: InputDecoration(
                                labelText: entry.key,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _removeSocialMedia(entry.key),
                            icon: Icon(Icons.delete, color: Colors.red),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),

          // Botón guardar
          ElevatedButton(
            onPressed: _saveChanges,
            child: Text('Guardar Cambios'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
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
    if (image != null) {
      setState(() {
        _mainImage = image;
      });
    }
  }

  Future<void> _pickGalleryImages() async {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    final images = await databaseService.pickMultipleImages();
    if (images.isNotEmpty) {
      setState(() {
        _galleryImages = images;
      });
    }
  }

  void _addSocialMedia() {
    showDialog(
      context: context,
      builder: (context) {
        String platform = '';
        return AlertDialog(
          title: Text('Agregar Red Social'),
          content: TextField(
            onChanged: (value) => platform = value,
            decoration: InputDecoration(
              labelText: 'Plataforma (ej: WhatsApp, Facebook)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (platform.isNotEmpty) {
                  setState(() {
                    _socialControllers[platform] = TextEditingController();
                  });
                }
                Navigator.pop(context);
              },
              child: Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  void _removeSocialMedia(String platform) {
    setState(() {
      _socialControllers.remove(platform);
    });
  }

  Future<void> _saveChanges() async {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);

    final Map<String, String> allSocialMedia = Map.fromEntries(
      _socialControllers.entries
          .where((entry) => entry.value.text.isNotEmpty)
          .map((entry) => MapEntry(entry.key, entry.value.text)),
    );
    if (_whatsappController.text.trim().isNotEmpty) {
      allSocialMedia['WhatsApp'] = _whatsappController.text.trim();
    }

    Map<String, dynamic> updates = {
      'location': _locationController.text,
      'socialMedia': allSocialMedia,
    };

    final success = await databaseService.updateVenue(
      _venue!.id,
      updates,
      mainImageFile: _mainImage,
      galleryFiles: _galleryImages,
    );

    if (success) {
      _showSnackBar('Cambios guardados exitosamente');
      await _loadVenue();
      setState(() {
        _mainImage = null;
        _galleryImages = [];
      });
    } else {
      _showSnackBar('Error al guardar los cambios');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}