import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StripeService {
  // 🛡️ SISTEMA LAD: Forzamos la región us-central1 para coincidir con el Dashboard de Firebase
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  /// 1. INICIAR REGISTRO BANCARIO PARA DRIVERS (ONBOARDING)
  Future<void> startOnboarding() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'No hay usuario autenticado.';
      
      debugPrint("[AUDITORÍA A] Iniciando solicitud de Onboarding para: ${user.uid}");

      final result = await _functions.httpsCallable('createStripeAccount').call();
      
      if (result.data == null || result.data['url'] == null) {
        throw 'Stripe no devolvió una URL válida.';
      }

      final String urlString = result.data['url'].toString().trim();
      debugPrint("[AUDITORÍA D] URL Recibida del servidor: $urlString");

      if (!await launchUrl(Uri.parse(urlString), mode: LaunchMode.externalApplication)) {
        throw 'No se pudo abrir el navegador.';
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

      debugPrint("🚀 SISTEMA LAD: Iniciando Setup de Pago para Cliente: ${user.uid}");

      // 1. Llamar a la función para obtener los secretos
      final result = await _functions.httpsCallable('createSetupIntent').call();
      final data = result.data;

      // 2. Inicializar el Payment Sheet (Ventana de Stripe)
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          setupIntentClientSecret: data['setupIntentClientSecret'],
          customerId: data['customerId'],
          customerEphemeralKeySecret: data['ephemeralKeySecret'],
          merchantDisplayName: 'LAD Courier',
          style: ThemeMode.light,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Colors.black,
            ),
            shapes: PaymentSheetShape(
              borderRadius: 12,
            ),
          ),
        ),
      );

      // 3. Mostrar el Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      // 4. 🛡️ SINCRONIZACIÓN FORZADA (Válvula de Seguridad LAD)
      // Una vez cerrada la ventana con éxito, obligamos a Firestore a actualizarse
      debugPrint("🚀 SISTEMA LAD: Sincronizando método de pago con el servidor...");
      await _functions.httpsCallable('syncPaymentMethod').call();
      debugPrint("✅ SISTEMA LAD: Sincronización completada.");

    } catch (e) {
      if (e is StripeException) {
        debugPrint("⚠️ SISTEMA LAD: Pago cancelado o fallido: ${e.error.localizedMessage}");
        // No lanzamos error si el usuario simplemente canceló
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
      if (e.code == 'unauthenticated') {
        return 'Error de Autenticación: Por favor, cierra sesión y vuelve a entrar.';
      }
      return e.message ?? 'Error en el servidor de pagos.';
    }
    return e.toString();
  }
}
