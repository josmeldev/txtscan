import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';

void main() async {
  // Agregar manejo de errores no capturados
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('FlutterError: ${details.toString()}');
  };

  // Asegurarse de que Flutter esté inicializado correctamente
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase con mejor manejo de errores
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase inicializado correctamente');
    
    // Inicializar servicio de notificaciones
    await NotificationService.initialize();
    print('Servicio de notificaciones inicializado');
    
    // Obtener y mostrar el token FCM en consola
    final token = await NotificationService.getToken();
    print('=== TOKEN FCM ===');
    print(token);
    print('================');
  } catch (e, stackTrace) {
    print('Error al inicializar Firebase: $e');
    print('Stack trace: $stackTrace');
    // Continúa ejecutando la app sin Firebase por ahora
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TxtScan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade900),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
