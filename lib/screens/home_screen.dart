import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:typed_data';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/image_loader_service.dart';  // NUEVO: Agrega este servicio
import '../models/venue_model.dart';
import '../models/zone_model.dart';
import '../models/user_model.dart';
import '../models/premium_banner_model.dart';
import '../widgets/custom_nav_bar.dart';
import 'zone_venues_screen.dart';
import 'venue_detail_screen.dart';
import 'admin_panel_screen.dart';
import 'client_panel_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';

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
            '/upload/c_fill,w_800,h_400,q_auto,f_auto/'
        );
      }
    }

    return originalUrl;
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final isWeb = kIsWeb;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          CustomNavBar(
            title: 'FIN-D',
            user: user,
            onMenuPressed: () => _showUserMenu(context, user!),
          ),
          Expanded(
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isWeb ? 1200 : double.infinity,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Carrusel Premium
                      _buildPremiumCarousel(isWeb: isWeb),
                      SizedBox(height: 20),

                      // Buscador de zonas
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Buscar zona...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Zonas
                      _buildZonesSection(isWeb: isWeb),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCarousel({bool isWeb = false}) {
    // Altura adaptativa para web/móvil
    double carouselHeight = isWeb ? 400 : 300;

    return Container(
      height: carouselHeight,
      margin: EdgeInsets.symmetric(horizontal: isWeb ? 20 : 0),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1A0000), Color(0xFF4D0000)],
              ),
              borderRadius: isWeb ? BorderRadius.circular(15) : null,
            ),
            child: Text(
              'PREMIUM',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isWeb ? 36 : 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<PremiumBannerModel>>(
              stream: Provider.of<DatabaseService>(context).getPremiumBanners(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final banners = snapshot.data!;
                if (banners.isEmpty) {
                  return Center(
                    child: Text(
                      'No hay contenido premium disponible',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }

                return CarouselSlider.builder(
                  itemCount: banners.length,
                  itemBuilder: (context, index, realIndex) {
                    final banner = banners[index];
                    return GestureDetector(
                      onTap: () {
                        if (banner.linkedVenueId != null) {
                          _navigateToLinkedVenue(banner.linkedVenueId!);
                        }
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              // IMAGEN CON FIX DE CORS
                              _buildImageWidget(banner.imageUrl, isWeb),

                              // Overlay con título si existe
                              if (banner.title.isNotEmpty)
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
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
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  options: CarouselOptions(
                    height: double.infinity,
                    autoPlay: true,
                    enlargeCenterPage: true,
                    viewportFraction: isWeb ? 0.7 : 0.8,
                    autoPlayInterval: Duration(seconds: 4),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // NUEVO WIDGET PARA MANEJAR IMÁGENES SIN CORS
  Widget _buildImageWidget(String imageUrl, bool isWeb) {
    if (isWeb) {
      // En web, usar el servicio de carga sin CORS
      return FutureBuilder<Uint8List?>(
        future: ImageLoaderService.loadImageBytes(
            optimizeCloudinaryUrl(imageUrl, isWeb: isWeb)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.grey[300],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFFF1744)),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Cargando imagen...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
              width: double.infinity,
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
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) =>
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.grey[300],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text(
                    'Cargando imagen...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
        errorWidget: (context, url, error) => _buildErrorWidget(),
      );
    }
  }

  Widget _buildErrorWidget() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 40, color: Colors.grey[600]),
          SizedBox(height: 10),
          Text(
            'Error al cargar imagen',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToLinkedVenue(String venueId) async {
    final databaseService = Provider.of<DatabaseService>(
        context, listen: false);
    final venue = await databaseService.getVenueById(venueId);

    if (venue != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VenueDetailScreen(venue: venue),
        ),
      );
    }
  }

  Widget _buildZonesSection({bool isWeb = false}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.red[600]!, Colors.red[800]!],
        ),
        borderRadius: BorderRadius.circular(isWeb ? 20 : 30),
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'DESCUBRE TU NUEVA AVENTURA',
            style: TextStyle(
              color: Colors.white,
              fontSize: isWeb ? 24 : 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          StreamBuilder<List<ZoneModel>>(
            stream: Provider.of<DatabaseService>(context).getZones(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final zones = snapshot.data!.where((zone) {
                return zone.name.toLowerCase().contains(_searchQuery);
              }).toList();

              if (zones.isEmpty) {
                return Center(
                  child: Text(
                    'No se encontraron zonas',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              // En web, usar grid para mejor distribución
              if (isWeb && zones.length > 3) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: zones.length,
                  itemBuilder: (context, index) {
                    final zone = zones[index];
                    return ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ZoneVenuesScreen(zone: zone),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: index % 2 == 0
                            ? Color(0xFF8B0000)
                            : Color(0xFF5C0000),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        zone.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                );
              }

              // En móvil o pocas zonas, usar lista
              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: zones.length,
                itemBuilder: (context, index) {
                  final zone = zones[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ZoneVenuesScreen(zone: zone),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: index % 2 == 0
                            ? Color(0xFF8B0000)
                            : Color(0xFF5C0000),
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, isWeb ? 50 : 60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        zone.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: isWeb ? 16 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _showUserMenu(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Color(0xFFCC0000),
                      width: 1,
                    ),
                  ),
                  child: ClipOval(
                    child: _buildMenuAvatarWidget(user),
                  ),
                ),
                title: Text(user.name),
                subtitle: Text(user.email),
              ),
              Divider(),
              if (user.role == UserRole.admin) ...[
                ListTile(
                  leading: Icon(Icons.admin_panel_settings),
                  title: Text('Panel de Administrador'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AdminPanelScreen()),
                    );
                  },
                ),
              ],
              if (user.role == UserRole.client) ...[
                ListTile(
                  leading: Icon(Icons.business),
                  title: Text('Panel de Cliente'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ClientPanelScreen()),
                    );
                  },
                ),
              ],
              ListTile(
                leading: Icon(Icons.logout),
                title: Text('Cerrar Sesión'),
                onTap: () {
                  Navigator.pop(context);
                  Provider.of<AuthService>(context, listen: false).signOut();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuAvatarWidget(UserModel user) {
    if (user.photoUrl == null) {
      return _buildMenuInitialsAvatar(user);
    }

    if (kIsWeb) {
      // En web, usar ImageLoaderService para evitar errores CORS
      return FutureBuilder<Uint8List?>(
        future: ImageLoaderService.loadImageBytes(user.photoUrl!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              color: Colors.grey[300],
              child: Center(
                child: SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFFF1744)),
                  ),
                ),
              ),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildMenuInitialsAvatar(user);
              },
            );
          } else {
            return _buildMenuInitialsAvatar(user);
          }
        },
      );
    } else {
      // En móvil, usar CachedNetworkImage normal
      return CachedNetworkImage(
        imageUrl: user.photoUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) =>
            Container(
              color: Colors.grey[300],
              child: Center(
                child: SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
              ),
            ),
        errorWidget: (context, url, error) => _buildMenuInitialsAvatar(user),
      );
    }
  }

// Widget de respaldo con iniciales para el menú
  Widget _buildMenuInitialsAvatar(UserModel user) {
    return Container(
      color: Color(0xFFCC0000),
      child: Center(
        child: Text(
          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}