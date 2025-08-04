import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

    // Solicitar permisos
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Usuario otorgó permisos para notificaciones');
    } else {
      print('Usuario no otorgó permisos para notificaciones');
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
    
    // Crear datos del mensaje
    final messageData = {
      'messageId': messageId,
      'title': message.notification?.title ?? 'Sin título',
      'body': message.notification?.body ?? 'Sin contenido',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'sender': message.from ?? 'Desconocido',
      'isAnalyzed': false,
      'isMalicious': false, // Por defecto false, se analizará con la API después
    };

    // Guardar en Firebase
    await _saveMessage(messageData);
  }

  // Guardar mensaje en Firebase
  static Future<void> _saveMessage(Map<String, dynamic> messageData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _database
            .child('users')
            .child(user.uid)
            .child('detected_messages')
            .push()
            .set(messageData);
        
        print('Mensaje guardado en Firebase');
      }
    } catch (e) {
      print('Error al guardar mensaje: $e');
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
