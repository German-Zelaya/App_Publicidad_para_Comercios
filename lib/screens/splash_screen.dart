import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'FIN-D',
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
            SizedBox(height: 20),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF1744)),
            ),
          ],
        ),
      ),
    );
  }
}
