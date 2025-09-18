import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/navigation_service.dart';
import 'services/sms_listener_service.dart';

void main() async {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('FlutterError: ${details.toString()}');
  };

  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase inicializado correctamente');
    await NotificationService.initialize();
    print('Servicio de notificaciones inicializado');
    // Iniciar el listener de SMS
    await SMSListenerService.start();
  } catch (e, stackTrace) {
    print('Error al inicializar Firebase: $e');
    print('Stack trace: $stackTrace');
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
      navigatorKey: NavigationService.navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade900),
        useMaterial3: true,
      ),
      home: Stack(
        children: [
          const SplashScreen(),
          // Eliminado campo OTP invisible, ya no es necesario
          // Banner para mostrar nuevo SMS detectado
          ValueListenableBuilder<Map<String, String>?>(
            valueListenable: SMSListenerService.lastSmsNotifier,
            builder: (context, sms, child) {
              if (sms == null) return const SizedBox.shrink();
              return Positioned(
                top: 40,
                left: 0,
                right: 0,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade900,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.sms, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Nuevo mensaje detectado:\n${sms['title']}\n${sms['body']}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => SMSListenerService.lastSmsNotifier.value = null,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
