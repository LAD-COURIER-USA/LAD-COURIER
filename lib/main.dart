import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'l10n/app_localizations.dart';
import 'package:lad_courier/firebase_options.dart';
import 'package:lad_courier/auth/auth_gate.dart';
import 'package:lad_courier/auth_service.dart';
import 'package:lad_courier/services/billing_service.dart';
import 'package:lad_courier/widgets/invitation_card.dart';
import 'package:lad_courier/services/user_service.dart';
import 'package:lad_courier/services/notification_service.dart';
import 'package:lad_courier/services/stripe_mode_service.dart';
import 'package:image_picker/image_picker.dart'; // 🚀 PARA MANEJO DE IMÁGENES BINGO
import 'package:lad_courier/pages/client/create_order_page.dart'; // 🚀 PARA NAVEGACIÓN AUTOMÁTICA
import 'package:universal_html/html.dart' as html; // 🌐 PARA LEER URL EN IPAD/WEB

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint("🎯 BINGO DEBUG: Inicio de main()");
  
  NotificationService? notificationService;
  final billingService = BillingService();

  // 🛡️ REFUERZO V19.0: Arranque Inmune a Plataformas
  try {
    debugPrint("🎯 BINGO DEBUG: Inicializando Firebase...");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 15));

    // 🌐 WEB-FIRST: En web saltamos todo lo que use Platform._operatingSystem
    if (!kIsWeb) {
      debugPrint("🎯 BINGO DEBUG: Activando App Check (Nativo)...");
      try {
        await FirebaseAppCheck.instance.activate(
          androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity, 
          appleProvider: AppleProvider.deviceCheck,
        );
      } catch (e) {
        debugPrint("🛡️ SISTEMA LAD: App Check omitido.");
      }
    }

    debugPrint("🎯 BINGO DEBUG: Inicializando NotificationService...");
    notificationService = NotificationService();
    if (!kIsWeb) {
      await notificationService.initialize();
    } else {
      notificationService.initialize(); // Modo pasivo
    }
    
    debugPrint("🎯 BINGO DEBUG: Inicializando BillingService...");
    billingService.initialize();

    debugPrint("🎯 BINGO DEBUG: Inicializando StripeModeService...");
    final stripeModeService = StripeModeService();
    await stripeModeService.initialize();

    debugPrint("🎯 BINGO DEBUG: Configurando Stripe Key...");
    String pk = "pk_test_51TMuNS2NOyx7kZidWtT02onQS0ky0YgHh0oaJWIeqt73t5x5II3ldBrjTZUDxdimLmqEk0jwJmjl8IwwYNEfw3sX00bEH0A7Pe";
    
    try {
      final configDoc = await FirebaseFirestore.instance.collection('admin_settings').doc('stripe').get();
      if (configDoc.exists) {
        final data = configDoc.data();
        if (data != null) {
          final String mode = data['stripe_mode'] ?? 'test';
          final String? livePk = data['pk_live'];
          final String? testPk = data['pk_test'];
          pk = (mode == 'live' ? livePk : testPk) ?? pk;
        }
      }
    } catch (_) {}

    // 🛡️ REFUERZO V19.0: Inicialización de Stripe Silenciosa en Web
    try {
      debugPrint("🎯 BINGO DEBUG: Aplicando publishableKey...");
      Stripe.publishableKey = pk.trim();
      if (!kIsWeb) {
        debugPrint("🎯 BINGO DEBUG: Aplicando applySettings (Nativo)...");
        await Stripe.instance.applySettings();
      }
    } catch (stripeError) {
      debugPrint("🛡️ SISTEMA LAD: Error Stripe (No fatal): $stripeError");
    }

  } catch (e) {
    debugPrint("⚠️ SISTEMA LAD: Error crítico en arranque: $e");
  }

  debugPrint("🎯 BINGO DEBUG: Ejecutando runApp()");

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<BillingService>(
          create: (_) => billingService,
          dispose: (_, service) => service.dispose(),
        ),
        Provider<UserService>(create: (_) => UserService()),
        if (notificationService != null)
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
  AppLinks? _appLinks;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static const _screenshotChannel = MethodChannel('com.laddigital.smartshopper/screenshot');

  @override
  void initState() {
    super.initState();
    // 🛡️ REFUERZO V19.0: Blindaje total de enlaces profundos
    if (kIsWeb) {
      _checkWebUrlParameters(); // 🚀 BINGO: Detecta invitaciones en iPad/Navegador
    } else {
      try {
        _appLinks = AppLinks();
        _initDeepLinks();
        _initSharedImageListener(); // 🚀 ESCUCHA GLOBAL DE BINGO
      } catch (_) {}
    }
    _listenToAuthChanges(); 
  }

  void _checkWebUrlParameters() {
    // 🌐 REFUERZO V2026: Lectura de espectro completo de la URL
    try {
      final String fullUrl = html.window.location.href;
      debugPrint("SISTEMA LAD DEBUG: Escaneando URL Web -> $fullUrl");

      String? driverId;

      // 🕵️ MOTOR DE BÚSQUEDA SOBERANO (Busca id= o ref= en toda la cadena)
      final regExp = RegExp(r'[?&](id|ref)=([^&#/]+)');
      final match = regExp.firstMatch(fullUrl);
      
      if (match != null) {
        driverId = match.group(2);
      }

      // Respaldo: Memoria del Navegador y Cookies
      if (driverId == null || driverId.isEmpty) {
        driverId = html.window.localStorage['pending_messenger_invitation'] ?? html.window.localStorage['pending_id'];
        
        if (driverId == null || driverId.isEmpty) {
          final String cookies = html.document.cookie ?? "";
          final List<String> cookieList = cookies.split(';');
          for (var cookie in cookieList) {
            if (cookie.trim().startsWith('pending_messenger_invitation=')) {
              driverId = cookie.split('=')[1].trim();
              break;
            }
          }
        }
      }

      if (driverId != null && driverId.trim().isNotEmpty) {
        final String cleanId = driverId.trim();
        debugPrint("SISTEMA LAD WEB: ¡ID PESCADO! -> $cleanId");
        
        // Guardamos para el registro
        html.window.localStorage['pending_messenger_invitation'] = cleanId;
        _processReferralId(cleanId);
      }
    } catch (e) {
      debugPrint("SISTEMA LAD ERROR: Fallo en radar de URL: $e");
    }
  }

  void _initSharedImageListener() {
    _screenshotChannel.setMethodCallHandler((call) async {
      debugPrint("SISTEMA LAD: Evento de Canal Screenshot -> ${call.method}");
      
      if (call.method == 'onImageShared') {
        final String path = call.arguments;
        _handleBingoNavigation(imagePath: path);
      } else if (call.method == 'onScreenshotDetected') {
        _handleBingoNavigation(autoStartOCR: true);
      }
    });

    // 🚀 ACTIVACIÓN DEL VIGILANTE SOBERANO
    _screenshotChannel.invokeMethod('startScreenshotWatcher').catchError((e) {
      debugPrint("SISTEMA LAD: No se pudo activar el vigilante nativo: $e");
    });
  }

  void _handleBingoNavigation({String? imagePath, bool autoStartOCR = false}) async {
    // 🛡️ Esperamos a que la App esté lista y el usuario logueado
    int retry = 0;
    while (FirebaseAuth.instance.currentUser == null && retry < 12) {
      await Future.delayed(const Duration(milliseconds: 500));
      retry++;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint("SISTEMA LAD: No se pudo navegar a BINGO - Usuario no autenticado.");
      return;
    }

    final context = navigatorKey.currentContext;
    if (context != null && context.mounted) {
      debugPrint("SISTEMA LAD: Ejecutando Teletransporte BINGO...");
      
      // 🚀 NAVEGACIÓN INTELIGENTE: Si ya estamos en una página, limpiamos hasta el Dashboard
      // y lanzamos la nueva misión para evitar duplicidad.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => CreateOrderPage(
            initialImage: imagePath != null ? XFile(imagePath) : null,
            autoStartOCR: autoStartOCR,
          ),
        ),
        (route) => route.isFirst,
      );
    }
  }

  void _listenToAuthChanges() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final pendingId = prefs.getString('pending_messenger_invitation');
          
          if (pendingId != null && pendingId.isNotEmpty) {
            // 🛡️ REGLA DE ORO SOBERANA: 
            // Verificamos si ya está vinculado para no repetir la tarjeta 100 veces
            final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
            final List<dynamic> linkedIds = userDoc.data()?['linkedMessengerIds'] ?? [];
            
            if (!linkedIds.contains(pendingId.trim())) {
              _showInvitationDialog(pendingId);
            } else {
              // Si ya es un driver vinculado, limpiamos la memoria en silencio
              await prefs.remove('pending_messenger_invitation');
            }
          }
        } catch (_) {}
      }
    });
  }

  void _initDeepLinks() async {
    if (_appLinks == null) return;
    _appLinks!.uriLinkStream.listen((uri) => _handleIncomingUri(uri));
    try {
      final initialUri = await _appLinks!.getInitialLink();
      if (initialUri != null) {
        _handleIncomingUri(initialUri);
      } else {
        _checkClipboardForReferral();
      }
    } catch (_) {}
  }

  void _checkClipboardForReferral() async {
    if (kIsWeb) return;
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      String? text = data?.text?.trim();
      
      // 🛡️ FILTRO DE SEGURIDAD SOBERANO (RESTAURADO)
      if (text != null && text.isNotEmpty && text.length >= 20 && text.length <= 40) {
        if (!text.contains(' ')) {
          _processReferralId(text);
        }
      }
    } catch (_) {}
  }

  void _handleIncomingUri(Uri uri) {
    String? referrerId = uri.queryParameters['id'] ?? uri.queryParameters['ref'];
    if (referrerId != null && referrerId.isNotEmpty) {
      // 🛡️ LIMPIEZA TOTAL: Eliminamos cualquier espacio o basura del ID
      _processReferralId(referrerId.trim());
    }
  }

  void _processReferralId(String driverId) async {
    try {
      final cleanId = driverId.trim();
      final prefs = await SharedPreferences.getInstance();
      
      // Guardamos SIEMPRE en memoria permanente
      await prefs.setString('pending_messenger_invitation', cleanId);
      
      if (FirebaseAuth.instance.currentUser != null) {
        _showInvitationDialog(cleanId);
      }
    } catch (e) {
      debugPrint("Error en processReferralId: $e");
    }
  }

  void _showInvitationDialog(String driverId) {
    final context = navigatorKey.currentContext;
    // Si el Dashboard aún no está listo, esperamos un poco
    if (context == null) {
      Future.delayed(const Duration(seconds: 1), () => _showInvitationDialog(driverId));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => InvitationCard(
        messengerId: driverId,
        onAccept: () async {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await UserService().linkMessengerToClient(user.uid, driverId);
          }
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('pending_messenger_invitation');
          if (dialogContext.mounted) Navigator.pop(dialogContext);
        },
        onReject: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('pending_messenger_invitation');
          if (dialogContext.mounted) Navigator.pop(dialogContext);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'LAD Courier USA',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4B39A8)),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {'/': (context) => const AuthGate()},
    );
  }
}
