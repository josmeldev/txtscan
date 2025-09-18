// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'validation_service.dart';
import 'navigation_service.dart';

class NotificationService {
  // static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();
  static bool _isDetecting = false;
  static final ValueNotifier<bool> isDetectingNotifier = ValueNotifier<bool>(false);
  static bool _isInitialized = false; // Para evitar múltiples inicializaciones
  static final Set<String> _processedMessages = <String>{}; // Para evitar duplicados

  static bool get isDetecting => _isDetecting;

  // Inicializar el servicio de notificaciones locales (SMS)
  static Future<void> initialize() async {
    if (_isInitialized) {
      print('NotificationService ya está inicializado');
      return;
    }
    // Aquí podrías inicializar el listener de notificaciones locales si es necesario
    _isInitialized = true;
    print('NotificationService inicializado correctamente (modo SMS local)');
  }

  // Procesar notificación local de SMS (title, body)
  static Future<void> processSMSNotification({required String title, required String body}) async {
    if (!_isDetecting) return;

    // Crear un ID único para el mensaje
    final messageId = '${title}_${body}_${DateTime.now().millisecondsSinceEpoch}';

    // Verificar si ya procesamos este mensaje
    if (_processedMessages.contains(messageId)) {
      print('Mensaje SMS ya procesado, ignorando duplicado: $messageId');
      return;
    }

    print('Procesando SMS: $title');
    print('Cuerpo: $body');
    print('Message ID: $messageId');

    // Marcar como procesado
    _processedMessages.add(messageId);

    final messageText = body;

    // Iniciar medición del tiempo de detección
    final startTime = DateTime.now();

    // Analizar con la API de smishing
    print('Analizando SMS con API...');
    final apiResult = await _analyzeWithAPI(messageText);

    // Crear datos del mensaje (sin tiempo_deteccion aún)
    final messageData = {
      'title': title,
      'body': messageText,
      'es_smishing': apiResult['isMalicious'],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    print('Resultado del análisis: ${apiResult['isMalicious'] ? 'SMISHING' : 'SEGURO'}');

    // Guardar en Firebase
    final savedMessageId = await _saveMessage(messageData);

    // Mostrar popup de validación si se guardó correctamente
    if (savedMessageId != null) {
      await Future.delayed(const Duration(milliseconds: 500));
      try {
        final endTime = DateTime.now();
        final tiempoDeteccionMs = endTime.difference(startTime).inMilliseconds;
        final tiempoDeteccion = tiempoDeteccionMs / 1000.0;

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
      print('Iniciando análisis con API...');
      final url = Uri.parse('https://txtscan-api.onrender.com/predict');
      Timer? slowResponseTimer;
      bool isSlowResponse = false;
      slowResponseTimer = Timer(const Duration(seconds: 7), () {
        isSlowResponse = true;
        print('API tardando más de lo normal - mostrando mensaje informativo');
        _showServiceActivatingMessage();
      });
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'texto': messageText,
        }),
      ).timeout(const Duration(seconds: 32));
      slowResponseTimer.cancel();
      if (isSlowResponse) {
        _hideServiceActivatingMessage();
      }
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
      _hideServiceActivatingMessage();
      return {
        'isAnalyzed': false,
        'isMalicious': false,
        'error': e.toString(),
      };
    }
  }

  // Mostrar mensaje de "Servicio activándose"
  static void _showServiceActivatingMessage() {
    final context = NavigationService.navigatorKey.currentContext;
    if (context != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text(
                  'El servicio se está activando',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Por favor espera un momento...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  // Ocultar mensaje de "Servicio activándose"
  static void _hideServiceActivatingMessage() {
    final context = NavigationService.navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context, rootNavigator: true).pop();
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
    print('Detección de SMS iniciada');
  }

  // Parar detección
  static Future<void> stopDetection() async {
    _isDetecting = false;
    isDetectingNotifier.value = false;
    _processedMessages.clear();
    print('Detección de SMS detenida y caché limpiado');
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

  // El método getToken y el handler de mensajes en segundo plano se eliminan porque ya no se usan Firebase Messaging
}
