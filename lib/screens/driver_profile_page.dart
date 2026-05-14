import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../models/user_model.dart';
import '../auth_service.dart';
import '../services/storage_service.dart';
import '../services/user_service.dart'; // 🛡️ IMPORTACIÓN AÑADIDA
import '../pages/client/completed_orders_page.dart';
import 'driver_terms_acceptance_page.dart';
import 'verification_process_page.dart';

class DriverProfilePage extends StatefulWidget {
  const DriverProfilePage({super.key});

  @override
  State<DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends State<DriverProfilePage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vehicleController = TextEditingController();
  final StorageService _storageService = StorageService();
  final AuthService _authService = AuthService();
  final UserService _userService = UserService(); // 🛡️ SERVICIO AÑADIDO

  bool _isLoading = true;
  bool _isSaving = false;
  UserModel? _userModel;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        _userModel = UserModel.fromFirestore(doc);

        if (_userModel?.acceptedTerms != true && mounted) {
          final accepted = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => const DriverTermsAcceptancePage(),
              fullscreenDialog: true,
            ),
          );

          if (accepted != true) {
            if (mounted) Navigator.of(context).pop();
            return;
          } else {
            return _loadUserData();
          }
        }

        _nameController.text = _userModel?.displayName ?? '';
        _phoneController.text = _userModel?.phoneNumber ?? '';
        _vehicleController.text = _userModel?.vehicleDescription ?? '';
        _photoUrl = _userModel?.photoURL;
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  /// Solicita un enlace de acceso al Dashboard de Stripe Express para ver ganancias
  Future<void> _openStripeDashboard() async {
    setState(() => _isSaving = true);
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('createStripeLoginLink');
      final result = await callable.call();

      final String? url = result.data['url'];
      if (url != null) {
        final Uri uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else {
        throw "No se pudo obtener la URL de Stripe";
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al abrir Dashboard: $e"), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _syncStripeStatus() async {
    setState(() => _isSaving = true);
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('syncStripeStatus');
      final result = await callable.call();

      final data = result.data as Map<String, dynamic>;
      final String status = data['status'] ?? '';

      if (status == 'active') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("¡Cuenta Activa y Sincronizada!"), backgroundColor: Colors.green)
          );
        }
        _loadUserData();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Stripe indica que aún faltan datos o validación."), backgroundColor: Colors.orange)
          );
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // --- LÓGICA DE ELIMINACIÓN DE CUENTA (MANTENIENDO TU LÓGICA DE FIREBASE) ---
  Future<void> _confirmDeleteAccount(AppLocalizations l10n) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.common_delete_account),
        content: const Text("¿Estás seguro de que deseas eliminar tu cuenta? Esta acción no se puede deshacer y borrará tus datos permanentemente."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCELAR")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("ELIMINAR", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isSaving = true);
      try {
        final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('deleteUserAccount');
        await callable.call();

        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Cuenta eliminada correctamente."))
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Error: Debes haber iniciado sesión recientemente para realizar esta acción."))
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildVerificationDashboard() {
    if (_userModel == null) return const SizedBox.shrink();

    final bool acceptedTerms = _userModel?.acceptedTerms ?? false;
    final String status = _userModel?.verificationStatus ?? 'ACEPTACIÓN_PENDIENTE';
    final bool isBankActive = _userModel?.stripeStatus == 'active' || _userModel?.isStripeConnected == true;
    final bool isIdentityVerified = _userModel?.isIdentityVerified == true || status == 'APROBADO_DOC' || status == 'APROBADO';

    final bool isApproved = acceptedTerms && isBankActive && isIdentityVerified;

    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isApproved ? Colors.green.withAlpha(13) : Colors.amber.withAlpha(13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isApproved ? Colors.green : Colors.amber.withAlpha(128),
            width: 2
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                  isApproved ? Icons.verified : Icons.security,
                  color: isApproved ? Colors.green : Colors.amber[800]
              ),
              const SizedBox(width: 10),
              Text(
                isApproved ? "PERFIL VERIFICADO" : "MANDATORIO",
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: isApproved ? Colors.green[900] : Colors.amber[900],
                    fontSize: 16
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _verificationStep("1. Acuerdo de Operador", acceptedTerms),
          _verificationStep("2. Vinculación Bancaria", isBankActive),
          _verificationStep("3. Verificación de Identidad", isIdentityVerified),

          if (!isApproved) ...[
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const VerificationProcessPage())
                ),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.greenAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                child: const Text("VERIFICACIÓN",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton.icon(
                onPressed: _isSaving ? null : _syncStripeStatus,
                icon: const Icon(Icons.sync, size: 18, color: Colors.indigo),
                label: const Text("YA COMPLETÉ MI REGISTRO (SINCRONIZAR)",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.indigo)
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Tu proceso de verificación asegura la calidad y confianza en la plataforma.",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
            ),
          ]
        ],
      ),
    );
  }

  Widget _verificationStep(String label, bool completed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
              completed ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 18,
              color: completed ? Colors.green : Colors.grey
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
                label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: completed ? FontWeight.bold : FontWeight.normal,
                    color: completed ? Colors.black : Colors.black54
                )
            ),
          ),
        ],
      ),
    );
  }

  void _showBusinessCard() {
    if (_userModel == null) return;
    
    // 🛡️ SISTEMA LAD: Usamos el esquema personalizado en el QR para forzar la apertura de la App.
    final String qrData = "ladcourier://invite?id=${_userModel!.uid}";

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black, width: 2.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FittedBox(
                  child: Text("LAD COURIER", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26, letterSpacing: 3, color: Colors.black)),
                ),
                const FittedBox(
                  child: Text("LAD DIGITAL SYSTEMS LLC", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.black87)),
                ),
                const Divider(height: 25, color: Colors.black, thickness: 2.5),

                Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            child: Text(_userModel?.displayName?.toUpperCase() ?? "DRIVER", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black)),
                          ),
                          const Text("MESSENGER VERIFIED", style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.w900, fontSize: 11)),
                          const SizedBox(height: 5),
                          Text(_userModel?.phoneNumber ?? "", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.black)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black26, width: 1.5),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 140.0,
                    gapless: false,
                  ),
                ),
                const SizedBox(height: 15),
                const Text("SCAN TO LINK", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black)),
                const SizedBox(height: 20),
                const FittedBox(
                  child: Text("EXPRESS DELIVERY • SHOPPING • LOGISTICS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 1.2)),
                ),
                const SizedBox(height: 20),
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(backgroundColor: Colors.black12, padding: const EdgeInsets.symmetric(horizontal: 40)),
                    child: const Text("CERRAR", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900))
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReferralSection(AppLocalizations l10n) {
    if (_userModel == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          const Icon(Icons.qr_code_scanner, color: Colors.greenAccent, size: 40),
          const SizedBox(height: 10),
          Text(
            l10n.prof_radar_title.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white),
          ),
          const SizedBox(height: 5),
          const Text(
            "TU HERRAMIENTA DE MARKETING",
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showBusinessCard,
              icon: const Icon(Icons.badge, color: Colors.black),
              label: const Text("MI TARJETA DE NEGOCIOS", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final bool acceptedTerms = _userModel?.acceptedTerms ?? false;
    final String status = _userModel?.verificationStatus ?? 'ACEPTACIÓN_PENDIENTE';
    final bool isBankActive = _userModel?.stripeStatus == 'active' || _userModel?.isStripeConnected == true;
    final bool isIdentityVerified = _userModel?.isIdentityVerified == true || status == 'APROBADO_DOC' || status == 'APROBADO';
    final bool isApproved = acceptedTerms && isBankActive && isIdentityVerified;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l10n.prof_title, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: Colors.black)) : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(isApproved),
            const SizedBox(height: 30),

            _buildVerificationDashboard(),

            if (isApproved) ...[
              _buildReferralSection(l10n),
              const SizedBox(height: 30),

              _buildMenuTile(
                title: l10n.earnings_history_title,
                icon: Icons.history_rounded,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CompletedOrdersPage(isDriver: true))),
              ),
              const SizedBox(height: 20),

              Text(l10n.prof_section_id, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.black)),
              const SizedBox(height: 15),
              _buildTextField(controller: _nameController, icon: Icons.person, label: l10n.prof_label_name),
              _buildTextField(controller: _phoneController, icon: Icons.phone, label: l10n.prof_label_phone),
              _buildTextField(controller: _vehicleController, icon: Icons.commute, label: l10n.prof_label_vehicle),

              const SizedBox(height: 30),
              Text(l10n.prof_section_pay, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.black)),
              const SizedBox(height: 15),
              _buildStripeConnectCard(l10n),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: FilledButton.styleFrom(backgroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  child: Text(l10n.prof_btn_save, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.greenAccent, fontSize: 16)),
                ),
              ),
            ],

            const SizedBox(height: 20),
            Center(
              child: TextButton.icon(
                onPressed: _switchToClientRole,
                icon: const Icon(Icons.swap_horiz, color: Colors.black),
                label: Text(l10n.prof_btn_switch, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
              ),
            ),

            // --- SECCIÓN DE ELIMINAR CUENTA ---
            const SizedBox(height: 50),
            const Divider(),
            const SizedBox(height: 20),
            Center(
              child: TextButton.icon(
                onPressed: () => _confirmDeleteAccount(l10n),
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                label: Text(l10n.common_delete_account, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({required String title, required IconData icon, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.green.withAlpha(26), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.green[800]),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black87)),
      trailing: const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey[200]!)),
    );
  }

  Widget _buildProfileHeader(bool isApproved) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 65,
            backgroundColor: Colors.grey[200],
            backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
            child: (_photoUrl == null) ? const Icon(Icons.person, size: 65, color: Colors.black26) : null,
          ),
          if (isApproved)
            const Positioned(
              top: 0,
              right: 0,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                radius: 18,
                child: Icon(Icons.verified, color: Colors.blue, size: 28),
              ),
            ),
          Positioned(bottom: 0, right: 0, child: CircleAvatar(backgroundColor: Colors.black, radius: 20, child: IconButton(icon: const Icon(Icons.edit, color: Colors.greenAccent, size: 20), onPressed: _changeProfilePicture))),
        ],
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required IconData icon, required String label}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          prefixIcon: Icon(icon, color: Colors.black),
          filled: true,
          fillColor: Colors.grey[300],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
        ),
      ),
    );
  }

  Widget _buildStripeConnectCard(AppLocalizations l10n) {
    final bool isConnected = _userModel?.isStripeConnected ?? false;
    const Color themeColor = Colors.indigo;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: isConnected ? Colors.green.withAlpha(26) : themeColor.withAlpha(26),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
              color: isConnected ? Colors.green.withAlpha(128) : themeColor.withAlpha(77),
              width: 2
          )
      ),
      child: ListTile(
        leading: Icon(
            isConnected ? Icons.check_circle : Icons.account_balance,
            color: isConnected ? Colors.green : themeColor,
            size: 28
        ),
        title: Text(
            isConnected ? "CUENTA DE COBROS VINCULADA" : l10n.prof_pay_stripe,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.black)
        ),
        subtitle: Text(
            isConnected ? "Listo para recibir pagos directos" : l10n.prof_pay_stripe_sub,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)
        ),
        trailing: Icon(
            isConnected ? Icons.settings : Icons.add_circle_outline,
            color: Colors.black
        ),
        onTap: () => _showStripeConnectModal(isConnected),
      ),
    );
  }

  void _showStripeConnectModal(bool isConnected) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.shield, color: Colors.indigo[900]),
            const SizedBox(width: 10),
            const Text("PAGOS DIRECTOS", style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Para cumplir con el modelo de LAD Courier, debes vincular tu cuenta de Stripe.",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 15),
            _infoRow(Icons.account_balance_wallet, "El dinero va del cliente directo a ti."),
            _infoRow(Icons.timer_off, "LAD Courier no retiene tus ganancias."),
            _infoRow(Icons.security, "Tus datos bancarios son procesados por Stripe."),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CERRAR")),
          if (!isConnected)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const VerificationProcessPage()));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              child: const Text("CONECTAR AHORA"),
            )
          else
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _openStripeDashboard();
              },
              icon: const Icon(Icons.dashboard_customize, size: 18),
              label: const Text("VER MIS GANANCIAS"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.black54),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final localL10n = AppLocalizations.of(context)!;

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'displayName': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'vehicleDescription': _vehicleController.text.trim(),
      });
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(localL10n.client_prof_update_success)));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _changeProfilePicture() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 🔒 CAPA DE SEGURIDAD LAD: Huella dactilar obligatoria para cambiar foto
    final bool isAuthentic = await _userService.authenticateBiometric(
      reason: "Confirma tu identidad para cambiar la foto oficial del perfil."
    );

    if (!isAuthentic) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ ACCESO DENEGADO: Identidad no verificada."), backgroundColor: Colors.red)
        );
      }
      return;
    }

    if (!mounted) return; // 🛡️ COMPROBACIÓN DE CONTEXTO

    try {
      final url = await _storageService.uploadProfilePicture(user.uid, context);
      if (url != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'photoURL': url,
          'lastBiometricVerification': FieldValue.serverTimestamp(), 
        });
        if (mounted) setState(() => _photoUrl = url);
      }
    } catch (e) { debugPrint(e.toString()); }
  }

  void _switchToClientRole() async {
    final res = await _authService.switchUserRole(newRole: 'CLIENT');
    if (res == "SUCCESS" && mounted) {
      Navigator.of(context).pop();
    }
  }
}