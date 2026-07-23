import 'dart:math'; // ✅ AÑADIDO PARA SECRETOS
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart'; // ✅ AÑADIDO PARA AUDITORÍA CLOUD
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:otp/otp.dart'; // ✅ CORREGIDO: Usando la librería 'otp'
import 'package:fl_chart/fl_chart.dart'; // ✅ AÑADIDO PARA GRÁFICOS
import 'package:google_maps_flutter/google_maps_flutter.dart'; // ✅ AÑADIDO PARA MAPA GLOBAL
import 'package:image_picker/image_picker.dart'; // ✅ AÑADIDO PARA SELFIE
import 'package:lad_courier/services/storage_service.dart'; // ✅ AÑADIDO PARA SUBIDA
import 'package:lad_courier/auth/auth_gate.dart';
import 'package:lad_courier/services/admin_service.dart';
import 'package:lad_courier/models/user_model.dart';
import 'package:lad_courier/models/order_model.dart'; // ✅ AÑADIDO PARA ÓRDENES

class ControlTowerPage extends StatefulWidget {
  const ControlTowerPage({super.key});

  @override
  State<ControlTowerPage> createState() => _ControlTowerPageState();
}

class _ControlTowerPageState extends State<ControlTowerPage> {
  final AdminService _adminService = AdminService();
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');
  
  bool _isUnlocked = false;
  bool _isSelfieVerified = false; // 🛡️ NUEVO: Paso 1 de Seguridad
  bool _isLoading = true;
  bool _isProcessingSelfie = false;
  String? _totpSecret;
  final TextEditingController _codeController = TextEditingController();

  String _activeView = 'DASHBOARD'; 
  bool _isRadarActive = false; 
  final Set<Marker> _mapMarkers = {};

  @override
  void initState() {
    super.initState();
    _checkSecuritySession();
  }

  // 🛡️ VÁLVULA DE SEGURIDAD: Verifica si la sesión de 8 horas sigue vigente
  Future<void> _checkSecuritySession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = userDoc.data();
    _totpSecret = data?['totpSecret'];

    final prefs = await SharedPreferences.getInstance();
    final lastAuth = prefs.getInt('admin_auth_timestamp') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // 8 Horas
    const eightHours = 8 * 60 * 60 * 1000;

    if (now - lastAuth < eightHours) {
      setState(() {
        _isUnlocked = true;
        _isSelfieVerified = true;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _takeAdminSelfie() async {
    setState(() => _isProcessingSelfie = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 600,
      );

      if (image == null) {
        setState(() => _isProcessingSelfie = false);
        return;
      }

      // 1. SUBIR SELFIE TEMPORAL
      final storage = StorageService();
      final String uid = FirebaseAuth.instance.currentUser!.uid;
      final String? url = await storage.uploadFile(
        'admin_verifications', 
        "admin_session_$uid", 
        image
      );

      if (url == null) throw "Error al subir evidencia.";

      // 2. AUDITORÍA FORENSE (GOOGLE VISION)
      final result = await _functions.httpsCallable('verifyLivenessCloud').call({
        'imageUrl': url,
      });

      if (result.data['success'] == true) {
        setState(() {
          _isSelfieVerified = true;
          _isProcessingSelfie = false;
        });
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text("✅ IDENTIDAD BIOMÉTRICA CONFIRMADA"), backgroundColor: Colors.green)
        );
      } else {
        throw result.data['error'] ?? "Fallo en la auditoría facial.";
      }
    } catch (e) {
      setState(() => _isProcessingSelfie = false);
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text("❌ ERROR DE SEGURIDAD: $e"), backgroundColor: Colors.red)
      );
    }
  }

  void _setupAdminAuthenticator() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // GENERACIÓN DE SECRET KEY
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final Random random = Random();
    String secret = Iterable.generate(16, (i) => chars[random.nextInt(chars.length)]).join();

    final String otpUri = "otpauth://totp/LAD_ADMIN:${user.email}?secret=$secret&issuer=LADCOURIER";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("CONFIGURACIÓN MAESTRA (2FA)", style: TextStyle(fontWeight: FontWeight.w900)),
        content: SizedBox(
          width: 300, // 🛡️ FIJAMOS EL ANCHO PARA EVITAR ERROR DE INTRINSICS EN WEB
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Escanea este código con Google Authenticator para activar tu acceso de Admin."),
              const SizedBox(height: 20),
              QrImageView(data: otpUri, size: 180),
              const SizedBox(height: 10),
              SelectableText(secret, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'totpSecret': secret});
              if (!mounted) return;
              setState(() => _totpSecret = secret);
              navigator.pop();
            },
            child: const Text("YA LO VINCULÉ"),
          )
        ],
      ),
    );
  }

  Future<void> _verifyCode() async {
    if (_totpSecret == null) return;

    // 🛡️ PROTOCOLO LAD: Validación contra Google Authenticator (Librería OTP)
    final String expectedCode = OTP.generateTOTPCodeString(
        _totpSecret!,
        DateTime.now().millisecondsSinceEpoch,
        algorithm: Algorithm.SHA1,
        isGoogle: true
    );

    if (_codeController.text == expectedCode) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('admin_auth_timestamp', DateTime.now().millisecondsSinceEpoch);

      setState(() => _isUnlocked = true);
    } else {
      _codeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ CÓDIGO DE SEGURIDAD INCORRECTO"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Colors.greenAccent)));

    if (!_isUnlocked) return _buildLockScreen();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A), // Black Bunker
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: _activeView != 'DASHBOARD' 
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.greenAccent),
              onPressed: () => setState(() => _activeView = 'DASHBOARD'),
            )
          : null,
        title: Text(
          _activeView == 'DASHBOARD' ? "LAD CONTROL TOWER" : _activeView,
          style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.security, color: Colors.blueAccent),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('admin_auth_timestamp');
              setState(() => _isUnlocked = false);
            },
            tooltip: "Bloquear Manualmente",
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await FirebaseAuth.instance.signOut();
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const AuthGate()),
                    (route) => false,
              );
            },
          )
        ],
      ),
      body: _buildCurrentView(),
    );
  }

  Widget _buildCurrentView() {
    switch (_activeView) {
      case 'VERIFICACIONES': return _buildVerificationsView();
      case 'FINANZAS': return _buildMarketingView();
      case 'RECLAMACIONES': return _buildTicketsView();
      case 'MAPA': return _buildGlobalMapView();
      case 'EVIDENCIAS': return _buildEvidenceArchiveView();
      default: return _buildDashboardView();
    }
  }

  Widget _buildDashboardView() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickStats(),
          const SizedBox(height: 30),
          const Text(
            "MONITOREO GLOBAL",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              children: [
                _buildMenuCard("RADAR", Icons.radar, Colors.blueAccent, "EN VIVO", () => setState(() => _activeView = 'MAPA')),
                _buildMenuCard("AUDITORÍA", Icons.verified_user, Colors.orangeAccent, "PENDIENTES", () => setState(() => _activeView = 'VERIFICACIONES')),
                _buildMenuCard("TICKETS", Icons.feedback, Colors.redAccent, "BUZÓN", () => setState(() => _activeView = 'RECLAMACIONES')),
                _buildMenuCard("ARCHIVO", Icons.photo_library, Colors.greenAccent, "EVIDENCIAS", () => setState(() => _activeView = 'EVIDENCIAS')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationsView() {
    return StreamBuilder<List<UserModel>>(
      stream: _adminService.getPendingVerifications(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.greenAccent));
        final drivers = snapshot.data!;
        if (drivers.isEmpty) return const Center(child: Text("NO HAY VERIFICACIONES PENDIENTES", style: TextStyle(color: Colors.white54)));

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: drivers.length,
          itemBuilder: (context, i) {
            final d = drivers[i];
            return Card(
              color: Colors.grey[900],
              margin: const EdgeInsets.only(bottom: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.white12,
                  backgroundImage: d.photoURL != null ? NetworkImage(d.photoURL!) : null,
                ),
                title: Text(d.displayName ?? 'SIN NOMBRE', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text("ID: ${d.uid.substring(0, 8)}...", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
                  onPressed: () => _showApprovalDialog(d),
                  child: const Text("REVISAR"),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showApprovalDialog(UserModel driver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text("AUDITORÍA: ${driver.displayName}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text("PERFIL", style: TextStyle(color: Colors.white54, fontSize: 10)),
                      const SizedBox(height: 5),
                      if (driver.photoURL != null) Image.network(driver.photoURL!, height: 180, width: 140, fit: BoxFit.cover),
                    ],
                  ),
                  const Icon(Icons.compare_arrows, color: Colors.greenAccent),
                  Column(
                    children: [
                      const Text("SELFIE HOY", style: TextStyle(color: Colors.white54, fontSize: 10)),
                      const SizedBox(height: 5),
                      if (driver.lastSessionSelfieUrl != null) 
                        Image.network(driver.lastSessionSelfieUrl!, height: 180, width: 140, fit: BoxFit.cover)
                      else
                        Container(height: 180, width: 140, color: Colors.black, child: const Icon(Icons.no_photography, color: Colors.white24)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text("¿Las fotos coinciden con el driver?", style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 30),
              const Divider(color: Colors.white24),
              const Text("ACCIONES DE FRANQUICIA", style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _FranchiseActionBtn(
                    label: "SUSPENDER", 
                    icon: Icons.timer_off, 
                    color: Colors.orange, 
                    onTap: () => _handleSuspension(driver.uid)
                  ),
                  _FranchiseActionBtn(
                    label: "REVOCAR", 
                    icon: Icons.gavel, 
                    color: Colors.red, 
                    onTap: () => _handleRevocation(driver)
                  ),
                  _FranchiseActionBtn(
                    label: "RESTAURAR", 
                    icon: Icons.restore, 
                    color: Colors.blue, 
                    onTap: () => _handleRestoration(driver.uid)
                  ),
                  _FranchiseActionBtn(
                    label: "SEGURIDAD", 
                    icon: Icons.lock_reset, 
                    color: Colors.white, 
                    onTap: () => _handleSecurityReset(driver)
                  ),
                ],
              )
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("RECHAZAR", style: TextStyle(color: Colors.redAccent))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
            onPressed: () async {
              await _adminService.approveDriver(driver.uid);
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text("APROBAR AHORA", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketingView() {
    return FutureBuilder<Map<String, double>>(
      future: _adminService.getServicePopularity(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.greenAccent));
        final stats = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text("POPULARIDAD DE SERVICIOS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 40),
              SizedBox(
                height: 250,
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(color: Colors.orange, value: stats['Courier'], title: 'Courier', radius: 60, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      PieChartSectionData(color: Colors.blue, value: stats['Logistics'], title: 'Logistics', radius: 60, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      PieChartSectionData(color: Colors.green, value: stats['SmartShopper'], title: 'Shopper', radius: 60, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const _StatItem(label: "TOTAL ÓRDENES ANALIZADAS", value: "1000+", color: Colors.blueAccent),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTicketsView() {
    return StreamBuilder<QuerySnapshot>(
      stream: _adminService.getDisputesAndSuggestions(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.greenAccent));
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("BÚNKER DE MENSAJES VACÍO", style: TextStyle(color: Colors.white54)));

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final status = data['status'] ?? 'PENDING';
            
            return Card(
              color: Colors.grey[900],
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(data['subject'] ?? 'SIN TÍTULO', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(data['message'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54)),
                trailing: Icon(Icons.circle, color: status == 'RESOLVED' ? Colors.green : Colors.orange, size: 12),
                onTap: () => _showTicketResolutionDialog(docs[i].id, data),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGlobalMapView() {
    if (!_isRadarActive) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map_outlined, color: Colors.blueAccent, size: 100),
            const SizedBox(height: 20),
            const Text("EL RADAR ESTÁ APAGADO", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const Text("Actívalo para ver la flota en tiempo real (USA).", style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => setState(() => _isRadarActive = true),
              icon: const Icon(Icons.power_settings_new),
              label: const Text("ACTIVAR RADAR GLOBAL"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20)),
            )
          ],
        ),
      );
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(target: LatLng(37.0902, -95.7129), zoom: 4), // Centro USA
          markers: _mapMarkers,
          myLocationButtonEnabled: false,
          onMapCreated: (controller) {},
        ),
        // 🛡️ CAPA DE DATOS EN VIVO (HILOS DE FIRESTORE)
        StreamBuilder<List<UserModel>>(
          stream: _adminService.getOnlineDrivers(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              for (var driver in snapshot.data!) {
                if (driver.lastKnownLocation != null) {
                  _mapMarkers.add(Marker(
                    markerId: MarkerId(driver.uid),
                    position: LatLng(driver.lastKnownLocation!.latitude, driver.lastKnownLocation!.longitude),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                    infoWindow: InfoWindow(title: "DRIVER: ${driver.displayName}"),
                  ));
                }
              }
            }
            return const SizedBox.shrink();
          },
        ),
        Positioned(
          bottom: 20, left: 20,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(10)),
            child: const Row(
              children: [
                Icon(Icons.circle, color: Colors.green, size: 12),
                SizedBox(width: 5),
                Text("DRIVERS ONLINE", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildEvidenceArchiveView() {
    return StreamBuilder<List<OrderModel>>(
      stream: _adminService.getCompletedOrdersHistory(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.greenAccent));
        final orders = snapshot.data!;
        if (orders.isEmpty) return const Center(child: Text("NO HAY ENTREGAS RECIENTES", style: TextStyle(color: Colors.white54)));

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: orders.length,
          itemBuilder: (context, i) {
            final o = orders[i];
            return Card(
              color: Colors.grey[900],
              margin: const EdgeInsets.only(bottom: 15),
              child: ListTile(
                leading: const Icon(Icons.inventory, color: Colors.greenAccent),
                title: Text("ORDEN: ${o.id.substring(0, 8)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text("ENTREGADO A: ${o.clientName}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white24),
                onTap: () => _showOrderEvidenceDialog(o),
              ),
            );
          },
        );
      },
    );
  }

  void _showOrderEvidenceDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text("EVIDENCIA DE ENTREGA: ${order.id.substring(0, 8)}", style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("FOTO DE ENTREGA (POD)", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (order.deliveryProofUrl != null)
                Image.network(order.deliveryProofUrl!, height: 250, fit: BoxFit.contain)
              else
                Container(height: 100, color: Colors.black, child: const Center(child: Text("SIN FOTO", style: TextStyle(color: Colors.white24)))),
              
              const SizedBox(height: 20),
              const Divider(color: Colors.white10),
              const SizedBox(height: 10),
              _StatItem(label: "DRIVER", value: order.messengerName ?? "N/A", color: Colors.blueAccent),
              const SizedBox(height: 10),
              _StatItem(label: "CLIENTE", value: order.clientName, color: Colors.orangeAccent),
              const SizedBox(height: 20),
              
              const Text("¿Existe una reclamación?", style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () async {
                  await _adminService.flagOrderForInvestigation(order.id, true);
                  if (context.mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.warning, color: Colors.black),
                label: const Text("INVESTIGAR", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CERRAR", style: TextStyle(color: Colors.white)))
        ],
      ),
    );
  }

  void _showTicketResolutionDialog(String id, Map<String, dynamic> data) {
    final TextEditingController resController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("RESOLVER DISCREPANCIA", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(data['message'] ?? '', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            TextField(
              controller: resController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Escribe la resolución...",
                hintStyle: TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.black26,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () async {
              await _adminService.resolveTicket(id, resController.text);
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text("RESOLVER"),
          ),
        ],
      ),
    );
  }

  Widget _buildLockScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                !_isSelfieVerified ? Icons.face_retouching_natural : Icons.lock_person, 
                color: Colors.greenAccent, 
                size: 80
              ),
              const SizedBox(height: 20),
              Text(
                !_isSelfieVerified ? "IDENTIFICACIÓN REQUERIDA" : "ACCESO RESTRINGIDO",
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Text(
                !_isSelfieVerified 
                    ? "Para entrar a la Torre de Control, debes validar tu identidad con una selfie de hoy."
                    : (_totpSecret == null
                        ? "Para continuar, debes configurar tu llave maestra de seguridad."
                        : "Ingresa el código de 6 dígitos de tu Google Authenticator"),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 40),
              
              if (!_isSelfieVerified)
                _isProcessingSelfie 
                  ? const CircularProgressIndicator(color: Colors.greenAccent)
                  : ElevatedButton.icon(
                      onPressed: _takeAdminSelfie,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("TOMAR SELFIE DE SEGURIDAD"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    )
              else if (_totpSecret == null)
                ElevatedButton(
                  onPressed: _setupAdminAuthenticator,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  child: const Text("CONFIGURAR AUTHENTICATOR", style: TextStyle(fontWeight: FontWeight.bold)),
                )
              else ...[
                Container(
                  width: 250,
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5)),
                  ),
                  child: TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 10),
                    decoration: const InputDecoration(
                      counterText: "",
                      border: InputBorder.none,
                      hintText: "000000",
                      hintStyle: TextStyle(color: Colors.white12, letterSpacing: 10),
                    ),
                    onChanged: (v) {
                      if (v.length == 6) _verifyCode();
                    },
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _verifyCode,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                  child: const Text("VERIFICAR CÓDIGO"),
                ),
              ],
              const SizedBox(height: 40),
              TextButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await FirebaseAuth.instance.signOut();
                  if (!mounted) return;
                  navigator.pushReplacement(
                    MaterialPageRoute(builder: (context) => const AuthGate()),
                  );
                },
                child: const Text("CERRAR SESIÓN", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshotUsers) {
        return StreamBuilder<List<OrderModel>>(
          stream: _adminService.getActiveMissions(),
          builder: (context, snapshotOrders) {
            int totalDrivers = 0;
            int pendingVerif = 0;
            int redAlerts = 0;

            if (snapshotUsers.hasData) {
              final docs = snapshotUsers.data!.docs;
              totalDrivers = docs.where((d) => (d.data() as Map)['role'] == 'DRIVER' || (d.data() as Map)['role'] == 'MESSENGER').length;
              pendingVerif = docs.where((d) => (d.data() as Map)['verificationStatus'] == 'APROBADO_DOC').length;
            }

            if (snapshotOrders.hasData) {
              final now = DateTime.now();
              redAlerts = snapshotOrders.data!.where((o) {
                if (o.status == OrderStatus.pickedUp) {
                  final startTime = o.pickedUpAt?.toDate() ?? o.createdAt.toDate();
                  return now.difference(startTime).inHours >= 2;
                }
                return false;
              }).length;
            }

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(label: "DRIVERS", value: totalDrivers.toString(), color: Colors.greenAccent),
                  _StatItem(label: "PENDIENTES", value: pendingVerif.toString(), color: Colors.orangeAccent),
                  _StatItem(label: "ALERTAS", value: redAlerts.toString(), color: redAlerts > 0 ? Colors.redAccent : Colors.blueAccent),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMenuCard(String title, IconData icon, Color color, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
            const SizedBox(height: 5),
            Text(subtitle, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
  void _handleSuspension(String uid) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("SUSPENDER DRIVER", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: reasonController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: "Motivo de la suspensión", hintStyle: TextStyle(color: Colors.white24)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await _adminService.suspendDriver(uid: uid, reason: reasonController.text);
              if (!mounted) return;
              navigator.pop(); // Cierra este diálogo
              navigator.pop(); // Cierra el diálogo de auditoría
            },
            child: const Text("CONFIRMAR"),
          )
        ],
      ),
    );
  }

  void _handleSecurityReset(UserModel driver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("RESET DE SEGURIDAD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text("Se enviará un correo de recuperación a ${driver.email}. El driver deberá cambiar su contraseña para volver a entrar. ¿Proceder?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          ElevatedButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              await _adminService.resetUserSecurity(driver.email);
              if (!mounted) return;
              navigator.pop();
              scaffoldMessenger.showSnackBar(const SnackBar(content: Text("✅ Correo de seguridad enviado.")));
            },
            child: const Text("ENVIAR RESET"),
          )
        ],
      ),
    );
  }

  void _handleRevocation(UserModel driver) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("REVOCACIÓN PERMANENTE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Esta acción es irreversible y meterá la identidad financiera en la lista negra.", style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 15),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: "Motivo legal de la revocación", hintStyle: TextStyle(color: Colors.white24)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await _adminService.revokeDriverFranchise(driver, reasonController.text);
              if (!mounted) return;
              navigator.pop(); // Cierra este diálogo
              navigator.pop(); // Cierra el de auditoría
            },
            child: const Text("REVOCAR PARA SIEMPRE"),
          )
        ],
      ),
    );
  }

  void _handleRestoration(String uid) async {
    final navigator = Navigator.of(context);
    await _adminService.restoreDriverFranchise(uid);
    if (!mounted) return;
    navigator.pop();
  }
}

class _FranchiseActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FranchiseActionBtn({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900)),
      ],
    );
  }
}
