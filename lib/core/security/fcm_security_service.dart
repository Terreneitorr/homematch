import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'secure_storage_service.dart';

class FcmSecurityService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize(BuildContext context) async {
    // Solicitar permisos
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Escuchar mensajes en primer plano
    FirebaseMessaging.onMessage.listen((message) {
      _handleSecurityMessage(message, context);
    });

    // Escuchar cuando la app se abre desde notificación
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleSecurityMessage(message, context);
    });

    // Mensaje inicial si la app estaba cerrada
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _handleSecurityMessage(initial, context);
    }
  }

  static void _handleSecurityMessage(
      RemoteMessage message, BuildContext context) {
    final data = message.data;

    // Verificar si es un wipe remoto
    if (data['action'] == 'REMOTE_WIPE') {
      _executeRemoteWipe(context);
    }
  }

  static Future<void> _executeRemoteWipe(BuildContext context) async {
    // Limpiar todos los datos sensibles
    await SecureStorageService.wipeAllData();

    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          final theme = Theme.of(context);
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.delete_forever, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                const Text('Datos eliminados'),
              ],
            ),
            content: const Text(
              'Se ha ejecutado una limpieza remota de seguridad. Todos los datos sensibles han sido eliminados del dispositivo.',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                        (route) => false,
                  );
                },
                child: const Text('Aceptar'),
              ),
            ],
          );
        },
      );
    }
  }

  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}