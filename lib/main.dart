import 'dart:async';
import 'dart:convert'; // 🛡️ IMPORTACIÓN PARA PUENTE SMART SHOPPER
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // IMPORTACIÓN PARA kDebugMode
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
import 'package:lad_courier/pages/client/create_order_page.dart'; // 🛡️ IMPORTACIÓN PARA NAVEGACIÓN DIRECTA

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. INICIALIZACIÓN DE FIREBASE CON VÁLVULA DE SEGURIDAD
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 2. ACTIVACIÓN DE APP CHECK (SEGURIDAD DINÁMICA)
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity, 
      appleProvider: AppleProvider.deviceCheck,
    );
    debugPrint("✅ SISTEMA LAD: Firebase y App Check configurados.");
  } catch (e) {
    debugPrint("⚠️ SISTEMA LAD: Error no crítico en inicio de Firebase: $e");
  }

  // 3. INICIALIZACIÓN DE STRIPE (LAD DIGITAL SYSTEMS LLC)
  Stripe.publishableKey = "pk_test_51TMuNS2NOyx7kZidWtT02onQS0ky0YgHh0oaJWIeqt73t5x5II3ldBrjTZUDxdimLmqEk0jwJmjl8IwwYNEfw3sX00bEH0A7Pe";
  await Stripe.instance.applySettings();

  final notificationService = NotificationService();
  // 🛡️ SISTEMA LAD: No usamos 'await' aquí para evitar el bloqueo del Splash Screen.
  // El servicio se inicializa en segundo plano mientras la App arranca.
  notificationService.initialize();

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
  
  bool _clipboardCheckedThisSession = false;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    _listenToAuthChanges(); 
    
    // 🚀 BINGO: ESCUCHA DE NOTIFICACIÓN NATIVA
    // Cuando la App vuelve al frente, chequeamos si hay una captura pendiente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfReturningFromBingo();
    });
  }

  void _checkIfReturningFromBingo() async {
    // 🛡️ REFUERZO: En Android 14 el Intent ya trae la orden, no necesitamos SharedPreferences
  }

  /// Vigilancia constante: En cuanto el usuario se loguea, soltamos la invitación pendiente
  void _listenToAuthChanges() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        final pendingId = prefs.getString('pending_messenger_invitation');
        
        if (pendingId != null && pendingId.isNotEmpty) {
          // 🛡️ SISTEMA LAD: Limpieza de emergencia si el ID parece un token técnico (contiene guiones)
          if (pendingId.contains('-')) {
            await prefs.remove('pending_messenger_invitation');
            debugPrint('SISTEMA LAD: Invitación técnica (token) eliminada automáticamente.');
            return;
          }

          debugPrint('SISTEMA LAD: Detectada invitación pendiente al iniciar sesión -> $pendingId');
          // Esperamos a que la App se dibuje
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showInvitationDialog(pendingId);
          });
        }
      }
    });
  }

  void _initDeepLinks() async {
    _appLinks.uriLinkStream.listen((uri) {
      debugPrint('[AUDITORÍA REGRESO] Link detectado en Stream: $uri');
      _handleIncomingUri(uri); // 🔄 RENOMBRADO PARA GENERALIZAR
    });

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('[AUDITORÍA REGRESO] App abierta por link inicial: $initialUri');
        _handleIncomingUri(initialUri);
      } else {
        // --- RESCATE DE REFERIDO O PEDIDO VIA PORTAPAPELES ---
        _checkClipboardForReferral();
      }
    } catch (e) {
      debugPrint('SISTEMA LAD: Error capturando link inicial: $e');
    }
  }

  /// Revisa si el usuario trae un ID o un Pedido de Smart Shopper en el portapapeles
  void _checkClipboardForReferral() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (prefs.containsKey('pending_messenger_invitation')) return;
      if (_clipboardCheckedThisSession) return;

      _clipboardCheckedThisSession = true;

      final data = await Clipboard.getData(Clipboard.kTextPlain);
      String? text = data?.text?.trim();

      if (text != null && text.isNotEmpty) {
        // 🚀 PUENTE SMART SHOPPER: Detectar si es un objeto JSON de orden
        if (text.startsWith('{') && text.endsWith('}')) {
          try {
            final Map<String, dynamic> jsonData = json.decode(text);
            if (jsonData['type'] == 'LAD_ORDER') {
              debugPrint('SISTEMA LAD: Pedido rescatado desde portapapeles (Smart Shopper)');
              _navigateToCreateOrder(Map<String, dynamic>.from(jsonData['data']));
              return;
            }
          } catch (_) {}
        }

        String? driverId;
        final String cleanText = text.trim();

        // 🧠 FILTRO DE ADN LAD (Extractor de Precisión)
        if (cleanText.contains('id=')) {
          final String afterId = cleanText.split('id=').last;
          // Solo capturamos caracteres alfanuméricos inmediatamente después de 'id='
          final match = RegExp(r'^([a-zA-Z0-9]+)').firstMatch(afterId);
          if (match != null) {
            final String potentialId = match.group(1)!;
            // Un ID de Firebase tiene usualmente 28 caracteres. Filtramos basura corta (como '808')
            if (potentialId.length >= 20 && potentialId.length <= 40) {
              driverId = potentialId;
            }
          }
        } else if (cleanText.length >= 20 && cleanText.length <= 40 && RegExp(r'^[a-zA-Z0-9]+$').hasMatch(cleanText)) {
          driverId = cleanText;
        }

        if (driverId != null && driverId.isNotEmpty) {
          // 🛡️ SISTEMA LAD: No molestamos si el driver ya fue procesado (Aceptado o Rechazado)
          if (prefs.getBool('referral_rejected_$driverId') == true) return;
          if (prefs.getBool('referral_accepted_$driverId') == true) return;

          debugPrint('SISTEMA LAD: Rescate exitoso del portapapeles -> $driverId');
          _processReferralId(driverId);
        }
      }
    } catch (e) {
      debugPrint('SISTEMA LAD ERROR [Clipboard]: $e');
    }
  }

  void _handleIncomingUri(Uri uri) async {
    debugPrint('SISTEMA LAD: Analizando URI entrante -> $uri');
    
    // 🚀 CASO A: Deep Link de Creación de Orden (desde Smart Shopper)
    if (uri.host == 'create_order') {
      final params = uri.queryParameters;
      _navigateToCreateOrder({
        'name': params['name'],
        'address': params['address'],
        'lat': params['lat'],
        'lon': params['lon'],
        'storeId': params['storeId'],
        'details': params['details'], // 🚀 DETALLES DEL TICKET OCR
      });
      return;
    }

    // 🚀 CASO B: Invitación de Driver (Lógica original)
    String? referrerId = uri.queryParameters['id'] ?? uri.queryParameters['ref'];

    if (referrerId == null || referrerId.isEmpty) {
      String fullUrl = uri.toString();
      if (fullUrl.contains('id=')) {
        referrerId = fullUrl.split('id=').last.split('&').first.trim();
      } else if (fullUrl.contains('ref=')) {
        referrerId = fullUrl.split('ref=').last.split('&').first.trim();
      }
    }

    if (referrerId != null && referrerId.isNotEmpty) {
      debugPrint('SISTEMA LAD: Invitación capturada vía Link -> $referrerId');
      
      // 🚀 SEGUNDA OPORTUNIDAD: Si el usuario pulsa un link/QR manualmente, 
      // limpiamos cualquier rechazo previo de este driver para permitirle re-intentar.
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('referral_rejected_$referrerId') == true) {
        await prefs.remove('referral_rejected_$referrerId');
        debugPrint('SISTEMA LAD: Rechazo previo limpiado por nueva acción de link.');
      }

      _processReferralId(referrerId);
    }
  }

  void _navigateToCreateOrder(Map<String, dynamic> orderData) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateOrderPage(bridgeData: orderData),
          ),
        );
      }
    });
  }

  /// Lógica común para procesar el ID del Driver (venga de Link o Portapapeles)
  void _processReferralId(String driverId) async {
    debugPrint('SISTEMA LAD: Procesando vinculación con Driver -> $driverId');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pending_messenger_invitation', driverId);

    if (FirebaseAuth.instance.currentUser != null) {
      // 🛡️ SISTEMA LAD: Usamos addPostFrameCallback para asegurar que el contexto sea válido
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showInvitationDialog(driverId);
      });
    }
  }

  void _showInvitationDialog(String driverId) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    // 🛡️ SISTEMA LAD: Sensor de Identidad. 
    // Si el Driver intenta invitarse a sí mismo, ignoramos la invitación para evitar bloqueos.
    if (currentUser != null && currentUser.uid == driverId) {
      debugPrint('SISTEMA LAD: Auto-invitación detectada. Ignorando diálogo.');
      return;
    }

    final context = navigatorKey.currentContext;
    if (context == null) {
      Future.delayed(const Duration(seconds: 1), () => _showInvitationDialog(driverId));
      return;
    }

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

              batch.set(clientRef, {
                'invitingMessengerId': driverId,
                'linkedMessengerIds': FieldValue.arrayUnion([driverId]),
              }, SetOptions(merge: true));

              batch.set(messengerRef, {
                'linkedClientIds': FieldValue.arrayUnion([currentUser.uid]),
              }, SetOptions(merge: true));

              await batch.commit();
              
              // 🛡️ SISTEMA LAD: Limpiamos la memoria interna tras el éxito
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('pending_messenger_invitation');
              await prefs.setBool('referral_accepted_$driverId', true); // Marcar como aceptado para no repetir

              // 🔄 REFREZCO AUTOMÁTICO: Notificamos a la App que el perfil cambió
              // Esto hace que el Dashboard se entere y muestre al driver de inmediato.
              FirebaseAuth.instance.currentUser?.reload();

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
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            }
          },
          onReject: () async {
            // 🛡️ SISTEMA LAD: También limpiamos la memoria si el usuario rechaza
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('pending_messenger_invitation');
            await prefs.setBool('referral_rejected_$driverId', true);

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
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
      },
    );
  }
}
