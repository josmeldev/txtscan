import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart'; // Cambiado de home_screen.dart a main_screen.dart
import 'services/auth_service.dart';

class AuthStateWrapper extends StatelessWidget {
  const AuthStateWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService _authService = AuthService();
    
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final User? user = snapshot.data;
          if (user == null) {
            // No hay usuario autenticado, mostrar login
            return const LoginScreen();
          } else {
            // Usuario autenticado, mostrar la pantalla principal con navegación
            return const MainScreen();
          }
        }
        
        // Mientras se verifica el estado de autenticación
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
