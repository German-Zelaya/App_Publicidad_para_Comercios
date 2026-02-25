import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:typed_data';
import '../models/venue_model.dart';
import '../services/image_loader_service.dart';

class VenueCard extends StatelessWidget {
  final VenueModel venue;
  final VoidCallback onTap;

  const VenueCard({
    Key? key,
    required this.venue,
    required this.onTap,
  }) : super(key: key);

  // Función para optimizar URLs de Cloudinary para web
  String optimizeCloudinaryUrl(String originalUrl, {bool isWeb = false}) {
    if (!isWeb) return originalUrl;

    // Si la URL ya tiene transformaciones, devolverla tal como está
    if (originalUrl.contains('/c_')) return originalUrl;

    // Si es URL de Cloudinary, agregar optimizaciones
    if (originalUrl.contains('cloudinary.com')) {
      // Buscar el punto donde insertar las transformaciones
      if (originalUrl.contains('/upload/')) {
        return originalUrl.replaceFirst(
            '/upload/',
            '/upload/c_fill,w_240,h_240,q_auto,f_auto/'
        );
      }
    }

    return originalUrl;
  }

  Widget _buildImageWidget(String imageUrl, bool isWeb) {
    if (isWeb) {
      // En web, usar el servicio de carga sin CORS
      return FutureBuilder<Uint8List?>(
        future: ImageLoaderService.loadImageBytes(optimizeCloudinaryUrl(imageUrl, isWeb: isWeb)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              color: Colors.grey[300],
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF1744)),
                  ),
                ),
              ),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return _buildErrorWidget();
              },
            );
          } else {
            return _buildErrorWidget();
          }
        },
      );
    } else {
      // En móvil, usar CachedNetworkImage normal
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        height: double.infinity,
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
        errorWidget: (context, url, error) => _buildErrorWidget(),
      );
    }
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[300],
      child: Icon(
        Icons.image_not_supported,
        size: 40,
        color: Colors.grey[600],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 120,
          child: Row(
            children: [
              // Imagen con fix de CORS
              Container(
                width: 120,
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  child: _buildImageWidget(venue.mainImageUrl, isWeb),
                ),
              ),

              // Contenido
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        venue.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF1744),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        venue.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (venue.isPremium) ...[
                        SizedBox(height: 4),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'PREMIUM',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Flecha
              Padding(
                padding: EdgeInsets.all(12),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFFFF1744),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}