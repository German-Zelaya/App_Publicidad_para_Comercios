import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';
import '../models/venue_model.dart';
import '../widgets/custom_nav_bar.dart';

class AdminUsersScreen extends StatefulWidget {
  @override
  _AdminUsersScreenState createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
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
            title: 'Gestionar Usuarios',
            user: user,
            showBackButton: true,
          ),
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: databaseService.getUsers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!;

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userItem = users[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: userItem.photoUrl != null
                              ? NetworkImage(userItem.photoUrl!)
                              : null,
                          child: userItem.photoUrl == null
                              ? Text(userItem.name[0].toUpperCase())
                              : null,
                        ),
                        title: Text(userItem.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(userItem.email),
                            SizedBox(height: 4),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getRoleColor(userItem.role),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getRoleText(userItem.role),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'admin',
                              child: Text('Hacer Administrador'),
                              enabled: userItem.role != UserRole.admin,
                            ),
                            PopupMenuItem(
                              value: 'client',
                              child: Text('Hacer Cliente'),
                              enabled: userItem.role != UserRole.client,
                            ),
                            PopupMenuItem(
                              value: 'user',
                              child: Text('Hacer Usuario'),
                              enabled: userItem.role != UserRole.user,
                            ),
                          ],
                          onSelected: (value) => _changeUserRole(userItem, value),
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
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.client:
        return Colors.blue;
      case UserRole.user:
        return Colors.green;
    }
  }

  String _getRoleText(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.client:
        return 'CLIENTE';
      case UserRole.user:
        return 'USUARIO';
    }
  }

  Future<void> _changeUserRole(UserModel user, String newRoleString) async {
    UserRole newRole;
    switch (newRoleString) {
      case 'admin':
        newRole = UserRole.admin;
        break;
      case 'client':
        newRole = UserRole.client;
        break;
      case 'user':
        newRole = UserRole.user;
        break;
      default:
        return;
    }

    String? venueId;
    if (newRole == UserRole.client) {
      // Mostrar diálogo para seleccionar venue
      venueId = await _selectVenueForClient();
      if (venueId == null) return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.updateUserRole(user.id, newRole, venueId: venueId);

    if (success) {
      _showSnackBar('Rol de usuario actualizado exitosamente');
    } else {
      _showSnackBar('Error al actualizar el rol del usuario');
    }
  }

  Future<String?> _selectVenueForClient() async {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);

    List<VenueModel> allVenues = [];
    try {
      allVenues = await databaseService.getAllVenues().first;
    } catch (e) {
      _showSnackBar('Error al cargar los locales');
      return null;
    }

    if (allVenues.isEmpty) {
      _showSnackBar('No hay locales disponibles');
      return null;
    }

    return await showDialog<String>(
      context: context,
      builder: (context) => _VenueSelectionDialog(venues: allVenues),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _VenueSelectionDialog extends StatefulWidget {
  final List<VenueModel> venues;

  const _VenueSelectionDialog({required this.venues});

  @override
  _VenueSelectionDialogState createState() => _VenueSelectionDialogState();
}

class _VenueSelectionDialogState extends State<_VenueSelectionDialog> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredVenues = widget.venues
        .where((v) => v.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return AlertDialog(
      title: Text('Seleccionar Local'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Buscar local...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            SizedBox(height: 8),
            Expanded(
              child: filteredVenues.isEmpty
                  ? Center(child: Text('No se encontraron locales'))
                  : ListView.builder(
                      itemCount: filteredVenues.length,
                      itemBuilder: (context, index) {
                        final venue = filteredVenues[index];
                        return ListTile(
                          leading: Icon(Icons.store),
                          title: Text(venue.name),
                          subtitle: venue.location.isNotEmpty
                              ? Text(
                                  venue.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          trailing: venue.isPremium
                              ? Icon(Icons.star, color: Colors.amber)
                              : null,
                          onTap: () => Navigator.pop(context, venue.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
      ],
    );
  }
}