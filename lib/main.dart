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

  @override
  void initState() {
    super.initState();
    // 🛡️ REFUERZO V19.0: Blindaje total de enlaces profundos en Web
    if (!kIsWeb) {
      try {
        _appLinks = AppLinks();
        _initDeepLinks();
      } catch (_) {}
    }
    _listenToAuthChanges(); 
  }

  void _listenToAuthChanges() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final pendingId = prefs.getString('pending_messenger_invitation');
          if (pendingId != null && pendingId.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _showInvitationDialog(pendingId));
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
      if (text != null && text.isNotEmpty) {
        if (text.length >= 20 && text.length <= 40) _processReferralId(text);
      }
    } catch (_) {}
  }

  void _handleIncomingUri(Uri uri) {
    String? referrerId = uri.queryParameters['id'] ?? uri.queryParameters['ref'];
    if (referrerId != null && referrerId.isNotEmpty) _processReferralId(referrerId);
  }

  void _processReferralId(String driverId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_messenger_invitation', driverId);
      if (FirebaseAuth.instance.currentUser != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _showInvitationDialog(driverId));
      }
    } catch (_) {}
  }

  void _showInvitationDialog(String driverId) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => InvitationCard(
        messengerId: driverId,
        onAccept: () async {
          Navigator.pop(dialogContext);
        },
        onReject: () => Navigator.pop(dialogContext),
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
