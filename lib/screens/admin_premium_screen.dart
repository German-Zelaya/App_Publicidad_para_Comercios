import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'dart:typed_data';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/image_loader_service.dart';
import '../models/premium_banner_model.dart';
import '../models/venue_model.dart';
import '../widgets/custom_nav_bar.dart';
import '../widgets/universal_image_widget.dart';

class AdminPremiumScreen extends StatefulWidget {
  @override
  _AdminPremiumScreenState createState() => _AdminPremiumScreenState();
}

class _AdminPremiumScreenState extends State<AdminPremiumScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _selectedImage;
  String? _linkedVenueId;
  bool _isLoading = false;

  // Widget para manejar imágenes con CORS
  Widget _buildImageWidget(String imageUrl) {
    if (kIsWeb) {
      return FutureBuilder<Uint8List?>(
        future: ImageLoaderService.loadImageBytes(imageUrl),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              color: Colors.grey[300],
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: Icon(Icons.broken_image, size: 40),
                );
              },
            );
          } else {
            return Container(
              color: Colors.grey[300],
              child: Icon(Icons.broken_image, size: 40),
            );
          }
        },
      );
    } else {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) => Container(
          color: Colors.grey[300],
          child: Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[300],
          child: Icon(Icons.broken_image, size: 40),
        ),
      );
    }
  }

  // Widget para miniaturas de imágenes
  Widget _buildThumbnailWidget(String imageUrl) {
    if (kIsWeb) {
      return FutureBuilder<Uint8List?>(
        future: ImageLoaderService.loadImageBytes(imageUrl),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              color: Colors.grey[300],
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: Icon(Icons.image),
                );
              },
            );
          } else {
            return Container(
              color: Colors.grey[300],
              child: Icon(Icons.broken_image),
            );
          }
        },
      );
    } else {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[300],
          child: Icon(Icons.image),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[300],
          child: Icon(Icons.broken_image),
        ),
      );
    }
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
            title: 'Gestión Premium',
            user: user,
            showBackButton: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Formulario para agregar nueva imagen
                  Card(
                    margin: EdgeInsets.all(16),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.add_photo_alternate, color: Color(0xFFCC0000)),
                              SizedBox(width: 8),
                              Text(
                                'Agregar Imagen al Carrusel',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFCC0000),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),

                          // Selector de imagen
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!, width: 2, style: BorderStyle.solid),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey[50],
                              ),
                              child: _selectedImage != null
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: UniversalImageWidget(
                                  file: _selectedImage,
                                  fit: BoxFit.cover,
                                ),
                              )
                                  : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, size: 48, color: Colors.grey[400]),
                                  SizedBox(height: 8),
                                  Text(
                                    'Toca para seleccionar imagen',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 16),

                          // Título
                          TextField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              labelText: 'Título (opcional)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.title),
                            ),
                          ),
                          SizedBox(height: 16),

                          // Descripción
                          TextField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              labelText: 'Descripción (opcional)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.description),
                            ),
                            maxLines: 2,
                          ),
                          SizedBox(height: 16),

                          // Enlazar a local (opcional)
                          StreamBuilder<List<VenueModel>>(
                            stream: databaseService.getAllVenues(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return Container();
                              }

                              return DropdownButtonFormField<String>(
                                value: _linkedVenueId,
                                decoration: InputDecoration(
                                  labelText: 'Enlazar a local (opcional)',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.link),
                                ),
                                items: [
                                  DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('Sin enlace'),
                                  ),
                                  ...snapshot.data!.map((venue) {
                                    return DropdownMenuItem<String>(
                                      value: venue.id,
                                      child: Text(venue.name),
                                    );
                                  }).toList(),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _linkedVenueId = value;
                                  });
                                },
                              );
                            },
                          ),
                          SizedBox(height: 20),

                          // Botón agregar
                          ElevatedButton(
                            onPressed: _isLoading ? null : _addBanner,
                            child: _isLoading
                                ? CircularProgressIndicator()
                                : Text('Agregar al Carrusel'),
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

                  // Vista previa del carrusel actual
                  Card(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Carrusel Actual',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFCC0000),
                            ),
                          ),
                          SizedBox(height: 12),
                          StreamBuilder<List<PremiumBannerModel>>(
                            stream: databaseService.getPremiumBanners(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return Center(child: CircularProgressIndicator());
                              }

                              final banners = snapshot.data!;

                              if (banners.isEmpty) {
                                return Container(
                                  padding: EdgeInsets.all(32),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.photo_library_outlined,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'No hay imágenes en el carrusel',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return Column(
                                children: [
                                  // Vista previa horizontal
                                  Container(
                                    height: 180,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: banners.length,
                                      itemBuilder: (context, index) {
                                        final banner = banners[index];
                                        return Container(
                                          width: 280,
                                          margin: EdgeInsets.only(right: 12),
                                          child: Card(
                                            elevation: 4,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Stack(
                                              children: [
                                                // Imagen CON IMAGELOADERSERVICE
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: _buildImageWidget(banner.imageUrl),
                                                ),
                                                // Overlay con info
                                                if (banner.title.isNotEmpty)
                                                  Positioned(
                                                    bottom: 0,
                                                    left: 0,
                                                    right: 0,
                                                    child: Container(
                                                      padding: EdgeInsets.all(8),
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.only(
                                                          bottomLeft: Radius.circular(12),
                                                          bottomRight: Radius.circular(12),
                                                        ),
                                                        gradient: LinearGradient(
                                                          begin: Alignment.topCenter,
                                                          end: Alignment.bottomCenter,
                                                          colors: [
                                                            Colors.transparent,
                                                            Colors.black.withOpacity(0.7),
                                                          ],
                                                        ),
                                                      ),
                                                      child: Text(
                                                        banner.title,
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ),
                                                // Botón eliminar
                                                Positioned(
                                                  top: 8,
                                                  right: 8,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.red,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: IconButton(
                                                      icon: Icon(Icons.delete, color: Colors.white, size: 18),
                                                      onPressed: () => _deleteBanner(banner),
                                                      tooltip: 'Eliminar',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(height: 16),

                                  // Lista detallada con controles de orden
                                  ...banners.map((banner) {
                                    return Card(
                                      margin: EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        leading: Container(
                                          width: 60,
                                          height: 60,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: _buildThumbnailWidget(banner.imageUrl),
                                          ),
                                        ),
                                        title: Text(banner.title.isEmpty ? 'Sin título' : banner.title),
                                        subtitle: Text('Orden: ${banner.order}'),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.arrow_upward),
                                              onPressed: banner.order > 1 ? () => _changeBannerOrder(banner, banner.order - 1) : null,
                                              tooltip: 'Subir',
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.arrow_downward),
                                              onPressed: () => _changeBannerOrder(banner, banner.order + 1),
                                              tooltip: 'Bajar',
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete, color: Colors.red),
                                              onPressed: () => _deleteBanner(banner),
                                              tooltip: 'Eliminar',
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ],
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

  Future<void> _pickImage() async {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    final image = await databaseService.pickImage();
    setState(() {
      _selectedImage = image;
    });
  }

  Future<void> _addBanner() async {
    if (_selectedImage == null) {
      _showSnackBar('Por favor selecciona una imagen');
      return;
    }

    setState(() => _isLoading = true);

    final databaseService = Provider.of<DatabaseService>(context, listen: false);

    final success = await databaseService.addPremiumBanner(
      _selectedImage!,
      _titleController.text,
      _descriptionController.text,
      _linkedVenueId,
    );

    setState(() => _isLoading = false);

    if (success) {
      _clearForm();
      _showSnackBar('Imagen agregada al carrusel');
    } else {
      _showSnackBar('Error al agregar la imagen');
    }
  }

  Future<void> _deleteBanner(PremiumBannerModel banner) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar'),
        content: Text('¿Eliminar esta imagen del carrusel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      final success = await databaseService.deletePremiumBanner(banner.id);

      if (success) {
        _showSnackBar('Imagen eliminada del carrusel');
      } else {
        _showSnackBar('Error al eliminar la imagen');
      }
    }
  }

  Future<void> _changeBannerOrder(PremiumBannerModel banner, int newOrder) async {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    final success = await databaseService.updateBannerOrder(banner.id, newOrder);

    if (success) {
      _showSnackBar('Orden actualizado');
    } else {
      _showSnackBar('Error al actualizar el orden');
    }
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedImage = null;
      _linkedVenueId = null;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}