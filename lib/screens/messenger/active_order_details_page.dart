import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_functions/cloud_functions.dart'; // IMPORTAR PARA LLAMAR A STRIPE
import 'package:lad_courier/models/order_model.dart';
import 'package:lad_courier/models/user_model.dart';
import 'package:lad_courier/services/order_service.dart';
import 'package:lad_courier/services/user_service.dart';
import 'package:lad_courier/services/geodata_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lad_courier/l10n/app_localizations.dart';

class ActiveOrderDetailsPage extends StatefulWidget {
  final OrderModel order;
  final List<OrderModel> allOrders;
  final int missionIndex;
  final String missionType;
  final bool isInRange;

  const ActiveOrderDetailsPage({
    super.key,
    required this.order,
    required this.allOrders,
    required this.missionIndex,
    required this.missionType,
    required this.isInRange,
  });

  @override
  State<ActiveOrderDetailsPage> createState() => _ActiveOrderDetailsPageState();
}

class _ActiveOrderDetailsPageState extends State<ActiveOrderDetailsPage> {
  final OrderService _orderService = OrderService();
  final UserService _userService = UserService();
  final GeodataService _geodataService = GeodataService();
  final ImagePicker _picker = ImagePicker();

  UserModel? _clientProfile;
  late bool _isNearPoint;
  double _distanceToPoint = 999.0;
  File? _deliveryPhoto;
  String? _deliveryPhotoName;
  bool _isUploading = false;
  bool _isSavingProductPhoto = false;

  Timer? _proximityTimer;
  int _currentRadarInterval = 10;
  static const double unlockThreshold = 250.0;

  @override
  void initState() {
    super.initState();
    _isNearPoint = widget.isInRange;
    _loadClientData();
    _checkProximity();
    _startRadar(intervalSeconds: 10);
  }

  void _startRadar({required int intervalSeconds}) {
    _proximityTimer?.cancel();
    _currentRadarInterval = intervalSeconds;
    _proximityTimer = Timer.periodic(Duration(seconds: intervalSeconds), (timer) {
      _checkProximity();
    });
  }

  @override
  void dispose() {
    _proximityTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadClientData() async {
    final profile = await _userService.getUser(widget.order.clientId);
    if (mounted) setState(() => _clientProfile = profile);
  }

  // 🔴 NO TOCAR BAJO NINGUN CONCEPTO - LÓGICA DE RADAR Y GPS PROBADA (GEODEFENSA)
  Future<void> _checkProximity() async {
    GeoPoint? targetLatLng;
    if (widget.order.status == OrderStatus.enRouteToPickup || widget.order.status == OrderStatus.active) {
      targetLatLng = widget.order.pickupLatLng;
    } else {
      targetLatLng = widget.order.dropoffLatLng;
    }

    if (targetLatLng != null) {
      try {
        Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        double distance = Geolocator.distanceBetween(
            pos.latitude, pos.longitude, targetLatLng.latitude, targetLatLng.longitude);

        if (mounted) {
          setState(() {
            _distanceToPoint = distance;
            _isNearPoint = distance <= unlockThreshold;
          });
          if (distance < 600 && _currentRadarInterval != 3) {
            _startRadar(intervalSeconds: 3);
          } else if (distance >= 600 && _currentRadarInterval != 10) {
            _startRadar(intervalSeconds: 10);
          }
        }
      } catch (e) {
        debugPrint("Error GPS Radar: $e");
      }
    }
  }

  Future<void> _saveProductPhotoToGallery(String url, String orderId, AppLocalizations l10n) async {
    setState(() => _isSavingProductPhoto = true);
    try {
      final response = await http.get(Uri.parse(url));
      final documentDirectory = await getTemporaryDirectory();
      final file = File('${documentDirectory.path}/LAD_ORDER_${orderId.substring(0, 8)}.jpg');
      file.writeAsBytesSync(response.bodyBytes);
      await Gal.putImage(file.path, album: "LAD_CLIENT_PHOTOS");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("✅ ${l10n.order_details_photo_saved}"),
          backgroundColor: Colors.black,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("⚠️ ${l10n.order_details_photo_error}"),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSavingProductPhoto = false);
    }
  }

  void _showFullImage(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(child: Center(child: Image.network(url))),
            Positioned(top: 40, right: 20, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context))),
          ],
        ),
      ),
    );
  }

  // 🔴 NO TOCAR BAJO NINGUN CONCEPTO - SISTEMA DE CAPTURA Y RENOMBRADO DE EVIDENCIA
  Future<void> _takePhoto(AppLocalizations l10n) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
      if (image != null) {
        // 📍 CAPTURAR GPS PARA VINCULACIÓN FÍSICA
        Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        final String dateStr = "${DateTime.now().day}-${DateTime.now().month}";
        final String lat = pos.latitude.toStringAsFixed(2);
        final String lng = pos.longitude.toStringAsFixed(2);
        final String clientName = widget.order.clientName.replaceAll(' ', '_');
        final String orderIdShort = widget.order.id.substring(0, 5);

        // NOMBRE DE ARCHIVO BLINDADO PARA RECLAMACIONES
        // Ejemplo: LAD_ORD_A7B2_JUAN_15-05_Lat25.76_Lon-80.19.jpg
        final String newName = "LAD_ORD_${orderIdShort}_${clientName}_${dateStr}_Lat${lat}_Lon$lng.jpg";
        
        final directory = await getTemporaryDirectory();
        final String newPath = "${directory.path}/$newName";
        final File renamedFile = await File(image.path).copy(newPath);

        setState(() {
          _deliveryPhoto = renamedFile;
          _deliveryPhotoName = newName;
        });

        await Gal.putImage(renamedFile.path, album: "LAD_COURIER_EVIDENCE");
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("📸 ${l10n.order_details_evidence_msg}"),
            backgroundColor: Colors.green,
          ));
        }
      }
    } catch (e) { debugPrint("Error foto: $e"); }
  }

  // 🔴 NO TOCAR BAJO NINGUN CONCEPTO - LÓGICA DE INICIO DE RUTA Y NAVEGACIÓN EXTERNA
  Future<void> _startNavigation(GeoPoint dest, String id, bool isPickup) async {
    /* 🛡️ SISTEMA LAD: BLOQUE DE RETENCIÓN COMENTADO TEMPORALMENTE PARA PRUEBAS DE FLUJO FINANCIERO
    if (isPickup) {
      setState(() => _isUploading = true);
      try {
        final messenger = await _userService.getUser(FirebaseAuth.instance.currentUser!.uid);
        final client = await _userService.getUser(widget.order.clientId);

        final String? stripeAcc = messenger?.stripeAccountId;
        final String? paymentMethod = client?.defaultPaymentMethodId; 
        final String? customerId = client?.stripeCustomerId;

        if (stripeAcc == null) throw "Debes vincular tu cuenta Stripe para recibir pagos.";
        if (paymentMethod == null || customerId == null) throw "El cliente no tiene un método de pago válido configurado.";

        debugPrint("🚀 SISTEMA LAD: Intentando autorizar cobro de \$${widget.order.price}...");

        final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('authorizeOrderPayment');
        final result = await callable.call({
          'amount': ((widget.order.price ?? 0.0) * 100).toInt(),
          'driverStripeAccountId': stripeAcc,
          'orderId': id,
          'paymentMethodId': paymentMethod,
          'customerId': customerId,
        });

        if (result.data['success'] != true) {
          throw result.data['error'] ?? 'El cliente no tiene fondos suficientes.';
        }

        debugPrint("✅ SISTEMA LAD: Pago autorizado y fondos retenidos en Stripe.");
      } catch (e) {
        if (mounted) {
          _showErrorDialog("Blindaje Financiero LAD", "No pudimos retener los fondos. Detalle: $e");
          await _orderService.updateOrderStatus(id, OrderStatus.cancelled, message: "⚠️ ORDEN DETENIDA: Error de fondos.");
          await _notifyPaymentFailure(id, e.toString());
        }
        if (mounted) setState(() => _isUploading = false);
        return;
      }
    }
    */

    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${dest.latitude},${dest.longitude}&travelmode=driving');
    await _orderService.updateOrderStatus(
        id, isPickup ? OrderStatus.enRouteToPickup : OrderStatus.enRouteToDelivery,
        message: isPickup ? "🚀 Iniciando ruta de recogida." : "🚚 Iniciando ruta de entrega.");
    
    setState(() => _isUploading = false);

    if (await canLaunchUrl(uri)) {
      // 🛡️ SISTEMA LAD: Usamos LaunchMode.externalApplication para que Android 
      // mantenga nuestra app viva en segundo plano de forma más robusta.
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /* 🛡️ SISTEMA LAD: Comentado temporalmente junto con el bloque de retención
  void _showErrorDialog(String title, String msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.red)),
        content: Text(msg),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("ENTENDIDO"))],
      ),
    );
  }
  */

  // 🟡 ÁREA DE TRABAJO CRÍTICA - FINALIZACIÓN Y COBRO (REVISAR CON CUIDADO)
  Future<void> _completeOrder(OrderModel order) async {
    if (_deliveryPhoto == null) return;
    setState(() => _isUploading = true);
    try {
      // 1. EJECUTAR EL COBRO REAL E INMEDIATO (MODELO SAAS DIRECTO)
      final messenger = await _userService.getUser(FirebaseAuth.instance.currentUser!.uid);


      // 🛡️ SISTEMA LAD: Forzamos la región us-central1 para evitar el error NOT_FOUND
      final HttpsCallable callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('processImmediatePayment');

      try {
        final result = await callable.call({
          'amount': ((order.price ?? 0.0) * 100).toInt(),
          'driverStripeAccountId': messenger?.stripeAccountId,
          'orderId': order.id,
          // 🛡️ SISTEMA LAD: Ya no enviamos paymentMethodId ni customerId.
          // El servidor los buscará directamente en Firestore para evitar IDs viejos.
        });

        if (result.data['success'] != true) {
          throw result.data['error'] ?? "Error desconocido en Stripe";
        }
      } catch (stripeError) {
        debugPrint("SISTEMA LAD: Error cobrando: $stripeError");
        bool bypass = await _showBypassDialog(stripeError.toString());
        if (!bypass) {
          setState(() => _isUploading = false);
          return;
        }
      }

      // 2. SUBIR EVIDENCIA Y COMPLETAR ORDEN
      final String fileName = _deliveryPhotoName ?? "delivery_${order.id}_${DateTime.now().millisecondsSinceEpoch}.jpg";
      final ref = FirebaseStorage.instance.ref().child('delivery_evidence').child(fileName);

      await ref.putFile(_deliveryPhoto!);
      final String downloadUrl = await ref.getDownloadURL();

      // 🛡️ CAPA AUDITORÍA PERFECTA LAD: Capturamos GPS y Selfie de Auditoría
      Position? completionPos;
      try {
        completionPos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high).timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint("LAD AUDIT: Error capturando GPS final: $e");
      }

      await FirebaseFirestore.instance.collection('orders').doc(order.id).set({
        'status': OrderStatus.completed,
        'statusMessage': '✅ ¡Pedido entregado con éxito!',
        'completionTimestamp': Timestamp.now(),
        'deliveryProofUrl': downloadUrl,
        'driverAuditSelfieUrl': messenger?.lastSessionSelfieUrl, // 🤳 Selfie del día (Sin Amazon IA)
        'completionLatLng': completionPos != null 
            ? GeoPoint(completionPos.latitude, completionPos.longitude) 
            : null,
      }, SetOptions(merge: true));

      await _notifyClientCompletion(order.id);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<bool> _showBypassDialog(String error) async {
    return await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("⚠️ ERROR DE COBRO", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Stripe dice: $error"),
            const SizedBox(height: 15),
            const Text("¿Quieres FORZAR la finalización de la orden de todos modos? (Solo para pruebas)", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCELAR")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text("FORZAR FINALIZACIÓN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _notifyClientCompletion(String orderId) async {
    if (_clientProfile?.phoneNumber == null) return;
    final String message = "LAD COURIER: Pedido #${orderId.substring(0, 5)} entregado con éxito.";
    final Uri smsUri = Uri.parse("sms:${_clientProfile!.phoneNumber}?body=${Uri.encodeComponent(message)}");
    if (await canLaunchUrl(smsUri)) await launchUrl(smsUri);
  }

  /* 🛡️ SISTEMA LAD: Comentado temporalmente junto con el bloque de retención
  Future<void> _notifyPaymentFailure(String orderId, String error) async {
    if (_clientProfile?.phoneNumber == null) return;
    final String message = "LAD COURIER: Tu orden #${orderId.substring(0, 5)} ha sido cancelada. Tu banco rechazó la retención de fondos. Por favor actualiza tu tarjeta en el perfil.";
    final Uri smsUri = Uri.parse("sms:${_clientProfile!.phoneNumber}?body=${Uri.encodeComponent(message)}");
    if (await canLaunchUrl(smsUri)) await launchUrl(smsUri);
  }
  */

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<OrderModel?>(
      stream: _orderService.getOrderStream(widget.order.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final order = snapshot.data!;

        final bool showProductPhoto = order.productPhotoUrl != null && order.status != OrderStatus.completed;

        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: Text(l10n.order_details_title(widget.missionType, widget.missionIndex),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            backgroundColor: Colors.white,
            foregroundColor: widget.missionType == "RECOGER" ? Colors.green[800] : Colors.red[800],
            elevation: 1, centerTitle: true,
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildClientCard(order, l10n),
                          if (showProductPhoto) ...[
                            const SizedBox(height: 16),
                            _buildProductPhotoCard(order, l10n),
                          ],
                          const SizedBox(height: 16),
                          _buildInstructionsCard(order, l10n),
                          const SizedBox(height: 16),
                          _buildProximityCard(l10n),
                        ],
                      ),
                    ),
                  ),
                  _buildActionPanel(order, l10n),
                ],
              ),
              if (_isUploading) Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator())),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductPhotoCard(OrderModel order, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.deepPurple, width: 2),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                const Icon(Icons.inventory_2, color: Colors.deepPurple, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(l10n.order_details_product_photo.toUpperCase(),
                    maxLines: 1,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.black, overflow: TextOverflow.ellipsis))),
                _isSavingProductPhoto
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : IconButton(
                  onPressed: () => _saveProductPhotoToGallery(order.productPhotoUrl!, order.id, l10n),
                  icon: const Icon(Icons.download_for_offline, color: Colors.deepPurple, size: 32),
                  padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                )
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showFullImage(order.productPhotoUrl!),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(13)),
                  child: Image.network(order.productPhotoUrl!, height: 200, width: double.infinity, fit: BoxFit.cover),
                ),
                Positioned(
                  right: 15,
                  bottom: 15,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), shape: BoxShape.circle),
                    child: const Icon(Icons.zoom_in, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(OrderModel order, AppLocalizations l10n) {
    return Card(
      color: Colors.white,
      elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            CircleAvatar(radius: 30, backgroundImage: _clientProfile?.photoURL != null ? NetworkImage(_clientProfile!.photoURL!) : null,
                child: _clientProfile?.photoURL == null ? const Icon(Icons.person, size: 35) : null),
            const SizedBox(width: 15),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_clientProfile?.displayName ?? order.clientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black)),
              Text(l10n.order_details_id(order.id.substring(0, 8)), style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
            ])),
          ]),
          const Divider(height: 30, color: Colors.black12),
          _locationRow(Icons.location_on, order.pickupAddress, Colors.green[800]!),
          const SizedBox(height: 15),
          _locationRow(Icons.flag, order.dropoffAddress, Colors.red[800]!),
        ]),
      ),
    );
  }

  Widget _locationRow(IconData icon, String address, Color color) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 10),
      Expanded(child: Text(address, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black))),
    ]);
  }

  Widget _buildInstructionsCard(OrderModel order, AppLocalizations l10n) {
    final String details = order.packageDetails ?? "";
    final bool hasReceiptUrl = details.contains("URL RECIBO:");
    String receiptUrl = "";

    if (hasReceiptUrl) {
      try {
        receiptUrl = details.split("URL RECIBO:")[1].split("\n")[0].trim();
      } catch (e) { debugPrint("Error parseando URL: $e"); }
    }

    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.orange, width: 2)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
              const SizedBox(width: 8),
              Text(l10n.order_details_instructions.toUpperCase(),
                  style: TextStyle(fontWeight: FontWeight.w900, color: Colors.orange[900], fontSize: 10)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
              details.isEmpty ? l10n.order_details_no_instructions : details,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)
          ),

          if (hasReceiptUrl && receiptUrl.isNotEmpty) ...[
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(receiptUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.open_in_browser, color: Colors.white),
                label: const Text("ABRIR RECIBO ORIGINAL",
                    style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[800],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProximityCard(AppLocalizations l10n) {
    return Card(
      color: _isNearPoint ? Colors.green[50] : Colors.blue[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(_isNearPoint ? Icons.check_circle : Icons.gps_fixed, color: _isNearPoint ? Colors.green : Colors.blue),
        title: Text(
            _isNearPoint ? l10n.order_details_proximity_on : l10n.order_details_proximity_off,
            style: TextStyle(fontWeight: FontWeight.w900, color: _isNearPoint ? Colors.green[900] : Colors.blue[900])
        ),
        subtitle: Text(
            l10n.order_details_meters(_distanceToPoint.toStringAsFixed(0)),
            style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black)
        ),
      ),
    );
  }

  Widget _buildActionPanel(OrderModel order, AppLocalizations l10n) {
    bool isPickupPhase = (order.status == OrderStatus.active || order.status == OrderStatus.enRouteToPickup);
    bool isDeliveryPhase = (order.status == OrderStatus.pickedUp || order.status == OrderStatus.enRouteToDelivery);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25)), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPickupPhase && !_isNearPoint)
              _btn(l10n.order_details_btn_go_pickup, Icons.navigation, Colors.blue, () => _startNavigation(order.pickupLatLng!, order.id, true)),
            if (isPickupPhase && _isNearPoint)
              _btn(l10n.order_details_btn_arrived, Icons.check_box, Colors.green, () async {

                // 🚀 ENGRANAJE DE AUTO-APRENDIZAJE SOBERANO REPARADO (V3 - ROBUSTO)
                try {
                  final String? driverId = FirebaseAuth.instance.currentUser?.uid;
                  if (driverId != null) {
                    final String fullAddr = order.pickupAddress.toUpperCase();
                    
                    // 🧠 Extracción Robusta: Buscamos el ZIP (5 dígitos)
                    final RegExp zipRegex = RegExp(r'\b(\d{5}(?:-\d{4})?)\b');
                    final String? zip = zipRegex.firstMatch(fullAddr)?.group(0);

                    // 🧠 Extracción Robusta: Buscamos el Número de Calle (1-6 dígitos que no sea el ZIP)
                    String? streetNum;
                    final allNumMatches = RegExp(r'\b\d{1,6}\b').allMatches(fullAddr);
                    for (var m in allNumMatches) {
                      if (m.group(0) != zip) {
                        streetNum = m.group(0);
                        break;
                      }
                    }

                    if (zip != null && streetNum != null) {
                      // Intentamos obtener el GPS para máxima precisión de LAD
                      Position? pos;
                      try {
                        pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high).timeout(const Duration(seconds: 3));
                      } catch (_) {
                        // Si falla el GPS, usamos el del pedido original (menos preciso pero sirve)
                        debugPrint("LAD: GPS falló en aprendizaje, usando fallback.");
                      }

                      String store = "Comercio Local";
                      if (order.packageDetails != null && order.packageDetails!.contains("RECOGER EN ")) {
                        final parts = order.packageDetails!.split("RECOGER EN ");
                        if (parts.length > 1) {
                          store = parts[1].split(".")[0].trim();
                        }
                      }

                      await _geodataService.registerNewValidatedStore(
                        zip: zip,
                        streetNumber: streetNum,
                        storeName: store,
                        fullAddress: order.pickupAddress,
                        lat: pos?.latitude ?? order.pickupLatLng!.latitude,
                        lng: pos?.longitude ?? order.pickupLatLng!.longitude,
                        driverId: driverId,
                      );
                      debugPrint("LAD: Inteligencia Soberana alimentada con éxito.");
                    }
                  }
                } catch (e) {
                  debugPrint("LAD: Error en Auto-Aprendizaje (V3): $e");
                }
                // -------------------------------------------

                await _orderService.updateOrderStatus(order.id, OrderStatus.pickedUp, message: "📦 Paquete recogido.");
                if (mounted) Navigator.pop(context);
              }),
            if (isDeliveryPhase && !_isNearPoint)
              _btn(l10n.order_details_btn_go_delivery, Icons.directions_car, Colors.deepPurple, () => _startNavigation(order.dropoffLatLng!, order.id, false)),
            if (isDeliveryPhase) ...[
              if (_deliveryPhoto == null)
                // 🛡️ SOBERANÍA GPS: Botón deshabilitado si no está en el punto
                _btn(
                  _isNearPoint ? l10n.order_details_btn_photo : "LLEGUE AL DESTINO PARA ACTIVAR CÁMARA", 
                  Icons.camera_alt, 
                  _isNearPoint ? Colors.orange : Colors.grey[400]!, 
                  _isNearPoint ? () => _takePhoto(l10n) : null
                )
              else
                // SI YA HAY FOTO (tomada bajo geodefensa), PERMITIMOS FINALIZAR
                _btn(l10n.order_details_btn_finish, Icons.verified, Colors.green, () => _completeOrder(order)),
            ],

          ],
        ),
      ),
    );
  }

  Widget _btn(String t, IconData i, Color c, VoidCallback? a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(width: double.infinity, height: 55, child: ElevatedButton.icon(onPressed: a, icon: Icon(i, color: Colors.white), label: Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)), style: ElevatedButton.styleFrom(backgroundColor: c, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))))),
    );
  }
}
