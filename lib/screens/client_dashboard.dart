import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lad_courier/models/order_model.dart';
import 'package:lad_courier/models/user_model.dart';
import 'package:lad_courier/pages/client/client_negotiation_page.dart';
import 'package:lad_courier/pages/client/create_order_page.dart';
import 'package:lad_courier/pages/client/completed_orders_page.dart';
import 'package:lad_courier/screens/client_profile_page.dart';
import 'package:lad_courier/services/order_service.dart';
import 'package:lad_courier/services/user_service.dart';
import 'package:lad_courier/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class ClientDashboard extends StatefulWidget {
  const ClientDashboard({super.key});

  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();
  final OrderService _orderService = OrderService();
  UserModel? _clientProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      final profile = await _userService.getUser(user.uid);
      if (mounted) {
        setState(() {
          _clientProfile = profile;
          _isLoading = false;
        });
      }
    }
  }

  void _showInviteDialog() {
    final l10n = AppLocalizations.of(context)!;
    final TextEditingController codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.prof_radar_title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.client_dash_invite_code_label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                hintText: l10n.client_dash_invite_hint,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.common_cancel.toUpperCase())),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.isNotEmpty) {
                final navigator = Navigator.of(context);
                await _userService.linkMessengerToClient(_auth.currentUser!.uid, codeController.text.trim());
                if (!mounted) return;
                navigator.pop();
                _loadProfile();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            child: Text(l10n.driver_btn_confirm.toUpperCase(), style: const TextStyle(color: Colors.greenAccent)),
          ),
        ],
      ),
    );
  }

  /// 🛡️ SISTEMA LAD: Verificación de Método de Pago antes de ordenar
  bool _checkPaymentMethodStatus(AppLocalizations l10n) {
    if (_clientProfile?.defaultPaymentMethodId == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: Row(
            children: [
              const Icon(Icons.credit_card_off_outlined, color: Colors.redAccent),
              const SizedBox(width: 10),
              Text(l10n.common_payment_required_title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            ],
          ),
          content: Text(l10n.common_payment_required_msg, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.common_cancel.toUpperCase())),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ClientProfilePage())).then((_) => _loadProfile());
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text(l10n.prof_btn_save.toUpperCase(), style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.black)));
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("LAD COURIER", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1, color: Colors.black, size: 26),
            onPressed: _showInviteDialog,
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.black, size: 26),
            tooltip: "Historial 36h",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CompletedOrdersPage())),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: Colors.black, size: 26),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ClientProfilePage())).then((_) => _loadProfile()),
          ),
          const SizedBox(width: 10),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_checkPaymentMethodStatus(l10n)) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateOrderPage(autoStartOCR: false)));
          }
        },
        backgroundColor: Colors.black,
        icon: const Icon(Icons.add_circle_outline, color: Colors.greenAccent),
        label: Text(l10n.client_dash_order_here.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        color: Colors.black,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(l10n),
              const SizedBox(height: 25),
              _buildSectionTitle(l10n.client_dash_active_missions.toUpperCase(), Icons.radar, Colors.indigo[900]!),
              _buildActiveOrdersList(l10n),
              const SizedBox(height: 25),
              _buildSectionTitle(l10n.client_dash_negotiations_title.toUpperCase(), Icons.handshake_outlined, Colors.orange[900]!),
              _buildNegotiationList(l10n),
              const SizedBox(height: 25),
              _buildSectionTitle(l10n.client_dash_linked_drivers.toUpperCase(), Icons.group_outlined, Colors.black),
              _buildMessengerDetailedList(l10n),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: color, letterSpacing: 1.1)),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey[900],
            backgroundImage: _clientProfile?.photoURL != null ? NetworkImage(_clientProfile!.photoURL!) : null,
            child: _clientProfile?.photoURL == null ? const Icon(Icons.person, size: 30, color: Colors.white) : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.client_dash_welcome.toUpperCase(), style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5)),
                Text(_clientProfile?.displayName ?? 'CLIENTE', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
              ],
            ),
          ),
          const Icon(Icons.verified_user, color: Colors.greenAccent, size: 28),
        ],
      ),
    );
  }

  Widget _buildActiveOrdersList(AppLocalizations l10n) {
    final uid = _auth.currentUser?.uid ?? '';
    return StreamBuilder<List<OrderModel>>(
      stream: _orderService.getActiveOrdersForClientStream(uid),
      builder: (context, snapshot) {
        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return Container(
            height: 80,
            decoration: BoxDecoration(color: Colors.indigo[50], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.indigo[100]!)),
            child: Center(child: Text(l10n.client_dash_no_active_missions, style: const TextStyle(color: Colors.indigo, fontSize: 12, fontWeight: FontWeight.bold))),
          );
        }
        return Column(
          children: orders.map((order) {
            double progress = order.status == 'picked_up' ? 0.7 : 0.3;
            String statusText = order.statusMessage?.toUpperCase() ?? l10n.client_dash_order_active;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.indigo[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.indigo[100]!, width: 1),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(radius: 18, backgroundImage: order.messengerPhotoUrl != null ? NetworkImage(order.messengerPhotoUrl!) : null),
                      const SizedBox(width: 10),
                      Expanded(child: Text(order.messengerName ?? 'Driver', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.indigo))),
                      Text("\$${order.price?.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.indigo)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  LinearProgressIndicator(value: progress, backgroundColor: Colors.white, color: Colors.indigo, minHeight: 6, borderRadius: BorderRadius.circular(10)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(statusText, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.indigo)),
                      const Icon(Icons.local_shipping_outlined, size: 14, color: Colors.indigo),
                    ],
                  )
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildNegotiationList(AppLocalizations l10n) {
    final uid = _auth.currentUser?.uid ?? '';
    return StreamBuilder<List<OrderModel>>(
      stream: _orderService.getOrdersForClientResponseStream(uid),
      builder: (context, snapshot) {
        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return Container(
            height: 80,
            decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.orange[100]!)),
            child: Center(child: Text(l10n.client_dash_no_negotiations, style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold))),
          );
        }
        return Column(
          children: orders.map((order) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange[100]!),
              ),
              child: ListTile(
                leading: CircleAvatar(backgroundImage: order.messengerPhotoUrl != null ? NetworkImage(order.messengerPhotoUrl!) : null),
                title: Text("\$${order.negotiationHistory.last['price']}", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.orange)),
                subtitle: Text("OFERTA DE ${order.messengerName?.toUpperCase()}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.orange)),
                trailing: const Icon(Icons.chevron_right, color: Colors.orange),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ClientNegotiationPage(orderId: order.id))),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildMessengerDetailedList(AppLocalizations l10n) {
    final uid = _auth.currentUser?.uid ?? '';
    return StreamBuilder<List<UserModel>>(
      stream: _userService.getLinkedMessengersStream(uid),
      builder: (context, snapshot) {
        final messengers = snapshot.data ?? [];
        if (messengers.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(20)),
            child: Center(child: Text(l10n.client_dash_no_linked_drivers, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12))),
          );
        }
        return Column(
          children: messengers.map((m) => _buildDriverCard(m, l10n)).toList(),
        );
      },
    );
  }

  Widget _buildDriverCard(UserModel m, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: () {
            if (!_checkPaymentMethodStatus(l10n)) return;

            if (!m.isMessengerActive) {
              _showDriverRestingDialog(m, l10n);
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateOrderPage(
                  selectedMessenger: {
                    'id': m.uid,
                    'name': m.displayName,
                    'photoURL': m.photoURL,
                    'availableServices': m.availableServices,
                  },
                ),
              ),
            );
          },
          child: Padding(padding: const EdgeInsets.all(15), child: _buildDriverCardContent(m, l10n)),
        ),
      ),
    );
  }

  Widget _buildDriverCardContent(UserModel m, AppLocalizations l10n) {
    return Column(
      children: [
        Row(
          children: [
            Stack(
              children: [
                CircleAvatar(radius: 30, backgroundImage: m.photoURL != null ? NetworkImage(m.photoURL!) : null, child: m.photoURL == null ? const Icon(Icons.person) : null),
                Positioned(right: 0, bottom: 0, child: Container(width: 16, height: 16, decoration: BoxDecoration(color: m.isMessengerActive ? Colors.green : Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
              ],
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.displayName?.toUpperCase() ?? 'DRIVER', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.black)),
                  const SizedBox(height: 4),
                  Text(m.isMessengerActive ? l10n.client_dash_driver_available : l10n.client_dash_driver_resting, style: TextStyle(color: m.isMessengerActive ? Colors.green : Colors.grey[600], fontWeight: FontWeight.w900, fontSize: 10)),
                  if (m.vehicleDescription != null) ...[
                    const SizedBox(height: 4),
                    Text(m.vehicleDescription!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.phone_in_talk, color: Colors.green, size: 28),
              onPressed: () => m.phoneNumber != null ? launchUrl(Uri.parse("tel:${m.phoneNumber}")) : null,
            ),
          ],
        ),
        const Divider(height: 25, color: Colors.black12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.client_dash_services_label(m.availableServices.join(", ")), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text("${l10n.client_dash_plan_label(m.subscriptionType?.toUpperCase() ?? 'LITE')} • ${l10n.client_dash_radius_label(m.maxRadiusMiles.toStringAsFixed(0))} mi", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black54)),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _confirmUnlink(m, l10n),
              child: Text(l10n.client_dash_unlink_button, style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ],
    );
  }

  void _showDriverRestingDialog(UserModel m, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.bedtime, color: Colors.orange),
            const SizedBox(width: 10),
            Text(l10n.client_dash_driver_resting.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
        content: Text(l10n.client_dash_driver_resting_body(m.displayName ?? 'Driver'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.common_cancel.toUpperCase(), style: const TextStyle(color: Colors.black))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateOrderPage(autoStartOCR: false)));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            child: Text(l10n.create_order_search_available.toUpperCase(), style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _confirmUnlink(UserModel m, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.client_dash_unlink_title),
        content: Text(l10n.client_dash_unlink_confirm(m.displayName ?? 'Driver')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.common_cancel)),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              await _userService.unlinkMessenger(_auth.currentUser!.uid, m.uid);
              if (!mounted) return;
              navigator.pop();
              messenger.showSnackBar(SnackBar(content: Text(l10n.client_dash_unlink_success)));
              _loadProfile();
            },
            child: Text(l10n.client_dash_unlink_button, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
