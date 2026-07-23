import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // 🛡️ PARA kIsWeb
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:cloud_functions/cloud_functions.dart'; // ✅ AÑADIDO PARA AUDITORÍA CLOUD
import 'package:lad_courier/services/stripe_service.dart';
import 'package:lad_courier/services/user_service.dart';
import 'package:lad_courier/services/storage_service.dart';
import 'package:lad_courier/models/user_model.dart';
import 'package:lad_courier/screens/messenger/liveness_selfie_page.dart';
import 'package:lad_courier/l10n/app_localizations.dart';
import 'package:lad_courier/services/stripe_mode_service.dart'; // 🧬 IMPORTACIÓN DOBLE ADN

class VerificationProcessPage extends StatefulWidget {
  const VerificationProcessPage({super.key});

  @override
  State<VerificationProcessPage> createState() => _VerificationProcessPageState();
}

class _VerificationProcessPageState extends State<VerificationProcessPage> with WidgetsBindingObserver {
  final StripeService _stripeService = StripeService();
  final UserService _userService = UserService();
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1'); // ✅ INSTANCIA DE FUNCIONES

  bool _isOnboardingLoading = false;
  bool _isBiometricLoading = false;

  @override
  void initState() {
    super.initState();
    // 🛡️ AUDITORÍA: Observamos la App para detectar cuándo el usuario vuelve de Stripe
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // ✨ MAGIA PROFESIONAL: Si el usuario vuelve a la App (resumed), sincronizamos Stripe solitos
    if (state == AppLifecycleState.resumed) {
      debugPrint("[AUDITORÍA REGRESO] El usuario volvió a la App. Sincronizando automáticamente...");
      _syncStripeStatus(silent: true);
    }
  }

  Future<void> _startBiometricVerification(UserModel user) async {
    final storage = StorageService();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      setState(() => _isBiometricLoading = true);

      // 🛡️ ESCANEO DE LISTA NEGRA (TRIDENTE V19.6)
      final bool blacklisted = await _userService.isBlacklisted(
        stripeId: user.stripeAccountId ?? user.stripeAccountIdLive,
        phone: user.phoneNumber
      );

      if (blacklisted) {
        throw "Esta identidad ha sido revocada permanentemente de LAD Courier.";
      }

      if (!mounted) return;

      // 1. CAPTURAR SELFIE DE LA JORNADA (MODO LIVENESS ACTIVADO)
      // 🤳 Usamos detección de vida para evitar fraudes con fotos estáticas.
      final String? localPath = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LivenessSelfiePage()),
      );

      if (localPath == null) {
        setState(() => _isBiometricLoading = false);
        return;
      }

      // SUBIMOS EL SELFIE VALIDADO
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text("🚀 SUBIENDO SELFIE AL BÚNKER..."), duration: Duration(seconds: 2))
        );
      }

      final String? sessionSelfieUrl = await storage.uploadFile(
        'order_photos', 
        "session_${user.uid}_${DateTime.now().millisecondsSinceEpoch}", 
        localPath
      );

      if (sessionSelfieUrl == null) {
        throw "Error crítico: No se pudo subir la foto al búnker.";
      }

      // 3. AUDITORÍA FORENSE (SISTEMA LAD V18.5)
      if (kIsWeb) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text("👁️ AUDITANDO IDENTIDAD (IA GOOGLE)..."), duration: Duration(seconds: 2))
          );
        }

        final result = await _functions.httpsCallable('verifyLivenessCloud').call({
          'imageUrl': sessionSelfieUrl,
        });

        if (result.data['success'] != true) {
          throw result.data['error'] ?? "Fallo en la auditoría de identidad.";
        }
        debugPrint("✅ SISTEMA LAD: Auditoría Forense APROBADA.");
      }

      // 4. VALIDACIÓN POR HUELLA DACTILAR (Solo Nativo)
      if (!kIsWeb) {
        final bool isAuthentic = await _userService.authenticateBiometric(
          reason: "Confirma tu identidad con tu huella para validar la selfie de hoy."
        );
        if (!isAuthentic) {
          throw "La huella no coincide.";
        }
      }

      // 5. ACTUALIZACIÓN FINAL
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'lastSessionSelfieUrl': sessionSelfieUrl,
        'last_biometric_verification': FieldValue.serverTimestamp(),
        'verificationStatus': 'APROBADO_DOC',
        'isIdentityVerified': true,
      });

      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text("✅ VERIFICACIÓN DE JORNADA EXITOSA"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text("Error de Verificación: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isBiometricLoading = false);
    }
  }

  Future<void> _startStripeOnboarding() async {
    setState(() => _isOnboardingLoading = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await _stripeService.startOnboarding();
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text("Error de Onboarding: $e")),
      );
    } finally {
      if (mounted) setState(() => _isOnboardingLoading = false);
    }
  }

  Future<void> _syncStripeStatus({bool silent = false}) async {
    if (!silent) setState(() => _isOnboardingLoading = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      // Llamamos a la Cloud Function de sincronización
      final result = await _userService.syncStripeStatus(user.uid);
      
      if (!silent) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(result == "active" 
              ? "✅ ¡Cuenta activada con éxito!" 
              : "ℹ️ Stripe aún está procesando tus datos."),
            backgroundColor: result == "active" ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!silent) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text("Error al sincronizar: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isOnboardingLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final l10n = AppLocalizations.of(context)!;
    if (user == null) return Scaffold(body: Center(child: Text(l10n.auth_error_session)));

    return StreamBuilder<UserModel?>(
      stream: _userService.getUserStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.black)));
        }

        final userModel = snapshot.data;
        if (userModel == null) {
          return Scaffold(
            appBar: AppBar(title: const Text("ERROR")),
            body: const Center(child: Text("No se pudo cargar el perfil")),
          );
        }

        final bool isLive = StripeModeService().isLive();
        
        // 🛡️ REGLA VIP SOBERANA: Si es VIP, tiene luz verde automática
        final bool isBankActive = userModel.isVipTester || (isLive 
            ? (userModel.stripeStatusLive == 'active')
            : (userModel.stripeStatus == 'active' || userModel.isStripeConnected == true));

        final bool hasStripeAccount = userModel.isVipTester || (isLive 
            ? (userModel.stripeAccountIdLive != null)
            : (userModel.stripeAccountId != null && userModel.stripeAccountId!.isNotEmpty));

        final bool isIdentityVerified = userModel.isVipTester || userModel.isIdentityVerified || userModel.verificationStatus == 'APROBADO_DOC';

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(l10n.verif_title, style: const TextStyle(fontWeight: FontWeight.w900)),
            centerTitle: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
          body: RefreshIndicator(
            onRefresh: () async => await _userService.getUser(user.uid),
            color: Colors.black,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.verif_header,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.verif_body,
                    style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.5),
                  ),
                  const SizedBox(height: 30),

                  _buildStepCard(
                    number: "1",
                    title: l10n.verif_step1_title,
                    description: l10n.verif_step1_desc,
                    icon: isBankActive ? Icons.check_circle : (hasStripeAccount ? Icons.hourglass_empty : Icons.account_balance_wallet_outlined),
                    buttonLabel: isBankActive
                        ? l10n.verif_step1_btn_active
                        : (hasStripeAccount ? l10n.verif_step1_btn_retry : l10n.verif_step1_btn_config),
                    isLoading: _isOnboardingLoading,
                    onPressed: _startStripeOnboarding,
                    color: isBankActive ? Colors.green : (hasStripeAccount ? Colors.orange : Colors.blueAccent),
                    isCompleted: isBankActive,
                  ),

                  if (hasStripeAccount && !isBankActive)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Center(
                        child: TextButton.icon(
                          onPressed: _isOnboardingLoading ? null : _syncStripeStatus,
                          icon: const Icon(Icons.sync, color: Colors.green),
                          label: const Text(
                            "SINCRONIZAR ESTADO",
                            style: TextStyle(fontWeight: FontWeight.w900, color: Colors.green, fontSize: 11),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  _buildStepCard(
                    number: "2",
                    title: l10n.verif_step2_title,
                    description: l10n.verif_step2_desc,
                    icon: isIdentityVerified ? Icons.check_circle : Icons.face_retouching_natural,
                    buttonLabel: isIdentityVerified ? l10n.verif_step2_btn_verified : l10n.verif_step2_btn_start,
                    isLoading: _isBiometricLoading,
                    onPressed: hasStripeAccount ? () => _startBiometricVerification(userModel) : () {},
                    color: isIdentityVerified ? Colors.green : (hasStripeAccount ? Colors.indigo : Colors.grey),
                    isEnabled: hasStripeAccount && !isIdentityVerified,
                    isCompleted: isIdentityVerified,
                  ),

                  const SizedBox(height: 40),
                  _buildSecurityFooter(l10n),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepCard({
    required String number,
    required String title,
    required String description,
    required IconData icon,
    required String buttonLabel,
    required bool isLoading,
    required VoidCallback onPressed,
    required Color color,
    bool isCompleted = false,
    bool isEnabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withAlpha(13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(51), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: color,
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 15)
                    : Text(number, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: color),
                ),
              ),
              Icon(icon, color: color),
            ],
          ),
          const SizedBox(height: 12),
          Text(description, style: const TextStyle(fontSize: 12, color: Colors.black87)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: (isLoading || !isEnabled || isCompleted) ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                disabledBackgroundColor: isCompleted ? color : Colors.grey[300],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(buttonLabel, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityFooter(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: Colors.black54),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              l10n.verif_footer,
              style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
