#!/usr/bin/env python3
"""
Script para enviar notificaciones de prueba a la aplicación TxtScan
"""

import requests
import json

# Token FCM de la aplicación (del log)
FCM_TOKEN = "cX0gmyGNTqGU_R6o7LYdkw:APA91bGnWiFJJoHCmWXxSRmWCOsL3nq4XG9tEeV6yIkk60LHZLO1iOPvBtLrPKtsdHbdAPvTOi1S8QxOh8GEavU21ttSggrx2f3IRoC8L5DEA"

# URL para enviar notificaciones (usando FCM Legacy API para simplificidad)
FCM_URL = "https://fcm.googleapis.com/fcm/send"

# Clave del servidor (deberías usar tu propia clave de Firebase)
SERVER_KEY = "YOUR_SERVER_KEY_HERE"

def send_test_notification(title, body, sender="test_sender"):
    """Envía una notificación de prueba"""
    
    headers = {
        'Authorization': f'key={SERVER_KEY}',
        'Content-Type': 'application/json'
    }
    
    payload = {
        "to": FCM_TOKEN,
        "notification": {
            "title": title,
            "body": body
        },
        "data": {
            "sender": sender,
            "messageType": "sms"
        }
    }
    
    try:
        response = requests.post(FCM_URL, headers=headers, json=payload)
        print(f"Respuesta del servidor: {response.status_code}")
        print(f"Contenido: {response.text}")
        return response.status_code == 200
    except Exception as e:
        print(f"Error enviando notificación: {e}")
        return False

if __name__ == "__main__":
    # Mensaje de prueba que podría ser considerado smishing
    test_messages = [
        {
            "title": "Banco Nacional",
            "body": "Su cuenta ha sido suspendida. Haga clic aquí para reactivarla: http://banco-falso.com",
            "sender": "+506-8888-9999"
        },
        {
            "title": "WhatsApp",
            "body": "Tienes un nuevo mensaje de María",
            "sender": "WhatsApp"
        }
    ]
    
    for i, msg in enumerate(test_messages, 1):
        print(f"\n--- Enviando mensaje de prueba {i} ---")
        print(f"Título: {msg['title']}")
        print(f"Cuerpo: {msg['body']}")
        success = send_test_notification(msg['title'], msg['body'], msg['sender'])
        if success:
            print("✅ Notificación enviada exitosamente")
        else:
            print("❌ Error enviando notificación")
