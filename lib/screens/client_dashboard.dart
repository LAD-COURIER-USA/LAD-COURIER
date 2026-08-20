import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // ✅ AÑADIDO PARA kIsWeb
import 'package:lad_courier/models/order_model.dart';
import 'package:lad_courier/models/user_model.dart';
import 'package:lad_courier/pages/client/client_negotiation_page.dart';
import 'package:lad_courier/pages/client/create_order_page.dart';
import 'package:lad_courier/pages/client/completed_orders_page.dart';
import 'package:lad_courier/screens/client_profile_page.dart';
import 'package:lad_courier/services/order_service.dart';
import 'package:lad_courier/services/user_service.dart';
import 'package:lad_courier/services/chat_service.dart';
import 'package:image_picker/image_picker.dart'; // ✅ AÑADIDO PARA BINGO WEB
import 'package:lad_courier/l10n/app_localizations.dart';
import 'package:lad_courier/auth/auth_gate.dart'; // 🚀 AÑADIDO PARA LOGOUT
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:lad_courier/screens/chat_screen.dart';
import 'package:lad_courier/widgets/invitation_card.dart'; // ✅ AÑADIDO PARA VINCULACIÓN
import 'package:shared_preferences/shared_preferences.dart'; // ✅ AÑADIDO PARA MEMORIA LOCAL
import 'package:universal_html/html.dart' as html; // 🚀 AÑADIDO PARA LEER URL
import 'package:cloud_firestore/cloud_firestore.dart'; // 🚀 AÑADIDO PARA VERIFICAR DB
import 'package:lad_courier/services/stripe_mode_service.dart'; // 🧬 IMPORTACIÓN DOBLE ADN


class ClientDashboard extends StatefulWidget {
  const ClientDashboard({super.key});

  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();
  final OrderService _orderService = OrderService();
  final ChatService _chatService = ChatService();
  
  // 🛡️ REFUERZO V18.7: Instanciación bajo demanda para evitar crash en Web
  FlutterLocalNotificationsPlugin? _localNotifications;
  
  UserModel? _clientProfile;
  
  StreamSubscription? _negotiationSubscription;
  StreamSubscription? _rejectionSubscription; 
  Map<String, int> _lastKnownOffersState = {};
  Map<String, String> _lastKnownRejectedState = {};

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _localNotifications = FlutterLocalNotificationsPlugin();
      _initializeNotifications();
    }
    _loadProfile();
    _startNegotiationListener();
    _startRejectionListener(); 
    
    // 🛡️ VIGILANTE SOBERANO DE VINCULACIÓN: 
    // Buscamos invitaciones pendientes en cuanto el Dashboard esté listo.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPendingInvitations(isManual: false));
  }

  Future<void> _checkPendingInvitations({bool isManual = false}) async {
    try {
      String? foundId;

      // 🛡️ REFUERZO V2026: Escaneo de URL en tiempo real en el Dashboard
      if (kIsWeb) {
        try {
          final String href = html.window.location.href;
          debugPrint("SISTEMA LAD: Escaneando URL en Dashboard -> $href");
          
          // Radar Regex: Busca id o ref en la URL actual (social links)
          final regExp = RegExp(r'[?&](id|ref)=([^&#/]+)');
          final match = regExp.firstMatch(href);
          if (match != null) {
            foundId = match.group(2);
            debugPrint("SISTEMA LAD: Driver pescado de URL en Dashboard -> $foundId");
          }
          
          // Respaldo: LocalStorage y Cookies
          if (foundId == null || foundId.isEmpty) {
            foundId = html.window.localStorage['pending_messenger_invitation'];
            
            if (foundId == null || foundId.isEmpty) {
              final String cookies = html.document.cookie ?? "";
              final List<String> cookieList = cookies.split(';');
              for (var cookie in cookieList) {
                if (cookie.trim().startsWith('pending_messenger_invitation=')) {
                  foundId = cookie.split('=')[1].trim();
                  break;
                }
              }
            }
          }
        } catch (_) {}
      }

      // Si no estaba en la URL/Navegador, buscamos en memoria interna (Android)
      if (foundId == null || foundId.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        foundId = prefs.getString('pending_messenger_invitation');
      }

      if (foundId != null && foundId.isNotEmpty) {
        final String cleanId = foundId.trim();
        // Verificamos si ya está vinculado consultando la DB directamente
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(_auth.currentUser!.uid).get();
        final List<dynamic> linkedIds = userDoc.data()?['linkedMessengerIds'] ?? [];
        
        if (!linkedIds.contains(cleanId)) {
          _showInvitationCard(cleanId);
        } else {
          // Si ya está vinculado, limpiamos los rastros locales para no repetir
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('pending_messenger_invitation');
          if (kIsWeb) {
            html.window.localStorage.remove('pending_messenger_invitation');
          }
          
          if (isManual && mounted) {
            final localL10n = AppLocalizations.of(context)!;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(localL10n.client_dash_already_linked), backgroundColor: Colors.blueGrey)
            );
          }
        }
      } else if (isManual && mounted) {
        final localL10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localL10n.client_dash_no_new_invitations), backgroundColor: Colors.orange)
        );
      }
    } catch (e) {
      debugPrint("SISTEMA LAD ERROR: Fallo al verificar invitaciones: $e");
    }
  }

  void _showInvitationCard(String driverId) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => InvitationCard(
        messengerId: driverId,
        onAccept: () async {
          final user = _auth.currentUser;
          final navigator = Navigator.of(context);
          if (user != null) {
            await _userService.linkMessengerToClient(user.uid, driverId);
          }
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('pending_messenger_invitation');
          navigator.pop();
          _loadProfile(); // Recargamos para ver al nuevo driver en la lista
        },
        onReject: () async {
          final navigator = Navigator.of(context);
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('pending_messenger_invitation');
          navigator.pop();
        },
      ),
    );
  }

  void _startRejectionListener() {
    final user = _auth.currentUser;
    if (user == null) return;

    _rejectionSubscription?.cancel();
    _rejectionSubscription = _orderService.getRejectedOrdersStream(user.uid).listen((orders) {
      if (!mounted) return;
      final localL10n = AppLocalizations.of(context)!;
      
      for (var o in orders) {
        if (!_lastKnownRejectedState.containsKey(o.id)) {
          _triggerAlert(localL10n.alert_rejected_title, localL10n.alert_rejected_body(o.messengerName ?? ''));
        }
      }
      _lastKnownRejectedState = {for (var o in orders) o.id: o.status};
    });
  }

  Future<void> _initializeNotifications() async {
    if (_localNotifications == null) return;
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    await _localNotifications!.initialize(initializationSettings);
  }

  void _startNegotiationListener() {
    final user = _auth.currentUser;
    if (user == null) return;

    _negotiationSubscription?.cancel();
    _negotiationSubscription = _orderService.getOrdersForClientResponseStream(user.uid).listen((orders) {
      if (!mounted) return;
      final localL10n = AppLocalizations.of(context)!;

      if (_lastKnownOffersState.isNotEmpty) {
        for (var o in orders) {
          bool isUpdated = _lastKnownOffersState.containsKey(o.id) && 
                           o.negotiationHistory.length > _lastKnownOffersState[o.id]!;

          if (isUpdated && o.lastPriceOfferedBy == 'driver') {
            _triggerAlert(localL10n.alert_new_offer_title, localL10n.alert_new_offer_body(o.messengerName ?? ''));
          }
        }
      }
      _lastKnownOffersState = {for (var o in orders) o.id: o.negotiationHistory.length};
    });
  }

  void _triggerAlert(String title, String body) async {
    HapticFeedback.vibrate();
    if (kIsWeb || _localNotifications == null) return;
    
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'high_importance_channel', 'Alertas de Pedidos Urgentes',
      importance: Importance.max, priority: Priority.high, playSound: true,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await _localNotifications!.show(DateTime.now().millisecond, title, body, platformChannelSpecifics);
  }

  @override
  void dispose() {
    _negotiationSubscription?.cancel();
    _rejectionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      final profile = await _userService.getUser(user.uid);
      if (mounted) {
        setState(() {
          _clientProfile = profile;
        });
      }
    }
  }

  Future<void> _logout() async {
    final l10n = AppLocalizations.of(context)!;

    // 🛡️ REFUERZO SOBERANO: Bloqueo de Logout si está ONLINE como Driver
    if (_clientProfile?.isMessengerActive ?? false) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(l10n.common_access_denied, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.red)),
          content: Text(l10n.logout_online_error),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.common_understood, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
            )
          ],
        ),
      );
      return;
    }

    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.common_logout, style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Text(l10n.common_logout_confirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.common_cancel.toUpperCase())),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.common_exit, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthGate()),
          (route) => false,
        );
      }
    }
  }

  bool _checkPaymentMethodStatus(AppLocalizations l10n, UserModel? profile) {
    // 🛡️ PASE VIP: El inspector no necesita tarjeta
    if (profile?.isVipTester ?? false) return true;

    final bool isLive = StripeModeService().isLive();
    final String? paymentMethodId = profile?.getActivePaymentMethodId(isLive);

    debugPrint("🛡️ SISTEMA LAD: Verificando pago [Modo: ${isLive ? 'LIVE' : 'TEST'}] [ID: $paymentMethodId]");

    if (paymentMethodId == null) {
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
    final user = _auth.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Sesión expirada")));
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<UserModel?>(
      stream: _userService.getUserStream(user.uid),
      builder: (context, profileSnapshot) {
        if (profileSnapshot.hasError) {
          debugPrint("❌ SISTEMA LAD: Error en Stream de Perfil: ${profileSnapshot.error}");
        }

        if (profileSnapshot.connectionState == ConnectionState.waiting && _clientProfile == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.black)));
        }
        
        if (profileSnapshot.hasData) {
          _clientProfile = profileSnapshot.data;
          debugPrint("🛡️ SISTEMA LAD: Perfil Cargado [${_clientProfile?.displayName}] [Payment Live: ${_clientProfile?.defaultPaymentMethodIdLive}]");
        }

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
                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                onPressed: _logout,
                tooltip: "Cerrar Sesión",
              ),
              IconButton(
                icon: const Icon(Icons.history, color: Colors.black, size: 26),
                tooltip: "Historial 36h",
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CompletedOrdersPage())),
              ),
              const SizedBox(width: 10),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              if (_checkPaymentMethodStatus(l10n, profileSnapshot.data)) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateOrderPage(autoStartOCR: false)));
              }
            },
            backgroundColor: Colors.black,
            icon: const Icon(Icons.add_circle_outline, color: Colors.greenAccent),
            label: Text(l10n.client_dash_order_here.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
          body: Stack(
            children: [
              RefreshIndicator(
                onRefresh: _loadProfile,
                color: Colors.black,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeSection(l10n),
                      const SizedBox(height: 20),
                      
                      // 🚀 NUEVA SECCIÓN BINGO UNIVERSAL (V19.9)
                      _buildBingoQuickAction(l10n),
                      
                      const SizedBox(height: 25),
                      _buildSectionTitle(l10n.client_dash_active_missions.toUpperCase(), Icons.radar, Colors.indigo[900]!),
                      _buildActiveOrdersList(l10n),
                      const SizedBox(height: 25),
                      _buildSectionTitle(l10n.client_dash_negotiations_title.toUpperCase(), Icons.handshake_outlined, Colors.orange[900]!),
                      _buildNegotiationList(l10n),
                      const SizedBox(height: 25),
                      _buildSectionTitle(l10n.client_dash_rejected_requests_title.toUpperCase(), Icons.warning_amber_rounded, Colors.red[900]!),
                      _buildRejectedOrdersList(l10n),
                      const SizedBox(height: 25),
                      _buildSectionTitle(l10n.client_dash_linked_drivers.toUpperCase(), Icons.group_outlined, Colors.black, onAction: () => _checkPendingInvitations(isManual: true)),
                      _buildMessengerDetailedList(l10n),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
              
              // 💬 NOTIFICACIÓN DE CHAT FLOTANTE PARA EL CLIENTE
              if (_clientProfile?.lastIncomingChatId != null)
                Positioned(
                  right: 20,
                  bottom: 100, // Encima del FAB
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(10)),
                        child: Text(
                          "CHAT: ${_clientProfile!.lastIncomingChatTitle ?? 'DRIVER'}",
                          style: const TextStyle(color: Colors.greenAccent, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 5),
                      CircleAvatar(
                        backgroundColor: Colors.greenAccent,
                        radius: 28,
                        child: IconButton(
                          icon: const Icon(Icons.chat, color: Colors.black),
                          onPressed: () async {
                            final chatId = _clientProfile!.lastIncomingChatId;
                            final chatTitle = _clientProfile!.lastIncomingChatTitle;
                            final navigator = Navigator.of(context);

                            // 🧹 LIMPIEZA INMEDIATA
                            if (chatId != null) {
                              await _chatService.clearChatNotification(user.uid);
                              
                              if (mounted) {
                                navigator.push(MaterialPageRoute(builder: (_) => ChatScreen(
                                  chatId: chatId,
                                  title: chatTitle ?? 'Driver',
                                )));
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color, {VoidCallback? onAction}) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: color, letterSpacing: 1.1))),
          if (onAction != null)
            TextButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.sync, size: 16, color: Colors.deepPurple),
              label: Text(l10n.common_sync, style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.w900, fontSize: 10)),
              style: TextButton.styleFrom(
                backgroundColor: Colors.deepPurple.withValues(alpha: 0.1),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(AppLocalizations l10n) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context, 
        MaterialPageRoute(builder: (context) => const ClientProfilePage())
      ).then((_) => _loadProfile()),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 8))],
          border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.grey[900],
                  backgroundImage: _clientProfile?.photoURL != null ? NetworkImage(_clientProfile!.photoURL!) : null,
                  child: _clientProfile?.photoURL == null ? const Icon(Icons.person, size: 35, color: Colors.white) : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                    child: const Icon(Icons.edit, size: 12, color: Colors.black),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.client_dash_welcome.toUpperCase(), style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5)),
                  Text(_clientProfile?.displayName ?? 'CLIENTE', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
                  const Text("VER PERFIL Y PAGOS", style: TextStyle(color: Colors.white60, fontWeight: FontWeight.bold, fontSize: 9, letterSpacing: 1)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.greenAccent, size: 30),
          ],
        ),
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
            bool isDelayed = order.statusMessage == "DELIVERY_DELAYED";
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: isDelayed ? Colors.red[50] : Colors.indigo[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDelayed ? Colors.red[200]! : Colors.indigo[100]!, width: 1),
              ),
              child: Column(
                children: [
                  if (isDelayed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(l10n.order_status_delivery_delayed_msg, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 9))),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      CircleAvatar(radius: 18, backgroundImage: order.messengerPhotoUrl != null ? NetworkImage(order.messengerPhotoUrl!) : null),
                      const SizedBox(width: 10),
                      Expanded(child: Text(order.messengerName ?? 'Driver', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: isDelayed ? Colors.red[900] : Colors.indigo))),
                      IconButton(
                        icon: Icon(Icons.chat_bubble_outline, color: isDelayed ? Colors.red[900] : Colors.indigo),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(
                          chatId: order.id, 
                          title: order.messengerName ?? 'Driver',
                          targetUserId: order.assignedMessengerId,
                          senderName: _clientProfile?.displayName ?? "Cliente",
                        ))),
                      ),
                      const SizedBox(width: 10),
                      Text("\$${order.price?.toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.w900, color: isDelayed ? Colors.red[900] : Colors.indigo)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  LinearProgressIndicator(value: progress, backgroundColor: Colors.white, color: isDelayed ? Colors.red : Colors.indigo, minHeight: 6, borderRadius: BorderRadius.circular(10)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isDelayed ? l10n.order_status_delivery_delayed : statusText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isDelayed ? Colors.red : Colors.indigo)),
                      Row(
                        children: [
                          if (order.status == OrderStatus.active)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Container(
                                decoration: BoxDecoration(
                                  boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () => _confirmCancelOrder(order.id, l10n),
                                  icon: const Icon(Icons.cancel, size: 12, color: Colors.white),
                                  label: Text(l10n.common_cancel.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                    minimumSize: const Size(0, 30),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ),
                          Icon(Icons.local_shipping_outlined, size: 14, color: isDelayed ? Colors.red : Colors.indigo),
                        ],
                      ),
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
            bool isWaitingForMessenger = order.lastPriceOfferedBy == 'client';
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                color: isWaitingForMessenger ? Colors.grey[100] : Colors.orange[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isWaitingForMessenger ? Colors.grey[300]! : Colors.orange[100]!),
              ),
              child: InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ClientNegotiationPage(orderId: order.id))),
                child: Row(
                  children: [
                    CircleAvatar(radius: 22, backgroundImage: order.messengerPhotoUrl != null ? NetworkImage(order.messengerPhotoUrl!) : null),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  isWaitingForMessenger ? "ORDEN ENVIADA" : "\$${order.negotiationHistory.last['price']}", 
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isWaitingForMessenger ? Colors.black54 : Colors.orange),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chat_outlined, color: Colors.orange, size: 22),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(
                                  chatId: order.id, 
                                  title: order.messengerName ?? 'Driver',
                                  targetUserId: order.assignedMessengerId,
                                  senderName: _clientProfile?.displayName ?? "Cliente",
                                ))),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  isWaitingForMessenger ? "ESPERANDO RESPUESTA" : "OFERTA RECIBIDA", 
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isWaitingForMessenger ? Colors.black45 : Colors.orange),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () => _confirmCancelOrder(order.id, l10n),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red, width: 1),
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  minimumSize: const Size(0, 24),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(l10n.common_cancel.toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildRejectedOrdersList(AppLocalizations l10n) {
    final uid = _auth.currentUser?.uid ?? '';
    return StreamBuilder<List<OrderModel>>(
      stream: _orderService.getRejectedOrdersStream(uid),
      builder: (context, snapshot) {
        final orders = snapshot.data ?? [];
        if (orders.isEmpty) return const SizedBox.shrink();

        return Column(
          children: orders.map((order) {
            String msg = l10n.order_status_rejected;
            if (order.statusMessage == "TIMEOUT_CLIENT") msg = l10n.order_status_timeout_client;
            if (order.statusMessage == "TIMEOUT_DRIVER" || order.statusMessage == "DRIVER_BUSY") msg = l10n.order_status_driver_busy;
            if (order.statusMessage == "ROUTE_PROBLEMS") msg = l10n.order_status_route_problems;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red[100]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg, 
                              style: TextStyle(
                                fontWeight: FontWeight.w900, 
                                fontSize: 11, 
                                color: (order.statusMessage?.contains("TIMEOUT") == true || order.statusMessage?.contains("BUSY") == true) ? Colors.orange[900] : Colors.red
                              )
                            ),
                            Text(order.messengerName ?? 'Driver', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _confirmCancelOrder(order.id, l10n),
                          icon: const Icon(Icons.delete_sweep_outlined, size: 14),
                          label: Text(l10n.common_cancel.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CreateOrderPage(reassignOrder: order),
                              ),
                            );
                          },
                          icon: const Icon(Icons.sync, size: 14),
                          label: Text(l10n.common_reassign, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD1DC), // Rosado claro
                            foregroundColor: Colors.red[900],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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
            if (!_checkPaymentMethodStatus(l10n, _clientProfile)) return;

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
    final uid = _auth.currentUser?.uid ?? '';
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
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.deepPurple, size: 28),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(
                chatId: "chat_${uid.substring(0, 5)}_${m.uid.substring(0, 5)}",
                title: m.displayName ?? 'Driver',
                targetUserId: m.uid,
                senderName: _clientProfile?.displayName ?? "Cliente",
              ))),
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

  Widget _buildBingoQuickAction(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple[900]!, Colors.black],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.deepPurple.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.greenAccent, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.bingo_magic_title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2)),
                    Text(l10n.bingo_magic_subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: _launchBingoWorkflow,
              icon: const Icon(Icons.wallpaper, color: Colors.black),
              label: Text(l10n.bingo_upload_screenshot, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _launchBingoWorkflow() async {
    try {
      final ImagePicker picker = ImagePicker();
      debugPrint("SISTEMA LAD: Abriendo galería para BINGO...");
      
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
      );

      if (image != null) {
        debugPrint("SISTEMA LAD: Imagen seleccionada: ${image.path}. Preparando vuelo...");
        
        if (!mounted) return;

        // 🛡️ REFUERZO: Pequeño respiro para que el sistema recupere el aliento tras cerrar la galería
        await Future.delayed(const Duration(milliseconds: 400));
        
        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateOrderPage(
              initialImage: image,
              autoStartOCR: false,
            ),
          ),
        );
      } else {
        debugPrint("SISTEMA LAD: Selección de imagen cancelada por el usuario.");
      }
    } catch (e) {
      debugPrint("❌ SISTEMA LAD: Error crítico en picker de Dashboard: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No se pudo abrir la galería: $e"), backgroundColor: Colors.red),
        );
      }
    }
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
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              await _userService.unlinkMessenger(_auth.currentUser!.uid, m.uid);
              
              scaffoldMessenger.showSnackBar(SnackBar(content: Text(l10n.client_dash_unlink_success)));
              _loadProfile();
              navigator.pop();
            },
            child: Text(l10n.client_dash_unlink_button, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmCancelOrder(String orderId, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.order_cancel_dialog_title, style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Text(l10n.order_cancel_dialog_body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.common_cancel)),
          ElevatedButton(
            onPressed: () async {
              // 🛡️ REFUERZO V16.8: Capturamos el messenger antes del await
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              try {
                await _orderService.cancelOrder(orderId);
              } catch (e) {
                String errorMsg = e.toString();
                if (e == 'PICKUP_STARTED') {
                  errorMsg = "No se puede cancelar la orden. El conductor ya inició la recogida y los fondos han sido reservados.";
                }
                
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(errorMsg),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.order_cancel_btn_confirm, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
