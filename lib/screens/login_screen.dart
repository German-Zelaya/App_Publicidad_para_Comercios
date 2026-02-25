// screens/login_screen.dart - CORREGIDO para tu AuthService
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 50),
              Text(
                'FIN-D',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                  color: Color(0xFFFF1744),
                  shadows: [
                    Shadow(
                      color: Color(0xFFFF1744),
                      blurRadius: 20,
                    ),
                    Shadow(
                      color: Color(0xFFFF1744).withOpacity(0.6),
                      blurRadius: 45,
                    ),
                    Shadow(
                      color: Color(0xFFFF0000).withOpacity(0.3),
                      blurRadius: 80,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 50),
              Card(
                color: Color(0xFF1A1A1A),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      if (!_isLogin) ...[
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Nombre',
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        SizedBox(height: 16),
                      ],
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleEmailAuth,
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(_isLogin ? 'Iniciar Sesión' : 'Registrarse'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFCC0000),
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 50),
                        ),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _handleGoogleAuth,
                        icon: Icon(Icons.login),
                        label: Text('Continuar con Google'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 50),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                          });
                        },
                        child: Text(
                          _isLogin
                              ? '¿No tienes cuenta? Regístrate'
                              : '¿Ya tienes cuenta? Inicia sesión',
                        ),
                      ),
                      // Mensaje informativo para web
                      if (kIsWeb) ...[
                        SizedBox(height: 10),
                        Text(
                          'Si el popup de Google no funciona, será redirigido automáticamente',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleEmailAuth() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      _showError('Por favor completa todos los campos');
      return;
    }

    if (!_isLogin && _nameController.text.trim().isEmpty) {
      _showError('Por favor ingresa tu nombre');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      bool success;

      if (_isLogin) {
        success = await authService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        success = await authService.registerWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );
      }

      if (!success && mounted) {
        _showError('Error en la autenticación. Verifica tus datos.');
      }
    } catch (e) {
      if (mounted) {
        _showError('Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleAuth() async {
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final success = await authService.signInWithGoogle();

      if (!success && mounted) {
        if (kIsWeb) {
          _showError(
              'Error con Google Sign-In. Asegúrate de permitir popups en tu navegador. '
                  'Si el problema persiste, serás redirigido automáticamente.'
          );
        } else {
          _showError('Error en la autenticación con Google');
        }
      }
    } catch (e) {
      if (mounted) {
        if (kIsWeb && e.toString().contains('popup')) {
          _showError(
              'Popup bloqueado. Permite popups para este sitio o '
                  'espera a ser redirigido automáticamente.'
          );
        } else {
          _showError('Error: ${e.toString()}');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}