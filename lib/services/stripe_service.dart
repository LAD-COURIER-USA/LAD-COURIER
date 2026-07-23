import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // 🛡️ PARA DETECTAR WEB/IPHONE
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lad_courier/services/stripe_mode_service.dart'; // 🛡️ IMPORTACIÓN DOBLE ADN

class StripeService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  /// 1. INICIAR REGISTRO BANCARIO PARA DRIVERS (ONBOARDING)
  Future<void> startOnboarding() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'No hay usuario autenticado.';
      
      debugPrint("[AUDITORÍA A] Iniciando solicitud de Onboarding para: ${user.uid}");

      // 🛡️ REFUERZO V15.14: Mimetismo con Cliente y cambio de nombre para limpiar IAM
      final result = await _functions.httpsCallable('setupDriverBank').call({});
      
      if (result.data == null || result.data['url'] == null) {
        throw 'Stripe no devolvió una URL válida.';
      }

      final String urlString = result.data['url'].toString().trim();
      debugPrint("🔗 [AUDITORÍA BINGO] URL de Stripe: $urlString");

      final Uri stripeUri = Uri.parse(urlString);

      // 🛡️ REFUERZO V15.12: Forzamos la apertura en navegador externo 
      // para evitar bloqueos de seguridad de Android.
      if (await canLaunchUrl(stripeUri)) {
        await launchUrl(
          stripeUri, 
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw 'No se puede abrir el portal de registro. Revisa tu conexión.';
      }

    } catch (e) {
      debugPrint("[AUDITORÍA ERROR] Fallo en Onboarding: $e");
      throw e.toString();
    }
  }

  /// 2. CONFIGURAR MÉTODO DE PAGO PARA CLIENTES (SETUP INTENT)
  Future<void> setupPaymentMethod() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'SISTEMA LAD: Usuario no autenticado.';

      final bool isLive = StripeModeService().isLive();
      debugPrint("🚀 SISTEMA LAD: Iniciando Setup en MODO ${isLive ? 'REAL' : 'TEST'} para: ${user.uid}");

      // 🌐 TRATO ESPECIAL PARA WEB (iPHONES / PWA)
      if (kIsWeb) {
        debugPrint("🌐 MODO WEB DETECTADO: Usando Stripe Checkout para Setup...");
        final result = await _functions.httpsCallable('createWebSetupSession').call();
        final String? checkoutUrl = result.data['url'];
        
        if (checkoutUrl != null) {
          if (await canLaunchUrl(Uri.parse(checkoutUrl))) {
            await launchUrl(Uri.parse(checkoutUrl), mode: LaunchMode.externalApplication);
            return; // El usuario termina en la web de Stripe
          }
        }
        throw 'No se pudo abrir la pasarela de pago web.';
      }

      // 📱 MODO NATIVO (ANDROID): Usamos el Payment Sheet original
      final result = await _functions.httpsCallable('createSetupIntent').call();
      final data = result.data;

      // 🛡️ REFUERZO DE RESILIENCIA: Desactivamos Google Pay en Live temporalmente 
      // para asegurar que el formulario de tarjeta sea lo primero que funcione.
      final googlePayConfig = isLive ? null : const PaymentSheetGooglePay(
        merchantCountryCode: 'US', 
        testEnv: true
      );
      
      const appearanceConfig = PaymentSheetAppearance(
        colors: PaymentSheetAppearanceColors(
          primary: Color(0xFF4B39A8),
        ),
        shapes: PaymentSheetShape(
          borderRadius: 12,
        ),
      );

      debugPrint("🚀 SISTEMA LAD: Llamando a initPaymentSheet...");

      // 2. Inicializar el Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          setupIntentClientSecret: data['setupIntentClientSecret'],
          customerId: data['customerId'],
          customerEphemeralKeySecret: data['ephemeralKeySecret'],
          merchantDisplayName: 'LAD Courier USA',
          googlePay: googlePayConfig,
          applePay: const PaymentSheetApplePay(
            merchantCountryCode: 'US',
          ),
          style: ThemeMode.light,
          appearance: appearanceConfig,
          returnURL: 'ladcourier://stripe-return', // 🛡️ REQUERIDO PARA iOS
        ),
      );

      debugPrint("🚀 SISTEMA LAD: initPaymentSheet completado. Llamando a presentPaymentSheet...");

      // 3. Mostrar el Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      // 4. 🛡️ SINCRONIZACIÓN FORZADA (Válvula de Seguridad LAD)
      debugPrint("🚀 SISTEMA LAD: Sincronizando método de pago con el servidor...");
      await _functions.httpsCallable('syncPaymentMethod').call();
      debugPrint("✅ SISTEMA LAD: Sincronización completada.");

    } catch (e) {
      if (e is StripeException) {
        debugPrint("⚠️ SISTEMA LAD: Pago cancelado o fallido: ${e.error.localizedMessage}");
        if (e.error.code == FailureCode.Canceled) return;
        throw e.error.localizedMessage ?? 'Error en la pasarela de pago.';
      }
      debugPrint("❌ SISTEMA LAD: Error en Setup de Pago: $e");
      throw _handleError(e);
    }
  }

  /// 3. INICIAR VERIFICACIÓN DE IDENTIDAD (STRIPE IDENTITY)
  Future<void> verifyIdentity(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'SISTEMA LAD: Usuario no autenticado.';

      final result = await _functions.httpsCallable('createIdentitySession').call();
      
      if (result.data == null || result.data['url'] == null) {
        throw 'No se pudo generar el enlace de verificación.';
      }

      final String verificationUrl = result.data['url'];
      if (await canLaunchUrl(Uri.parse(verificationUrl))) {
        await launchUrl(Uri.parse(verificationUrl), mode: LaunchMode.externalApplication);
      } else {
        throw 'No se pudo abrir el enlace en el navegador.';
      }
    } catch (e) {
      debugPrint("❌ SISTEMA LAD: Error de identidad: $e");
      throw _handleError(e);
    }
  }

  String _handleError(dynamic e) {
    if (e is FirebaseFunctionsException) {
      debugPrint("🔥 [LAD ERROR DETALLE] Code: ${e.code}, Message: ${e.message}, Details: ${e.details}");
      if (e.code == 'unauthenticated') {
        return 'Error de Autenticación: Por favor, cierra sesión y vuelve a entrar.';
      }
      return 'Error de Servidor (${e.code}): ${e.message}';
    }
    return e.toString();
  }
}
