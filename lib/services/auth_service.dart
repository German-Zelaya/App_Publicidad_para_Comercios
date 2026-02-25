import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Solo inicializar GoogleSignIn en móvil
  GoogleSignIn? _googleSignIn;

  UserModel? _currentUser;
  bool _isLoading = true;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  AuthService() {
    // Solo inicializar GoogleSignIn en móvil, no en web
    if (!kIsWeb) {
      _googleSignIn = GoogleSignIn();
    }

    // Escuchar cambios de autenticación
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        try {
          // Intentar obtener usuario de Firestore
          DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();

          if (doc.exists && doc.data() != null) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            _currentUser = UserModel(
              id: user.uid,
              email: data['email'] ?? user.email ?? '',
              name: data['name'] ?? user.displayName ?? 'Usuario',
              role: _parseRole(data['role']),
              photoUrl: data['photoUrl'] ?? user.photoURL,
              createdAt: data['createdAt'] != null
                  ? (data['createdAt'] as Timestamp).toDate()
                  : DateTime.now(),
              venueId: data['venueId'],
            );
          } else {
            // Si no existe en Firestore, crear uno básico
            _currentUser = UserModel(
              id: user.uid,
              email: user.email ?? '',
              name: user.displayName ?? 'Usuario',
              role: UserRole.user,
              photoUrl: user.photoURL,
              createdAt: DateTime.now(),
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error loading user data: $e');
          }
          _currentUser = null;
        }
      } else {
        _currentUser = null;
      }

      _isLoading = false;
      notifyListeners();
    });

    // IMPORTANTE: Manejar resultado de redirect para web
    if (kIsWeb) {
      _handleWebRedirectResult();
    }
  }

  // Método para manejar el resultado del redirect en web
  Future<void> _handleWebRedirectResult() async {
    try {
      final result = await _auth.getRedirectResult();
      if (result.user != null) {
        // El usuario se autenticó via redirect, crear documento si es necesario
        await _ensureUserDocument(result.user!);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling redirect result: $e');
      }
    }
  }

  UserRole _parseRole(dynamic role) {
    if (role == null) return UserRole.user;

    switch (role.toString()) {
      case 'admin':
        return UserRole.admin;
      case 'client':
        return UserRole.client;
      case 'user':
      default:
        return UserRole.user;
    }
  }

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Email sign in error: $e');
      }
      return false;
    }
  }

  Future<bool> registerWithEmailAndPassword(String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        await _ensureUserDocument(result.user!, name: name);
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Email register error: $e');
      }
      return false;
    }
  }

  // MÉTODO PRINCIPAL CORREGIDO PARA GOOGLE SIGN-IN
  Future<bool> signInWithGoogle() async {
    try {
      UserCredential? result;

      if (kIsWeb) {
        // CONFIGURACIÓN ESPECÍFICA PARA WEB
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();

        // CRÍTICO: Configurar scopes correctamente
        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        // CRÍTICO: Parámetros específicos para evitar errores CORS
        googleProvider.setCustomParameters({
          'prompt': 'select_account',
          'include_granted_scopes': 'true',
          'access_type': 'online',
        });

        try {
          // Intentar popup primero
          result = await _auth.signInWithPopup(googleProvider);

          if (kDebugMode) {
            print('Google Sign-In popup successful');
          }
        } catch (popupError) {
          if (kDebugMode) {
            print('Popup failed, trying redirect: $popupError');
          }

          // Si popup falla, usar redirect como backup
          try {
            await _auth.signInWithRedirect(googleProvider);
            // El redirect se manejará en _handleWebRedirectResult
            return true;
          } catch (redirectError) {
            if (kDebugMode) {
              print('Redirect also failed: $redirectError');
            }
            return false;
          }
        }
      } else {
        // PARA MÓVIL (que ya funciona)
        if (_googleSignIn == null) return false;

        final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
        if (googleUser == null) return false;

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        result = await _auth.signInWithCredential(credential);
      }

      if (result?.user != null) {
        await _ensureUserDocument(result!.user!);
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Google Sign-In error (${kIsWeb ? 'Web' : 'Mobile'}): $e');

        // Logging específico para errores web
        if (kIsWeb) {
          if (e.toString().contains('popup_blocked_by_browser')) {
            print('Popup blocked - user needs to enable popups');
          } else if (e.toString().contains('auth/unauthorized-domain')) {
            print('Unauthorized domain - check Google Console configuration');
          } else if (e.toString().contains('network')) {
            print('Network error - possibly CORS related');
          }
        }
      }
      return false;
    }
  }

  // Método auxiliar para asegurar que el documento del usuario existe
  Future<void> _ensureUserDocument(User user, {String? name}) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        // Crear nuevo usuario
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'name': name ?? user.displayName ?? 'Usuario',
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
          'photoUrl': user.photoURL,
          'venueId': null,
        });

        if (kDebugMode) {
          print('Created new user document for ${user.email}');
        }
      } else {
        // Actualizar último login
        await _firestore.collection('users').doc(user.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }
    } catch (firestoreError) {
      if (kDebugMode) {
        print('Firestore error: $firestoreError');
      }
      // No bloquear la autenticación por errores de Firestore
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      // Solo hacer signOut de Google en móvil
      if (!kIsWeb && _googleSignIn != null) {
        await _googleSignIn!.signOut();
      }
      // Para web, también limpiar la sesión de Google si es posible
      if (kIsWeb) {
        try {
          // Intentar limpiar la sesión de Google en web
          final GoogleSignIn webGoogleSignIn = GoogleSignIn();
          await webGoogleSignIn.signOut();
        } catch (e) {
          // Error silencioso - no es crítico
          if (kDebugMode) {
            print('Web Google signOut error (not critical): $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('SignOut error: $e');
      }
    }
  }

  Future<bool> updateUserRole(String userId, UserRole newRole, {String? venueId}) async {
    try {
      Map<String, dynamic> updateData = {
        'role': newRole.toString().split('.').last,
      };

      if (newRole == UserRole.client && venueId != null) {
        updateData['venueId'] = venueId;
      } else if (newRole != UserRole.client) {
        updateData['venueId'] = null;
      }

      await _firestore.collection('users').doc(userId).update(updateData);

      // Sincronizar el ownerId del local con el usuario asignado
      if (newRole == UserRole.client && venueId != null) {
        await _firestore.collection('venues').doc(venueId).update({'ownerId': userId});
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Update user role error: $e');
      }
      return false;
    }
  }

  bool canAccessAdminFeatures() {
    return _currentUser?.role == UserRole.admin;
  }

  bool canAccessClientFeatures() {
    return _currentUser?.role == UserRole.client || _currentUser?.role == UserRole.admin;
  }

  bool canEditVenue(String venueId) {
    if (_currentUser?.role == UserRole.admin) return true;
    if (_currentUser?.role == UserRole.client && _currentUser?.venueId == venueId) return true;
    return false;
  }
}