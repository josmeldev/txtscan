import 'package:flutter/material.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart' show NotificationsListener, NotificationEvent;
import 'dart:async';
import 'dart:isolate';
import '../services/notification_service.dart'; 
  
  
  
  





@pragma('vm:entry-point')
class SMSListenerService {
  static Future<void> ensureNotificationPermission() async {
    final hasPermission = await NotificationsListener.hasPermission;
    if (hasPermission == null || !hasPermission) {
      print('[SMSListenerService] Solicitando permiso de acceso a notificaciones...');
      await NotificationsListener.openPermissionSettings();
    }
  }
  static final ValueNotifier<Map<String, String>?> lastSmsNotifier = ValueNotifier(null);
  static bool _isStarted = false;
  static StreamSubscription? _subscription;

  @pragma('vm:entry-point')
  static void _callback(NotificationEvent event) {
    print('[SMSListenerService] [CALLBACK] Evento recibido: $event');
    if (event.packageName == 'com.google.android.apps.messaging') {
      final title = event.title ?? '';
      final body = event.text ?? '';
      final isNumericTitle = RegExp(r'^\d{5,}$').hasMatch(title); // 5+ dígitos
      final isSystemMsg = title.toLowerCase().contains('messages') ||
                         title.toLowerCase().contains('background') ||
                         body.toLowerCase().contains('background');
      if (isNumericTitle && body.isNotEmpty && !isSystemMsg) {
        lastSmsNotifier.value = {'title': title, 'body': body};
        NotificationService.processSMSNotification(title: title, body: body);
      }
    }
  // Enviar a UI si es necesario
  // final send = IsolateNameServer.lookupPortByName("_listener_");
  // send?.send(event);
  }

  static Future<void> start() async {
    if (_isStarted) return;
    _isStarted = true;
    await NotificationsListener.initialize(callbackHandle: _callback);
    await NotificationsListener.startService();
    _subscription = NotificationsListener.receivePort?.listen((event) {
      print('[SMSListenerService] Evento recibido en UI: $event');
      if (event is NotificationEvent && event.packageName == 'com.google.android.apps.messaging') {
        final title = event.title ?? '';
        final body = event.text ?? '';
        final isNumericTitle = RegExp(r'^\d{5,}$').hasMatch(title); // 5+ dígitos
        final isSystemMsg = title.toLowerCase().contains('messages') ||
                           title.toLowerCase().contains('background') ||
                           body.toLowerCase().contains('background');
        if (isNumericTitle && body.isNotEmpty && !isSystemMsg) {
          print('[SMSListenerService] Notificación detectada: title="$title" body="$body" package=${event.packageName}');
          lastSmsNotifier.value = {'title': title, 'body': body};
          NotificationService.processSMSNotification(title: title, body: body);
        }
      }
    });
    print('SMSListenerService (flutter_notification_listener) iniciado');
  }

  static Future<void> stop() async {
    _isStarted = false;
    await NotificationsListener.stopService();
    await _subscription?.cancel();
    print('SMSListenerService detenido');
  }
}
