import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart'; 
import 'services/auth_service.dart';

class AuthStateWrapper extends StatefulWidget {
  const AuthStateWrapper({super.key});

  @override
  State<AuthStateWrapper> createState() => _AuthStateWrapperState();
}

class _AuthStateWrapperState extends State<AuthStateWrapper> {
  final AuthService _authService = AuthService();
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // Verificar la conexión y estado de autenticación
        if (snapshot.connectionState == ConnectionState.active) {
          final User? user = snapshot.data;
          
          print('AuthStateWrapper: Estado de autenticación cambiado - Usuario: ${user != null ? 'Autenticado' : 'No autenticado'}');
          
          if (user == null) {
            // No hay usuario autenticado, mostrar login
            return LoginScreen();
          } else {
            // Usuario autenticado, mostrar la pantalla principal con navegación
            return MainScreen();
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
