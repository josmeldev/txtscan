import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'validation_service.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();
  static bool _isDetecting = false;
  static final ValueNotifier<bool> isDetectingNotifier = ValueNotifier<bool>(false);
  static bool _isInitialized = false; // Para evitar múltiples inicializaciones
  static final Set<String> _processedMessages = <String>{}; // Para evitar duplicados
  
  static bool get isDetecting => _isDetecting;
  
  // Inicializar el servicio de notificaciones
  static Future<void> initialize() async {
    // Evitar múltiples inicializaciones
    if (_isInitialized) {
      print('NotificationService ya está inicializado');
      return;
    }

    try {
      // Primero verificar el estado actual de los permisos
      NotificationSettings settings = await _messaging.getNotificationSettings();
      
      // Solo solicitar permisos si no están determinados
      if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        print('Solicitando permisos de notificación por primera vez...');
        settings = await _messaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );
        print('Permisos solicitados: ${settings.authorizationStatus}');
      } else {
        print('Permisos ya configurados: ${settings.authorizationStatus}');
      }

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('Usuario tiene permisos para notificaciones');
      } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
        print('Usuario negó permisos para notificaciones');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('Usuario tiene permisos provisionales para notificaciones');
      }
    } catch (e) {
      print('Error al verificar/solicitar permisos: $e');
    }

    // Configurar listeners de mensajes (solo una vez)
    _setupMessageListeners();
    
    _isInitialized = true;
    print('NotificationService inicializado correctamente');
  }

  // Configurar listeners para mensajes
  static void _setupMessageListeners() {
    // Cuando la app está en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (_isDetecting) {
        processMessage(message);
      }
    });

    // Cuando la app está en segundo plano pero no cerrada
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (_isDetecting) {
        processMessage(message);
      }
    });

    // Cuando la app está completamente cerrada
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Procesar mensajes recibidos (ahora público para el background handler)
  static Future<void> processMessage(RemoteMessage message) async {
    if (!_isDetecting) return;
    
    // Crear un ID único para el mensaje
    final messageId = '${message.messageId}_${message.sentTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}';
    
    // Verificar si ya procesamos este mensaje
    if (_processedMessages.contains(messageId)) {
      print('Mensaje ya procesado, ignorando duplicado: $messageId');
      return;
    }
    
    print('Procesando mensaje: ${message.notification?.title}');
    print('Cuerpo: ${message.notification?.body}');
    print('Message ID: $messageId');
    
    // Marcar como procesado
    _processedMessages.add(messageId);
    
    final messageText = message.notification?.body ?? 'Sin contenido';
    
    // Iniciar medición del tiempo de detección
    final startTime = DateTime.now();
    
    // Analizar con la API de smishing
    print('Analizando mensaje con API...');
    final apiResult = await _analyzeWithAPI(messageText);
    
    // Crear datos del mensaje (sin tiempo_deteccion aún)
    final messageData = {
      'title': message.notification?.title ?? 'Sin título',
      'body': messageText,
      'es_smishing': apiResult['isMalicious'],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    print('Resultado del análisis: ${apiResult['isMalicious'] ? 'SMISHING' : 'SEGURO'}');

    // Guardar en Firebase
    final savedMessageId = await _saveMessage(messageData);
    
    // Mostrar popup de validación si se guardó correctamente
    if (savedMessageId != null) {
      // Usar un delay pequeño para asegurar que el contexto esté disponible
      await Future.delayed(const Duration(milliseconds: 500));
      try {
        // Calcular tiempo total hasta que aparece el popup (en segundos con decimales)
        final endTime = DateTime.now();
        final tiempoDeteccionMs = endTime.difference(startTime).inMilliseconds;
        final tiempoDeteccion = tiempoDeteccionMs / 1000.0; // Convertir a segundos decimales
        
        // Actualizar el mensaje con el tiempo de detección
        await _updateMessageWithDetectionTime(savedMessageId, tiempoDeteccion);
        
        await ValidationService.showValidationDialog(
          savedMessageId,
          messageText,
          apiResult['isMalicious'],
        );
      } catch (e) {
        print('Error al mostrar dialog de validación: $e');
      }
    }
  }

  // Analizar mensaje con API de smishing
  static Future<Map<String, dynamic>> _analyzeWithAPI(String messageText) async {
    try {
      // URL de tu API - usar 10.0.2.2 para emulador Android
      final url = Uri.parse('https://txtscan-api.onrender.com/predict');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'texto': messageText,
        }),
      ).timeout(const Duration(seconds: 20));

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'isAnalyzed': true,
          'isMalicious': data['es_smishing'] ?? false,
          'apiResponse': data,
        };
      } else {
        print('Error en API: Status ${response.statusCode}');
        return {
          'isAnalyzed': false,
          'isMalicious': false,
          'error': 'API error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error al llamar API de smishing: $e');
      return {
        'isAnalyzed': false,
        'isMalicious': false,
        'error': e.toString(),
      };
    }
  }
  static Future<String?> _saveMessage(Map<String, dynamic> messageData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final ref = _database
            .child('users')
            .child(user.uid)
            .child('detected_messages')
            .push();
        
        await ref.set(messageData);
        
        print('Mensaje guardado en Firebase con ID: ${ref.key}');
        return ref.key; // Retornar el ID generado
      }
      return null;
    } catch (e) {
      print('Error al guardar mensaje: $e');
      return null;
    }
  }

  // Iniciar detección
  static Future<void> startDetection() async {
    _isDetecting = true;
    isDetectingNotifier.value = true;
    print('Detección iniciada');
  }

  // Parar detección
  static Future<void> stopDetection() async {
    _isDetecting = false;
    isDetectingNotifier.value = false;
    
    // Limpiar el caché de mensajes procesados
    _processedMessages.clear();
    
    print('Detección detenida y caché limpiado');
  }

  // Obtener token FCM
  // Actualizar mensaje con tiempo de detección
  static Future<void> _updateMessageWithDetectionTime(String messageId, double tiempoDeteccion) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _database
            .child('users')
            .child(user.uid)
            .child('detected_messages')
            .child(messageId)
            .update({'tiempo_deteccion': tiempoDeteccion});
        
        print('Tiempo de detección actualizado: ${tiempoDeteccion.toStringAsFixed(2)}s');
      }
    } catch (e) {
      print('Error al actualizar tiempo de detección: $e');
    }
  }

  static Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      print('Error al obtener token: $e');
      return null;
    }
  }
}

// Handler para mensajes en segundo plano
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Mensaje en segundo plano: ${message.messageId}');
  
  // Solo procesar si la detección está activa
  if (NotificationService.isDetecting) {
    await NotificationService.processMessage(message);
  }
}
