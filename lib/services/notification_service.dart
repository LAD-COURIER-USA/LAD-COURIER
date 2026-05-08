import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Plugin para disparar las alertas visuales y sonoras
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // 1. Pedir permisos (Android 13+ y S24)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('SISTEMA LAD: Permiso concedido.');

      // 2. CONFIGURACIÓN DEL CANAL (Bunker de sonido)
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel', // DEBE coincidir con el de la Cloud Function
        'Alertas de Pedidos Urgentes',
        description: 'Este canal se usa para notificaciones que deben sonar sí o sí.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      // Creamos el canal físicamente en el Android de Lucrecio
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 3. INICIALIZACIÓN DE NOTIFICACIONES LOCALES (Para primer plano)
      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _localNotifications.initialize(initializationSettings);

      // 4. EL ESCUCHA DE PRIMER PLANO (El que hace sonar el panel)
      // Este bloque captura el mensaje cuando Lucrecio tiene el panel abierto
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (notification != null && android != null) {
          debugPrint('SISTEMA LAD: Disparando alerta sonora en primer plano.');

          _localNotifications.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                importance: Importance.max,
                priority: Priority.high,
                icon: android.smallIcon ?? '@mipmap/ic_launcher',
                playSound: true,
              ),
            ),
          );
        }
      });

      // 5. Configuración global de Firebase
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      if (_auth.currentUser != null) {
        await saveTokenToDatabase();
      }

      _fcm.onTokenRefresh.listen((_) => saveTokenToDatabase());
      _auth.authStateChanges().listen((user) {
        if (user != null) saveTokenToDatabase();
      });
    }
  }

  Future<void> saveTokenToDatabase() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final String? token = await _fcm.getToken();
      if (token != null) {
        // 🛡️ SISTEMA LAD: Usamos set con merge:true para evitar errores de "documento no encontrado"
        // durante el registro de nuevos clientes.
        await _db.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('SISTEMA LAD: Token FCM guardado con éxito.');
      }
    } catch (e) {
      debugPrint('SISTEMA LAD ERROR: Error guardando token (No crítico): $e');
    }
  }
}