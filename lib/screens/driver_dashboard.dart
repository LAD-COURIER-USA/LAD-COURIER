import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // ✅ AÑADIDO PARA kIsWeb
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
import 'package:qr_flutter/qr_flutter.dart'; // 🚀 ASEGURAMOS QR LOCAL


const List<String> _allServices = [
  'Paquetería y Mensajería',
  'Logística Especializada',
  'SmartShopper',
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
  
  // 🛡️ REFUERZO V18.7: Instanciación bajo demanda para evitar crash en Web
  FlutterLocalNotificationsPlugin? _localNotifications;

  UserModel? _driverProfile;
  bool _isLoadingProfile = true;
  bool _isToggleLoading = false;

  StreamSubscription? _globalOrdersSubscription;
  Map<String, int> _lastKnownOrdersState = {};

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _localNotifications = FlutterLocalNotificationsPlugin();
      _initializeNotifications();
    }
    _fetchDriverProfile();
  }

  Future<void> _initializeNotifications() async {
    if (_localNotifications == null) return;
    try {
      // ESTANDARIZACIÓN LAD: Usamos el icono por defecto para evitar PlatformException en Release
      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

      await _localNotifications!.initialize(initializationSettings);
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
          // 🛡️ SISTEMA LAD: Verificación de Inactividad (Cierre automático tras 4h)
          if (profile?.lastActiveAt != null) {
            final lastActive = profile!.lastActiveAt!.toDate();
            final now = DateTime.now();
            final difference = now.difference(lastActive).inHours;

            if (difference >= 4) {
              debugPrint("SISTEMA LAD: Detectadas $difference horas de inactividad. Cerrando turno.");
              _processStatusChange(false);
              _showInactivityNotice();
              return;
            }
          }
          _startGlobalOrderListener(profile!.uid);
          // 🛡️ REFUERZO: Marcamos presencia al entrar al Dashboard si está Online
          _userService.updateLastActive(profile.uid);
        }
      }
    }
  }

  void _showInactivityNotice() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("💤 MODO DESCANSO", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.orange)),
        content: const Text("Tu disponibilidad se ha cerrado automáticamente por llevar más de 4 horas sin actividad. Si estás listo para trabajar, vuelve a ponerte online.", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ENTENDIDO", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
          )
        ],
      ),
    );
  }

  void _startGlobalOrderListener(String uid) {
    _globalOrdersSubscription?.cancel();
    _globalOrdersSubscription = _orderService.getNegotiatingOrdersStream(uid).listen((orders) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      if (l10n == null) return;

      // 🛡️ REFUERZO SOBERANO: Si entran órdenes, el Driver está activo
      if (orders.isNotEmpty) {
        _userService.updateLastActive(uid);
      }

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
    if (kIsWeb || _localNotifications == null) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'global_orders_channel', 'Notificaciones Globales de Órdenes',
      importance: Importance.max, priority: Priority.high, playSound: true, enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    try {
      await _localNotifications!.show(DateTime.now().millisecond, title, body, platformChannelSpecifics);
    } catch (e) {
      debugPrint("⚠️ SISTEMA LAD: Error al mostrar notificación: $e");
    }
  }

  Future<void> _logout() async {
    final l10n = AppLocalizations.of(context)!;

    // 🛡️ REFUERZO SOBERANO: Bloqueo de Logout si está ONLINE
    if (_driverProfile?.isMessengerActive ?? false) {
      _showErrorDialog(
        "ACCESO DENEGADO", 
        "No puedes cerrar sesión mientras estés ONLINE. Por favor, ponte fuera de línea primero para proteger la integridad del servicio a tus clientes."
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

  String _getTranslatedServiceName(BuildContext context, String serviceId) {
    final l10n = AppLocalizations.of(context)!;
    switch (serviceId) {
      case 'Paquetería y Mensajería':
        return l10n.driver_service_courier;
      case 'Logística Especializada':
        return l10n.driver_service_logistics;
      case 'SmartShopper':
        return l10n.driver_service_smartshopper;
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

      // 🛡️ SEGURIDAD MANDATORIA V2026.8: Selfie + Huella (Lógica 4h/12h)
      // 💎 BYPASS VIP: Los inspectores no necesitan re-verificarse bajo estas reglas
      if (!(_driverProfile!.isVipTester)) {
        final now = DateTime.now();
        
        if (_driverProfile!.lastBiometricVerification != null) {
          final lastVerification = _driverProfile!.lastBiometricVerification!.toDate();
          final diffHours = now.difference(lastVerification).inHours;
          
          bool needsReauth = false;

          // REGLA 1: Máximo 12 horas desde la última verificación (obligatorio siempre)
          if (diffHours >= 12) {
            debugPrint("SISTEMA LAD: Han pasado $diffHours horas (Límite 12h). Nueva validación requerida.");
            needsReauth = true;
          } 
          // REGLA 2: Si han pasado +4 horas y no ha habido actividad (sin órdenes pendientes)
          else if (diffHours >= 4) {
             if (_driverProfile!.lastActiveAt != null) {
               final lastActive = _driverProfile!.lastActiveAt!.toDate();
               final idleHours = now.difference(lastActive).inHours;
               
               if (idleHours >= 4) {
                 debugPrint("SISTEMA LAD: $idleHours horas de inactividad detectadas. Nueva validación requerida.");
                 needsReauth = true;
               }
             } else {
               // Si no hay rastro de actividad y pasaron 4h, pedimos por seguridad
               needsReauth = true;
             }
          }

          if (needsReauth) {
            _showBiometricPrompt();
            return;
          }

        } else {
          // Si nunca se ha verificado, obligamos la primera vez
          _showBiometricPrompt();
          return;
        }
      }

      _processStatusChange(true);

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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.auth_verification_required_title, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blueAccent)),
        content: Text(l10n.auth_verification_required_body, style: const TextStyle(fontWeight: FontWeight.bold)),
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
            child: Text(l10n.common_continue, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blueAccent)),
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

    // 🛡️ REFUERZO V2026.5: SOBERANÍA DE HARDWARE (Bloqueo Driver en Web)
    if (kIsWeb) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.phonelink_setup_rounded, color: Colors.amber, size: 80),
                  const SizedBox(height: 30),
                  const Text(
                    "REQUISITO DE HARDWARE PROFESIONAL",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Para garantizar un rastreo GPS continuo, la seguridad de tus entregas y el funcionamiento óptimo en segundo plano, el rol de Driver requiere el uso de nuestra App Nativa para Android.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Debido a las limitaciones técnicas del sistema Apple (iOS) y navegadores web que bloquean el GPS al apagar la pantalla, este dispositivo solo está habilitado para el Rol de Cliente.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text("SALIR DEL BÚNKER"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

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
              const SizedBox(height: 20),

              // 🛡️ REFUERZO V2026.4: TIP DE NEGOCIO SOBERANO
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.indigo[900],
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars_rounded, color: Colors.amber, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "POTENCIA TU NEGOCIO",
                            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1),
                          ),
                          Text(
                            "Para una mejor experiencia GPS y recibir más alertas, recomendamos usar un dispositivo Android como herramienta principal.",
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),
              GridView.count(
                crossAxisCount: kIsWeb ? (MediaQuery.of(context).size.width > 900 ? 4 : 2) : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                childAspectRatio: kIsWeb ? 1.3 : 1.1,
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
                  _buildActionCard(l10n.driver_menu_invite, Icons.qr_code_2_rounded, Colors.purple[800]!, Colors.purple[50]!, () => _showInviteDualDialog(context)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInviteDualDialog(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    final unifiedLink = _invitationService.getUnifiedLink(uid);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        backgroundColor: Colors.white,
        title: const Text("VINCULAR NUEVO CLIENTE", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Muestra este código o comparte el link para que tus clientes te envíen pedidos directamente.", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 25),
            
            // 🛡️ CÓDIGO QR UNIFICADO SOBERANO (LOCAL - REFORZADO)
            if (unifiedLink.isNotEmpty && unifiedLink.length > 25)
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.2)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                ),
                child: QrImageView(
                  data: unifiedLink,
                  version: QrVersions.auto,
                  size: 200.0,
                  gapless: false,
                  backgroundColor: Colors.white,
                  errorStateBuilder: (cxt, err) => const SizedBox(
                    width: 200, 
                    height: 200, 
                    child: Center(child: Text("Error al generar QR", style: TextStyle(fontSize: 10)))
                  ),
                ),
              )
            else
              const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator(color: Colors.deepPurple)),
              ),
            
            const SizedBox(height: 20),

            // 🚀 BOTÓN DE COMPARTIR UNIFICADO
            _buildLargeInviteButton(
              context, 
              "COMPARTIR INVITACIÓN", 
              Icons.share, 
              Colors.deepPurple, 
              unifiedLink,
              "WhatsApp, Mensajes, etc."
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("CERRAR", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))
          )
        ],
      ),
    );
  }

  Widget _buildLargeInviteButton(BuildContext context, String title, IconData icon, Color color, String link, String sub) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), 
            side: BorderSide(color: color.withValues(alpha: 0.3), width: 2)
          ),
          elevation: 5,
        ),
        onPressed: () {
          // 🛡️ USAMOS EL MENSAJE AMISTOSO DEL SERVICIO
          _invitationService.shareLink(context);
        },
        child: Row(
          children: [
            Icon(icon, size: 30),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                  Text(sub, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Icon(Icons.send_rounded, size: 20),
          ],
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
    // 🛡️ REFUERZO V19.2: Tamaño de iconos inteligente (Web vs Nativo)
    const double iconSize = kIsWeb ? 65 : 40;
    
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
            Icon(icon, color: color, size: iconSize),
            const SizedBox(height: 12), // Más espacio en Web
            Text(
              title, 
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w900, 
                fontSize: kIsWeb ? 14 : 12, 
                color: Colors.black
              )
            ),
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
