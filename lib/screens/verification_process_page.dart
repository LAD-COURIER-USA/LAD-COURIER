import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lad_courier/services/stripe_service.dart';
import 'package:lad_courier/services/user_service.dart';
import 'package:lad_courier/models/user_model.dart';

class VerificationProcessPage extends StatefulWidget {
  const VerificationProcessPage({super.key});

  @override
  State<VerificationProcessPage> createState() => _VerificationProcessPageState();
}

class _VerificationProcessPageState extends State<VerificationProcessPage> with WidgetsBindingObserver {
  final StripeService _stripeService = StripeService();
  final UserService _userService = UserService();

  bool _isStripeLoading = false;
  bool _isOnboardingLoading = false;

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

  Future<void> _startStripeIdentity(UserModel user) async {
    if (user.stripeAccountId == null || user.stripeAccountId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Debes iniciar la Vinculación Bancaria primero.")),
      );
      return;
    }

    setState(() => _isStripeLoading = true);
    try {
      await _stripeService.verifyIdentity(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error de Identidad: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isStripeLoading = false);
    }
  }

  Future<void> _startStripeOnboarding() async {
    setState(() => _isOnboardingLoading = true);
    try {
      await _stripeService.startOnboarding();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error de Onboarding: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isOnboardingLoading = false);
    }
  }

  Future<void> _syncStripeStatus({bool silent = false}) async {
    if (!silent) setState(() => _isOnboardingLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      // Llamamos a la Cloud Function de sincronización
      final result = await _userService.syncStripeStatus(user.uid);
      
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result == "active" 
              ? "✅ ¡Cuenta activada con éxito!" 
              : "ℹ️ Stripe aún está procesando tus datos."),
            backgroundColor: result == "active" ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al sincronizar: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted && !silent) setState(() => _isOnboardingLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("No autenticado")));

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

        final bool hasStripeAccount = userModel.stripeAccountId != null && userModel.stripeAccountId!.isNotEmpty;
        final bool isBankActive = userModel.stripeStatus == 'active' || userModel.isStripeConnected == true;
        final bool isIdentityVerified = userModel.isIdentityVerified || userModel.verificationStatus == 'APROBADO_DOC';

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text("CENTRAL DE VERIFICACIÓN", style: TextStyle(fontWeight: FontWeight.w900)),
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
                  const Text(
                    "TU SEGURIDAD ES TU MEJOR INVERSIÓN",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "SISTEMA LAD: Completa los pasos para activar tu cuenta de driver. Si ya terminaste un paso en Stripe, jala hacia abajo para refrescar.",
                    style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.5),
                  ),
                  const SizedBox(height: 30),

                  _buildStepCard(
                    number: "1",
                    title: "Vinculación Bancaria",
                    description: "Configura tu cuenta para recibir pagos directos.",
                    icon: isBankActive ? Icons.check_circle : (hasStripeAccount ? Icons.hourglass_empty : Icons.account_balance_wallet_outlined),
                    buttonLabel: isBankActive
                        ? "CUENTA ACTIVA"
                        : (hasStripeAccount ? "REINTENTAR / CONTINUAR" : "CONFIGURAR PAGOS"),
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
                            "YA TERMINÉ EN STRIPE (VERIFICAR AHORA)",
                            style: TextStyle(fontWeight: FontWeight.w900, color: Colors.green, fontSize: 11),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  _buildStepCard(
                    number: "2",
                    title: "Verificar Identidad",
                    description: "Escanea tu ID y tómate una selfie.",
                    icon: isIdentityVerified ? Icons.check_circle : Icons.face_retouching_natural,
                    buttonLabel: isIdentityVerified ? "IDENTIDAD VERIFICADA" : "INICIAR ESCANEO ID",
                    isLoading: _isStripeLoading,
                    onPressed: hasStripeAccount ? () => _startStripeIdentity(userModel) : () {},
                    color: isIdentityVerified ? Colors.green : (hasStripeAccount ? Colors.indigo : Colors.grey),
                    isEnabled: hasStripeAccount && !isIdentityVerified,
                    isCompleted: isIdentityVerified,
                  ),

                  const SizedBox(height: 40),
                  _buildSecurityFooter(),
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

  Widget _buildSecurityFooter() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_outline, color: Colors.black54),
          SizedBox(width: 15),
          Expanded(
            child: Text(
              "Tus datos están encriptados y son procesados directamente por Stripe bajo estándares bancarios.",
              style: TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
