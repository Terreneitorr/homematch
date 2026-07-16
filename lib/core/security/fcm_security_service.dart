import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:homematch_ai/core/network/dio_client.dart';
import '../../../../core/network/dio_client.dart';
import 'secure_storage_service.dart';

// Handler para mensajes en background
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (message.data['action'] == 'REMOTE_WIPE') {
    await SecureStorageService.wipeAllData();
  }
}

class FcmSecurityService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize(BuildContext context) async {
    // Permisos
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Registrar handler de background
    FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler);

    // Obtener y registrar token en backend
    await _registerToken();

    // Escuchar cambios de token
    _messaging.onTokenRefresh.listen((_) => _registerToken());

    // Mensajes en primer plano
    FirebaseMessaging.onMessage.listen((message) {
      _handleMessage(message, context);
    });

    // App abierta desde notificación
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNavigation(message, context);
    });

    // App cerrada — abierta desde notificación
    final initial = await _messaging.getInitialMessage();
    if (initial != null && context.mounted) {
      _handleNavigation(initial, context);
    }
  }

  static Future<void> _registerToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await DioClient().dio.post('/fcm/register-token', data: {
          'token': token,
          'device': 'android',
        });
      }
    } catch (_) {}
  }

  static void _handleMessage(
      RemoteMessage message, BuildContext context) {
    final action = message.data['action'];

    if (action == 'REMOTE_WIPE') {
      _executeRemoteWipe(context);
      return;
    }

    // Mostrar snackbar para otras notificaciones
    if (context.mounted) {
      final notification = message.notification;
      if (notification != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(notification.body ?? ''),
              ],
            ),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Ver',
              onPressed: () => _handleNavigation(message, context),
            ),
          ),
        );
      }
    }
  }

  static void _handleNavigation(
      RemoteMessage message, BuildContext context) {
    final action = message.data['action'];
    if (!context.mounted) return;

    switch (action) {
      case 'OPEN_APPOINTMENTS':
        Navigator.pushNamed(context, '/appointments');
        break;
      case 'OPEN_CHAT':
        Navigator.pushNamed(context, '/chat');
        break;
      default:
        break;
    }
  }

  static Future<void> _executeRemoteWipe(BuildContext context) async {
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
                Icon(Icons.delete_forever,
                    color: theme.colorScheme.error),
                const SizedBox(width: 8),
                const Text('Datos eliminados'),
              ],
            ),
            content: const Text(
              'Se ejecutó una limpieza remota de seguridad. Todos los datos sensibles han sido eliminados.',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/', (r) => false);
                },
                child: const Text('Aceptar'),
              ),
            ],
          );
        },
      );
    }
  }
}