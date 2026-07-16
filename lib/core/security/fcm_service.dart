import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'remote_wipe_service.dart';
import 'dart:developer' as developer;

/// Manejador de mensajes en segundo plano.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  developer.log('Mensaje recibido en segundo plano: ${message.messageId}', name: 'FcmService');
  await FcmService.processMessage(message);
}

class FcmService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  
  // Stream para que la UI reaccione al wipe
  static final _wipeController = StreamController<bool>.broadcast();
  static Stream<bool> get onWipeStream => _wipeController.stream;

  Future<void> initialize() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      developer.log('Permisos de notificaciones concedidos.', name: 'FcmService');
    }

    String? token = await _fcm.getToken();
    developer.log('FCM Token: $token', name: 'FcmService');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log('Mensaje recibido en primer plano: ${message.messageId}', name: 'FcmService');
      processMessage(message);
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log('App abierta desde notificación: ${message.messageId}', name: 'FcmService');
      processMessage(message);
    });
  }

  static Future<void> processMessage(RemoteMessage message) async {
    final data = message.data;
    
    if (data['action'] == 'wipe_remote') {
      developer.log('Comando de Wipe Remoto detectado!', name: 'FcmService');
      await RemoteWipeService.performWipe();
      _wipeController.add(true);
    }
  }
  
  void dispose() {
    // Nota: El controller es estático en este caso para persistir entre estados si es necesario,
    // pero si se instanciara por app se cerraría aquí.
  }
}
