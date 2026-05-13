import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart'; // 🟢 Importación vital
import 'package:lad_courier/l10n/app_localizations.dart';
import 'package:lad_courier/models/user_model.dart';
import 'package:lad_courier/services/storage_service.dart';
import 'package:lad_courier/services/stripe_service.dart';
import 'package:lad_courier/auth_service.dart';
import 'package:lad_courier/screens/subscription_page.dart';
import 'package:lad_courier/pages/client/completed_orders_page.dart';

class ClientProfilePage extends StatefulWidget {
  const ClientProfilePage({super.key});
  @override
  State<ClientProfilePage> createState() => _ClientProfilePageState();
}

class _ClientProfilePageState extends State<ClientProfilePage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final StorageService _storageService = StorageService();
  final AuthService _authService = AuthService();
  final StripeService _stripeService = StripeService();

  bool _isSaving = false;
  UserModel? _userModel;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
  }

  // 🟢 LÓGICA DE ELIMINACIÓN REFORZADA CON CLOUD FUNCTIONS
  void _confirmDeleteAccount() {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.delete_account_confirm_title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text(l10n.delete_account_confirm_body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.common_cancel, style: const TextStyle(color: Colors.black))),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              try {
                // 🛡️ Buscamos la función en la región correcta (us-central1)
                final HttpsCallable callable = FirebaseFunctions.instanceFor(region: 'us-central1')
                    .httpsCallable('deleteUserAccount');
                
                final result = await callable.call();

                if (mounted && result.data['success'] == true) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("✅ Cuenta y datos de Stripe eliminados."), backgroundColor: Colors.black)
                  );
                }
              } catch (e) {
                if (mounted) {
                  debugPrint("❌ Error al borrar: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)
                  );
                }
              }
            },
            child: Text(l10n.delete_account_btn_confirm, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) return const Scaffold(body: Center(child: Text("Inicia sesión")));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _userModel == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.black)));
        }
        
        if (snapshot.hasData && snapshot.data!.exists) {
          _userModel = UserModel.fromFirestore(snapshot.data!);
          // Actualizamos controladores solo si no estamos editando activamente
          if (!_isSaving) {
            _nameController.text = _userModel?.displayName ?? '';
            _phoneController.text = _userModel?.phoneNumber ?? '';
            _addressController.text = _userModel?.mainAddress ?? '';
            _photoUrl = _userModel?.photoURL;
          }
        }

        final bool hasPayment = _userModel?.defaultPaymentMethodId != null;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
              title: Text(l10n.client_prof_title, style: const TextStyle(fontWeight: FontWeight.w900)),
              centerTitle: true,
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 50),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildProfileHeader(),
              const SizedBox(height: 30),

              // ✨ NOTA DE TRANSPARENCIA LEGAL
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "LAD Courier es una plataforma gratuita para clientes. Tus pagos se realizan directamente al driver por el servicio acordado.",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey[800]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _buildSectionHeader(l10n.client_prof_contact_details, Colors.blueGrey[50]!),
              const SizedBox(height: 15),
              _buildTextField(controller: _nameController, icon: Icons.person, label: l10n.client_prof_name_label),
              _buildTextField(controller: _phoneController, icon: Icons.phone, label: l10n.client_prof_phone_label),
              _buildTextField(controller: _addressController, icon: Icons.location_on, label: l10n.client_prof_address_label),
              const SizedBox(height: 30),

              _buildSectionHeader(l10n.client_prof_payment_methods, Colors.indigo[50]!),
              const SizedBox(height: 15),
              
              // 💳 TARJETA DE STRIPE DINÁMICA (REFORZADA)
              _buildPaymentCard(
                title: hasPayment ? "✅ SISTEMA DE PAGO ACTIVADO" : l10n.client_prof_stripe_title,
                subtitle: hasPayment ? "Tu tarjeta está vinculada de forma segura" : l10n.client_prof_stripe_subtitle,
                icon: hasPayment ? Icons.verified_user : Icons.credit_card,
                color: hasPayment ? Colors.green[700]! : Colors.indigo,
                isLinked: hasPayment,
                onTap: () async {
                  try {
                    await _stripeService.setupPaymentMethod();
                    // Al ser un StreamBuilder, el color cambiará solo cuando Stripe actualice Firebase vía Webhook
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                    );
                  }
                },
              ),

              _buildMenuTile(
                title: l10n.client_prof_completed_orders,
                icon: Icons.history_rounded,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CompletedOrdersPage())),
              ),

              const SizedBox(height: 30),
              _buildMessengerCTA(l10n),
              const SizedBox(height: 40),
              SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: FilledButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: FilledButton.styleFrom(backgroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      child: Text(l10n.client_prof_save_button, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.greenAccent))
                  )
              ),
              const SizedBox(height: 25),
              Center(child: TextButton.icon(onPressed: _switchToDriverRole, icon: const Icon(Icons.swap_horiz, color: Colors.black), label: Text(l10n.client_prof_switch_button, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black)))),

              const SizedBox(height: 50),
              const Divider(),
              const SizedBox(height: 20),

              Center(
                child: TextButton.icon(
                  onPressed: _confirmDeleteAccount,
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  label: Text(l10n.common_delete_account, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, Color bgColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
      child: Text(title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.black87, letterSpacing: 1.1)),
    );
  }

  Widget _buildMenuTile({required String title, required IconData icon, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.amber[800]),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black87)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    );
  }

  Widget _buildMessengerCTA(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.deepPurple[50], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.3), width: 2)),
      child: Column(children: [
        const Icon(Icons.rocket_launch, color: Colors.deepPurple, size: 40),
        const SizedBox(height: 12),
        Text(l10n.client_prof_cta_title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.deepPurple)),
        const SizedBox(height: 8),
        Text(l10n.client_prof_cta_body, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 15),
        FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SubscriptionPage())), style: FilledButton.styleFrom(backgroundColor: Colors.deepPurple), child: Text(l10n.client_prof_cta_button, style: const TextStyle(fontWeight: FontWeight.w900))),
      ]),
    );
  }

  Widget _buildProfileHeader() {
    return Center(child: Stack(children: [
      CircleAvatar(radius: 65, backgroundColor: Colors.grey[200], backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null, child: _photoUrl == null ? const Icon(Icons.person, size: 65, color: Colors.black26) : null),
      Positioned(bottom: 0, right: 0, child: CircleAvatar(backgroundColor: Colors.black, radius: 20, child: IconButton(icon: const Icon(Icons.edit, color: Colors.greenAccent, size: 20), onPressed: _changeProfilePicture))),
    ]));
  }

  Widget _buildTextField({required TextEditingController controller, required IconData icon, required String label}) {
    return Padding(padding: const EdgeInsets.only(bottom: 15), child: TextFormField(
      controller: controller, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        prefixIcon: Icon(icon, color: Colors.black),
        filled: true,
        fillColor: Colors.grey[300], // Satin Gray 300
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey[300]!)),
      ),
    ));
  }

  Widget _buildPaymentCard({
    required String title, 
    required String subtitle, 
    required IconData icon, 
    required Color color, 
    required VoidCallback onTap,
    bool isLinked = false,
  }) {
    return Card(
        elevation: isLinked ? 4 : 0,
        margin: const EdgeInsets.only(bottom: 10),
        color: isLinked ? Colors.green[50] : color.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15), 
          side: BorderSide(color: isLinked ? Colors.green : color.withValues(alpha: 0.3), width: 2.0)
        ),
        child: ListTile(
            onTap: onTap,
            leading: Icon(icon, color: isLinked ? Colors.green[700] : color, size: 30),
            title: Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: isLinked ? Colors.green[900] : Colors.black)),
            subtitle: Text(subtitle, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isLinked ? Colors.green[800] : Colors.black87)),
            trailing: Icon(isLinked ? Icons.check_circle : Icons.add_circle_outline, color: isLinked ? Colors.green : Colors.black)
        )
    );
  }

  Future<void> _saveProfile() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(u.uid).update({
        'displayName': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'mainAddress': _addressController.text.trim()
      });
      if (!context.mounted) return;
      scaffoldMessenger.showSnackBar(SnackBar(content: Text(l10n.client_prof_update_success), backgroundColor: Colors.green));
    } catch (e) {
      if (!context.mounted) return;
      scaffoldMessenger.showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _changeProfilePicture() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    final url = await _storageService.uploadProfilePicture(u.uid, context);
    if (url != null) {
      await FirebaseFirestore.instance.collection('users').doc(u.uid).update({'photoURL': url});
      if (mounted) setState(() => _photoUrl = url);
    }
  }

  void _switchToDriverRole() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final res = await _authService.switchUserRole(newRole: 'MESSENGER');
    if (!mounted) return;

    if (res == "SUCCESS") {
      navigator.pop();
    } else {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text(res), backgroundColor: Colors.red));
    }
  }
}