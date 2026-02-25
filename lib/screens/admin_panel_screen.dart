import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';
import '../models/zone_model.dart';
import '../models/venue_model.dart';
import '../widgets/custom_nav_bar.dart';
import 'admin_zones_screen.dart';
import 'admin_venues_screen.dart';
import 'admin_users_screen.dart';
import 'admin_premium_screen.dart';

class AdminPanelScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          CustomNavBar(
            title: 'Panel de Admin',
            user: user,
            showBackButton: true,
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildAdminCard(
                    context,
                    'Gestión Premium',
                    Icons.star,
                    Colors.amber,
                        () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AdminPremiumScreen()),
                    ),
                  ),
                  _buildAdminCard(
                    context,
                    'Gestionar Zonas',
                    Icons.location_city,
                    Colors.blue,
                        () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AdminZonesScreen()),
                    ),
                  ),
                  _buildAdminCard(
                    context,
                    'Gestionar Locales',
                    Icons.store,
                    Colors.red,
                        () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AdminVenuesScreen()),
                    ),
                  ),
                  _buildAdminCard(
                    context,
                    'Gestionar Usuarios',
                    Icons.people,
                    Colors.green,
                        () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AdminUsersScreen()),
                    ),
                  ),
                  _buildAdminCard(
                    context,
                    'Estadísticas',
                    Icons.analytics,
                    Colors.orange,
                        () => _showComingSoon(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCard(
      BuildContext context,
      String title,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.8), color],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Colors.white,
              ),
              SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Próximamente'),
        content: Text('Esta funcionalidad estará disponible pronto.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}