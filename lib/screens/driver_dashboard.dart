import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lad_courier/models/user_model.dart';
import 'package:lad_courier/screens/driver_profile_page.dart';
import 'package:lad_courier/screens/driver_work_zone_page.dart';
import 'package:lad_courier/screens/subscription_page.dart';
import 'package:lad_courier/screens/biometric_verification_page.dart';
import 'package:lad_courier/services/invitation_service.dart';
import 'package:lad_courier/services/user_service.dart';
import 'package:lad_courier/services/order_service.dart';
import 'package:lad_courier/l10n/app_localizations.dart';
import 'package:lad_courier/auth/auth_gate.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';

const List<String> _allServices = [
  'Paquetería y Mensajería',
  'Logística Especializada',
  'Compras y Encargos',
];

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});
  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  final UserService _userService = UserService();
  final OrderService _orderService = OrderService();
  final InvitationService _invitationService = InvitationService();
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  UserModel? _driverProfile;
  bool _isLoadingProfile = true;
  bool _isToggleLoading = false;

  StreamSubscription? _globalOrdersSubscription;
  Map<String, int> _lastKnownOrdersState = {};

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _fetchDriverProfile();
  }

  Future<void> _initializeNotifications() async {
    try {
      // ESTANDARIZACIÓN LAD: Usamos el icono por defecto para evitar PlatformException en Release
      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

      await _localNotifications.initialize(initializationSettings);
      debugPrint("✅ SISTEMA LAD: Notificaciones inicializadas.");
    } catch (e) {
      debugPrint("⚠️ SISTEMA LAD: Error silencioso en inicialización de notificaciones: $e");
    }
  }

  Future<void> _fetchDriverProfile() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final profile = await _userService.getUser(currentUser.uid);
      if (mounted) {
        setState(() {
          _driverProfile = profile;
          _isLoadingProfile = false;
        });
        if (profile?.isMessengerActive ?? false) {
          _startGlobalOrderListener(profile!.uid);
        }
      }
    }
  }

  void _startGlobalOrderListener(String uid) {
    _globalOrdersSubscription?.cancel();
    _globalOrdersSubscription = _orderService.getNegotiatingOrdersStream(uid).listen((orders) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      if (l10n == null) return;

      if (_lastKnownOrdersState.isNotEmpty) {
        for (var o in orders) {
          bool isNew = !_lastKnownOrdersState.containsKey(o.id);
          bool isUpdated = !isNew && o.negotiationHistory.length > _lastKnownOrdersState[o.id]!;

          if (isNew) {
            _triggerNotification(
                l10n.notification_new_order_title,
                l10n.notification_new_order_body
            );
          } else if (isUpdated && o.lastPriceOfferedBy == 'client') {
            _triggerNotification(
                "🚀 CONTRAOFERTA RECIBIDA",
                "El cliente ${o.clientName} ha respondido a tu propuesta."
            );
          }
        }
      }
      _lastKnownOrdersState = {for (var o in orders) o.id: o.negotiationHistory.length};
    });
  }

  void _triggerNotification(String title, String body) async {
    HapticFeedback.vibrate();

    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'global_orders_channel', 'Notificaciones Globales de Órdenes',
      importance: Importance.max, priority: Priority.high, playSound: true, enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    try {
      await _localNotifications.show(DateTime.now().millisecond, title, body, platformChannelSpecifics);
    } catch (e) {
      debugPrint("⚠️ SISTEMA LAD: Error al mostrar notificación: $e");
    }
  }

  Future<void> _logout() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("CERRAR SESIÓN", style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text("¿Estás seguro de que quieres salir? Tendrás que poner tu email y contraseña de nuevo para refrescar la seguridad."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCELAR")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("SALIR", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
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

  String _getTranslatedServiceName(BuildContext context, String serviceId) {
    final l10n = AppLocalizations.of(context)!;
    switch (serviceId) {
      case 'Paquetería y Mensajería':
        return l10n.driver_service_courier;
      case 'Logística Especializada':
        return l10n.driver_service_logistics;
      case 'Compras y Encargos':
        return l10n.driver_service_shopping;
      default:
        return serviceId;
    }
  }

  Future<void> _toggleStatus(bool isGoingOnline) async {
    if (_driverProfile == null) return;

    final l10n = AppLocalizations.of(context)!;

    if (isGoingOnline) {
      if (_driverProfile!.photoURL == null || _driverProfile!.photoURL!.isEmpty) {
        _showErrorDialog(l10n.driver_error_no_photo, l10n.driver_error_no_photo_msg);
        return;
      }
      if (_driverProfile!.displayName == null || _driverProfile!.displayName!.isEmpty ||
          _driverProfile!.phoneNumber == null || _driverProfile!.phoneNumber!.isEmpty) {
        _showErrorDialog(l10n.driver_error_incomplete_data, l10n.driver_error_incomplete_data_msg);
        return;
      }
      if (_driverProfile!.vehicleDescription == null || _driverProfile!.vehicleDescription!.isEmpty) {
        _showErrorDialog(l10n.driver_error_no_vehicle, l10n.driver_error_no_vehicle_msg);
        return;
      }

      // 💳 SEGURIDAD: STRIPE ES INDISPENSABLE PARA COBRAR
      final bool isStripeActive = _driverProfile!.isStripeConnected || _driverProfile!.stripeStatus == 'active';
      if (!isStripeActive) {
        _showErrorDialog(l10n.driver_error_no_stripe, l10n.driver_error_no_stripe_msg);
        return;
      }

      // 🛡️ SEGURIDAD: COMPROBACIÓN DE IDENTIDAD
      final String status = _driverProfile!.verificationStatus;
      final bool isIdentityVerified = status == 'APROBADO' || status == 'APROBADO_DOC' || _driverProfile!.isIdentityVerified;

      if (!isIdentityVerified) {
        _showErrorDialog(l10n.driver_error_no_verification, l10n.driver_error_no_verification_msg);
        return;
      }

      if (_driverProfile!.subscriptionType == null || _driverProfile!.subscriptionStatus != 'active') {
        _showErrorDialog(l10n.driver_error_no_membership, l10n.driver_error_no_membership_msg);
        return;
      }

      if (_driverProfile!.availableServices.isEmpty) {
        _showErrorDialog(l10n.driver_error_no_services, l10n.driver_error_no_services_msg);
        return;
      }

      // 🤳 SEGURIDAD MANDATORIA: Selfie + Huella SIEMPRE al iniciar
      _showBiometricPrompt();

    } else {
      final activeOrders = await _orderService.getActiveOrdersOnce(_driverProfile!.uid);
      if (!mounted) return;
      if (activeOrders.isNotEmpty) {
        _showSnackBar(l10n.driver_active_missions_alert, Colors.red);
        return;
      }
      _processStatusChange(false);
    }
  }

  Future<void> _processStatusChange(bool online) async {
    if (!mounted) return;
    setState(() { _isToggleLoading = true; });

    try {
      await _userService.updateMessengerActiveStatus(_driverProfile!.uid, online, context);
      if (!mounted) return;
      setState(() {
        _driverProfile = _driverProfile!.copyWith(isMessengerActive: online);
      });
      if (online) {
        _startGlobalOrderListener(_driverProfile!.uid);
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const DriverWorkZonePage()));
      } else {
        _globalOrdersSubscription?.cancel();
        _lastKnownOrdersState.clear();
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: $e', Colors.red);
    } finally {
      if (mounted) setState(() { _isToggleLoading = false; });
    }
  }

  void _showBiometricPrompt() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("🛡️ VERIFICACIÓN OBLIGATORIA", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blueAccent)),
        content: const Text("Por seguridad, debes validar tu identidad con una selfie y tu huella dactilar para comenzar a trabajar.", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BiometricVerificationPage()),
              );
              if (success == true) {
                _processStatusChange(true);
              }
            },
            child: const Text("CONTINUAR", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blueAccent)),
          )
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.red)),
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.driver_btn_understand, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
          )
        ],
      ),
    );
  }

  void _showSnackBar(String m, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(m, style: const TextStyle(fontWeight: FontWeight.w900)), backgroundColor: c)
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.black)));
    final l10n = AppLocalizations.of(context)!;
    final bool isActive = _driverProfile?.isMessengerActive ?? false;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(l10n.driver_dash_title, style: const TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: _logout,
            tooltip: "Cerrar Sesión",
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDriverProfile,
        color: Colors.black,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildStatusCard(isActive, l10n),
              const SizedBox(height: 30),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                childAspectRatio: 1.1,
                children: [
                  _buildActionCard(l10n.driver_menu_services, Icons.inventory_2, Colors.orange[800]!, Colors.orange[50]!, () => _showServicesDialog(context)),
                  _buildActionCard(l10n.driver_menu_profile, Icons.admin_panel_settings, Colors.blue[800]!, Colors.blue[50]!, () async {
                    await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const DriverProfilePage()));
                    _fetchDriverProfile();
                  }),
                  _buildActionCard(l10n.driver_menu_earnings, Icons.map, Colors.green[700]!, Colors.green[50]!, () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => const SubscriptionPage()));
                    _fetchDriverProfile();
                  }),
                  _buildActionCard(l10n.driver_menu_invite, Icons.share, Colors.purple[800]!, Colors.purple[50]!, () => _invitationService.shareInvitationLink(context)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(bool isActive, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: isActive ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.black, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))]
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: _driverProfile?.photoURL != null ? NetworkImage(_driverProfile!.photoURL!) : null,
                child: _driverProfile?.photoURL == null ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isActive ? l10n.driver_status_online : l10n.driver_status_offline,
                      style: TextStyle(color: isActive ? Colors.greenAccent : Colors.grey[700], fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                    Text(
                      _driverProfile?.displayName ?? 'DRIVER',
                      style: TextStyle(color: isActive ? Colors.white : Colors.black, fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ],
                ),
              ),
              _isToggleLoading
                  ? const CircularProgressIndicator(color: Colors.greenAccent)
                  : Switch.adaptive(
                value: isActive,
                onChanged: _toggleStatus,
                activeTrackColor: Colors.greenAccent,
              ),
            ],
          ),
          if (isActive) ...[
            const SizedBox(height: 20),
            const Divider(color: Colors.white24, thickness: 1),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const DriverWorkZonePage())),
                icon: const Icon(Icons.map_outlined, color: Colors.black),
                label: Text(l10n.driver_btn_work_zone, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, Color bgColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.black)),
          ],
        ),
      ),
    );
  }

  void _showServicesDialog(BuildContext context) {
    if (_driverProfile == null) return;
    final l10n = AppLocalizations.of(context)!;
    final List<String> temp = List<String>.from(_driverProfile!.availableServices);
    showDialog(
        context: context,
        builder: (c) => StatefulBuilder(builder: (c, setS) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text(l10n.driver_dialog_services_title, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _allServices.map((s) => CheckboxListTile(
                title: Text(_getTranslatedServiceName(context, s),
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black, fontSize: 14)),
                value: temp.contains(s),
                activeColor: Colors.black,
                onChanged: (v) => setS(() => v! ? temp.add(s) : temp.remove(s))
            )).toList(),
          ),
          actions: [
            FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.black),
                onPressed: () async {
                  await _userService.updateAvailableServices(_driverProfile!.uid, temp);
                  _fetchDriverProfile();
                  if (c.mounted) Navigator.pop(c);
                },
                child: Text(l10n.driver_btn_confirm, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))
            )
          ],
        ))
    );
  }

  @override
  void dispose() {
    _globalOrdersSubscription?.cancel();
    super.dispose();
  }
}
