import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class DetectScreen extends StatefulWidget {
  const DetectScreen({super.key});

  @override
  State<DetectScreen> createState() => _DetectScreenState();
}

class _DetectScreenState extends State<DetectScreen> {

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await NotificationService.initialize();
  }

  Future<void> _toggleDetection() async {
    final currentState = NotificationService.isDetectingNotifier.value;
    
    if (currentState) {
      await NotificationService.stopDetection();
      _showSnackBar('Detección detenida.');
    } else {
      await NotificationService.startDetection();
      _showSnackBar('Detección iniciada. Los mensajes serán capturados.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detectar', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0D1A2A),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Círculo que cambia entre INICIAR y PARAR usando ValueListenableBuilder
            ValueListenableBuilder<bool>(
              valueListenable: NotificationService.isDetectingNotifier,
              builder: (context, isDetecting, child) {
                return GestureDetector(
                  onTap: _toggleDetection,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: isDetecting ? Colors.red : const Color(0xFF005AA3),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isDetecting ? Colors.red : const Color(0xFF005AA3)).withOpacity(0.3),
                          spreadRadius: 5,
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        isDetecting ? 'PARAR' : 'INICIAR',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            // Mensaje debajo del botón
            ValueListenableBuilder<bool>(
              valueListenable: NotificationService.isDetectingNotifier,
              builder: (context, isDetecting, child) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    isDetecting 
                      ? 'Detección activa. Los mensajes se guardarán en Resultados.'
                      : 'Presiona INICIAR para comenzar a capturar mensajes de notificaciones.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: isDetecting ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            // Indicador de estado
            ValueListenableBuilder<bool>(
              valueListenable: NotificationService.isDetectingNotifier,
              builder: (context, isDetecting, child) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDetecting ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDetecting ? Colors.green : Colors.grey,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDetecting ? Icons.shield_outlined : Icons.shield,
                        color: isDetecting ? Colors.green : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isDetecting ? 'CAPTURA ACTIVA' : 'CAPTURA INACTIVA',
                        style: TextStyle(
                          color: isDetecting ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
