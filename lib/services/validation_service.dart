import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'navigation_service.dart';

class ValidationService {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  // Mostrar popup de validación al usuario
  static Future<void> showValidationDialog(
    String messageId,
    String messageBody,
    bool detectedAsSmishing,
  ) async {
    try {
      final result = await NavigationService.showCustomDialog<bool>(
        barrierDismissible: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                detectedAsSmishing ? Icons.warning : Icons.check_circle,
                color: detectedAsSmishing ? Colors.red : Colors.green,
                size: 28,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Validación de Detección',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mensaje capturado:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  messageBody,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                detectedAsSmishing 
                  ? '🔴 Detectado como SMISHING, ¿es correcto?'
                  : '🟢 Detectado como NO SMISHING, ¿es correcto?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: detectedAsSmishing ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(NavigationService.currentContext!).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
              ),
              child: const Text('NO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(NavigationService.currentContext!).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: detectedAsSmishing ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('SÍ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (result != null) {
        await _processValidation(messageId, detectedAsSmishing, result);
      }
    } catch (e) {
      print('Error al mostrar dialog de validación: $e');
    }
  }

  // Procesar la validación del usuario
  static Future<void> _processValidation(
    String messageId,
    bool detectedAsSmishing,
    bool userConfirms,
  ) async {
    String validationType;
    
    if (detectedAsSmishing && userConfirms) {
      // Sistema detectó smishing y usuario confirma = Verdadero Positivo
      validationType = 'VP';
    } else if (detectedAsSmishing && !userConfirms) {
      // Sistema detectó smishing pero usuario dice que no = Falso Positivo
      validationType = 'FP';
    } else if (!detectedAsSmishing && userConfirms) {
      // Sistema detectó no-smishing y usuario confirma = Verdadero Negativo
      validationType = 'VN';
    } else {
      // Sistema detectó no-smishing pero usuario dice que sí era = Falso Negativo
      validationType = 'FN';
    }

    // Actualizar en Firebase
    await _updateMessageValidation(messageId, validationType);
    
    print('Validación procesada: $validationType');
  }

  // Actualizar mensaje en Firebase con la validación
  static Future<void> _updateMessageValidation(String messageId, String validationType) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _database
            .child('users')
            .child(user.uid)
            .child('detected_messages')
            .child(messageId)
            .update({
          'validation_type': validationType,
          'validated_at': DateTime.now().millisecondsSinceEpoch,
        });
        
        print('Mensaje actualizado con validación: $validationType');
      }
    } catch (e) {
      print('Error al actualizar validación: $e');
    }
  }

  // Obtener descripción de la validación
  static String getValidationDescription(String validationType) {
    switch (validationType) {
      case 'VP':
        return 'Verdadero Positivo';
      case 'VN':
        return 'Verdadero Negativo';
      case 'FP':
        return 'Falso Positivo';
      case 'FN':
        return 'Falso Negativo';
      default:
        return 'Sin validar';
    }
  }

  // Obtener color para la validación
  static Color getValidationColor(String validationType) {
    switch (validationType) {
      case 'VP':
      case 'VN':
        return Colors.green; // Correctos
      case 'FP':
      case 'FN':
        return Colors.orange; // Incorrectos
      default:
        return Colors.grey; // Sin validar
    }
  }
}
