import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  // 🛡️ REFUERZO V18.7: Instanciación bajo demanda para evitar crash en Web
  FlutterLocalNotificationsPlugin? _localNotifications;

  Future<void> initialize() async {
    // 🛡️ REFUERZO WEB (iPad/iPhone): Safari no soporta notificaciones locales
    // de la misma forma que Android. Saltamos para evitar PlatformException.
    if (kIsWeb) {
      debugPrint('SISTEMA LAD: Notificaciones en Web - Modo Pasivo.');
      return;
    }

    _localNotifications = FlutterLocalNotificationsPlugin();

    // 1. Pedir permisos (Android 13+ y S24)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('SISTEMA LAD: Permiso de notificaciones concedido.');

      // 2. CONFIGURACIÓN DEL CANAL
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'Alertas de Pedidos Urgentes',
        description: 'Canal para misiones críticas.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications!
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 3. INICIALIZACIÓN UNIVERSAL (V19.11)
      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _localNotifications!.initialize(initializationSettings);

      // 4. ESCUCHA DE PRIMER PLANO
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        RemoteNotification? notification = message.notification;
        
        if (notification != null && _localNotifications != null) {
          // Detalles Android
          AndroidNotificationDetails? androidDetails;
          if (message.notification?.android != null) {
            androidDetails = AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              importance: Importance.max,
              priority: Priority.high,
              icon: message.notification?.android?.smallIcon ?? '@mipmap/ic_launcher',
            );
          }

          // Detalles iOS (Darwin)
          const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          );

          _localNotifications!.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: androidDetails,
              iOS: darwinDetails,
            ),
          );
        }
      });

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
    if (user == null || kIsWeb) return;
    try {
      final String? token = await _fcm.getToken();
      if (token != null) {
        await _db.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('SISTEMA LAD: Error token: $e');
    }
  }
}
