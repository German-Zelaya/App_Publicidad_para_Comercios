import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'dart:typed_data';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/image_loader_service.dart';
import '../models/zone_model.dart';
import '../widgets/custom_nav_bar.dart';

class AdminZonesScreen extends StatefulWidget {
  @override
  _AdminZonesScreenState createState() => _AdminZonesScreenState();
}

class _AdminZonesScreenState extends State<AdminZonesScreen> {
  final _nameController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;

  // Widget para manejar imágenes de zonas
  Widget _buildZoneImageWidget(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Icon(Icons.location_city);
    }

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
        placeholder: (context, url) => Container(
          color: Colors.grey[300],
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Icon(Icons.image_not_supported),
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
            title: 'Gestionar Zonas',
            user: user,
            showBackButton: true,
          ),
          Expanded(
            child: Column(
              children: [
                // Formulario para agregar zona
                Card(
                  margin: EdgeInsets.all(16),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Agregar Nueva Zona',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFCC0000),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Nombre de la zona',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _pickImage,
                              icon: Icon(Icons.image),
                              label: Text('Seleccionar Imagen'),
                            ),
                            SizedBox(width: 8),
                            if (_selectedImage != null)
                              Text('Imagen seleccionada', style: TextStyle(color: Colors.green)),
                          ],
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _addZone,
                          child: _isLoading
                              ? CircularProgressIndicator()
                              : Text('Agregar Zona'),
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

                // Lista de zonas existentes
                Expanded(
                  child: StreamBuilder<List<ZoneModel>>(
                    stream: databaseService.getZones(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      final zones = snapshot.data!;

                      return ListView.builder(
                        itemCount: zones.length,
                        itemBuilder: (context, index) {
                          final zone = zones[index];
                          return Card(
                            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[300],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: _buildZoneImageWidget(zone.imageUrl),
                                ),
                              ),
                              title: Text(zone.name),
                              subtitle: Text('Orden: ${zone.order}'),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Editar'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Eliminar'),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _editZone(zone);
                                  } else if (value == 'delete') {
                                    _deleteZone(zone.id);
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
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

  Future<void> _addZone() async {
    if (_nameController.text.isEmpty) {
      _showSnackBar('Por favor ingresa el nombre de la zona');
      return;
    }

    setState(() => _isLoading = true);

    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    final success = await databaseService.addZone(_nameController.text, _selectedImage);

    setState(() => _isLoading = false);

    if (success) {
      _nameController.clear();
      _selectedImage = null;
      setState(() {});
      _showSnackBar('Zona agregada exitosamente');
    } else {
      _showSnackBar('Error al agregar la zona');
    }
  }

  void _editZone(ZoneModel zone) {
    _nameController.text = zone.name;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Zona'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Nombre'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final databaseService = Provider.of<DatabaseService>(context, listen: false);
              final success = await databaseService.updateZone(
                zone.id,
                _nameController.text,
                _selectedImage,
              );
              Navigator.pop(context);
              _showSnackBar(success ? 'Zona actualizada' : 'Error al actualizar');
              _nameController.clear();
              _selectedImage = null;
            },
            child: Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteZone(String zoneId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar'),
        content: Text('¿Estás seguro de que quieres eliminar esta zona?'),
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
      final success = await databaseService.deleteZone(zoneId);
      _showSnackBar(success ? 'Zona eliminada' : 'Error al eliminar');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}