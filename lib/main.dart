import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Para kDebugMode
import 'package:flutter/services.dart'; // PARA EL PORTAPAPELES
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_stripe/flutter_stripe.dart'; // IMPORTACIÓN DE STRIPE
import 'package:firebase_app_check/firebase_app_check.dart'; // IMPORTACIÓN DE APP CHECK

// --- IMPORTACIÓN DE TRADUCCIONES ---
import 'l10n/app_localizations.dart';

import 'package:lad_courier/firebase_options.dart';
import 'package:lad_courier/auth/auth_gate.dart';
import 'package:lad_courier/auth_service.dart';
import 'package:lad_courier/services/billing_service.dart';
import 'package:lad_courier/widgets/invitation_card.dart';
import 'package:lad_courier/services/user_service.dart';
import 'package:lad_courier/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. INICIALIZACIÓN DE FIREBASE CON VÁLVULA DE SEGURIDAD
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 2. ACTIVACIÓN DE APP CHECK (SEGURIDAD DINÁMICA)
    // Usamos debugProvider en modo debug para desarrollo fluido.
    // En Release usamos playIntegrity, pero con try-catch para evitar el "freeze" si Google rechaza la firma.
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity, 
      appleProvider: AppleProvider.deviceCheck,
    );
    debugPrint("✅ SISTEMA LAD: Firebase y App Check configurados.");
  } catch (e) {
    debugPrint("⚠️ SISTEMA LAD: Error no crítico en inicio de Firebase: $e");
    // Permitimos que la App siga adelante para evitar el bloqueo en el Splash Screen.
  }

  // 3. INICIALIZACIÓN DE STRIPE (LAD DIGITAL SYSTEMS LLC)
  Stripe.publishableKey = "pk_test_51TMuNS2NOyx7kZidWtT02onQS0ky0YgHh0oaJWIeqt73t5x5II3ldBrjTZUDxdimLmqEk0jwJmjl8IwwYNEfw3sX00bEH0A7Pe";
  await Stripe.instance.applySettings();

  final notificationService = NotificationService();
  await notificationService.initialize();

  final billingService = BillingService();
  billingService.initialize();

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<BillingService>(
          create: (_) => billingService,
          dispose: (_, service) => service.dispose(),
        ),
        Provider<UserService>(create: (_) => UserService()),
        Provider<NotificationService>.value(value: notificationService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _appLinks = AppLinks();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  // ✨ SISTEMA LAD: Variable volátil para controlar el portapapeles por sesión 
  // (No se guarda en SharedPreferences para que se resetee al cerrar la App)
  bool _clipboardCheckedThisSession = false;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() async {
    _appLinks.uriLinkStream.listen((uri) {
      debugPrint('[AUDITORÍA REGRESO] Link detectado en Stream: $uri');
      _handleInvitation(uri);
    });

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('[AUDITORÍA REGRESO] App abierta por link inicial: $initialUri');
        _handleInvitation(initialUri);
      } else {
        // --- RESCATE DE REFERIDO VIA PORTAPAPELES (Para instalaciones desde APK) ---
        _checkClipboardForReferral();
      }
    } catch (e) {
      debugPrint('SISTEMA LAD: Error capturando link inicial: $e');
    }
  }

  /// Revisa si el usuario trae un ID en el portapapeles desde la landing page
  void _checkClipboardForReferral() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 🛡️ SISTEMA LAD: No molestamos si:
      // 1. Ya hay una invitación aceptada o pendiente en pantalla.
      // 2. Ya revisamos el portapapeles en esta ejecución de la App.
      if (prefs.containsKey('pending_messenger_invitation')) return;
      if (_clipboardCheckedThisSession) return;

      _clipboardCheckedThisSession = true;

      final data = await Clipboard.getData(Clipboard.kTextPlain);
      String? text = data?.text?.trim();

      if (text != null && text.isNotEmpty) {
        // Solo procesamos si el texto ha cambiado desde la última vez que tuvo éxito
        String? lastProcessed = prefs.getString('last_clipboard_processed');
        if (text == lastProcessed) return;

        String? driverId;
        if (text.contains('ref=')) {
          driverId = text.split('ref=').last.trim();
          if (driverId.length < 20 || driverId.length > 50) driverId = null;
        }

        if (driverId != null) {
          if (prefs.getBool('referral_rejected_$driverId') == true) return;

          debugPrint('SISTEMA LAD: Nuevo referido detectado en portapapeles -> $driverId');
          await prefs.setString('last_clipboard_processed', text);
          _processReferralId(driverId);
        }
      }
    } catch (e) {
      debugPrint('SISTEMA LAD: Error leyendo portapapeles: $e');
    }
  }

  void _handleInvitation(Uri uri) async {
    String? referrerId = uri.queryParameters['ref'] ?? uri.queryParameters['id'];

    if (referrerId == null || referrerId.isEmpty) {
      String fullUrl = uri.toString();
      if (fullUrl.contains('ref=')) {
        referrerId = fullUrl.split('ref=').last.split('&').first.split('/').first;
      } else if (fullUrl.contains('id=')) {
        referrerId = fullUrl.split('id=').last.split('&').first.split('/').first;
      }
    }

    if (referrerId != null && referrerId.isNotEmpty) {
      _processReferralId(referrerId);
    }
  }

  /// Lógica común para procesar el ID del Driver (venga de Link o Portapapeles)
  void _processReferralId(String driverId) async {
    debugPrint('SISTEMA LAD: Procesando vinculación con Driver -> $driverId');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pending_messenger_invitation', driverId);

    if (FirebaseAuth.instance.currentUser != null) {
      Future.delayed(const Duration(seconds: 3), () {
        _showInvitationDialog(driverId);
      });
    }
  }

  void _showInvitationDialog(String driverId) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(dialogContext)!;

        return InvitationCard(
          messengerId: driverId,
          onAccept: () async {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser == null) {
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              return;
            }

            try {
              final batch = FirebaseFirestore.instance.batch();
              final clientRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
              final messengerRef = FirebaseFirestore.instance.collection('users').doc(driverId);

              // 🛡️ SISTEMA LAD: Cambiamos update por set con merge para evitar el error "not-found"
              batch.set(clientRef, {
                'invitingMessengerId': driverId,
                'linkedMessengerIds': FieldValue.arrayUnion([driverId]),
              }, SetOptions(merge: true));

              batch.set(messengerRef, {
                'linkedClientIds': FieldValue.arrayUnion([currentUser.uid]),
              }, SetOptions(merge: true));

              await batch.commit();

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("✅ ${l10n.client_prof_update_success}"),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              debugPrint("SISTEMA LAD ERROR: $e");
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text("❌ ${l10n.client_prof_update_error(e.toString())}"),
                      backgroundColor: Colors.red
                  ),
                );
              }
            }
          },
          onReject: () {
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'LAD Courier',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      // ✨ SISTEMA LAD: Definimos rutas para permitir navegación forzada desde el registro
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
      },
    );
  }
}
