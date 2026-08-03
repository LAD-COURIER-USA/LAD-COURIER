import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // 🛡️ PARA kIsWeb
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:gal/gal.dart'; // ❌ EXTERMINADO PARA WEB
import 'package:http/http.dart' as http;
import 'package:cloud_functions/cloud_functions.dart'; 
import 'package:lad_courier/models/order_model.dart';
import 'package:lad_courier/models/user_model.dart';
import 'package:lad_courier/services/order_service.dart';
import 'package:lad_courier/services/user_service.dart';
import 'package:lad_courier/services/geodata_service.dart';
import 'package:lad_courier/services/stripe_mode_service.dart'; 
import 'package:url_launcher/url_launcher.dart';
import 'package:lad_courier/l10n/app_localizations.dart';
import 'package:lad_courier/screens/chat_screen.dart';

// 🛡️ REFUERZO V18.8: Eliminamos dart:io y usamos abstracciones para Web
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
  
  // 🛡️ Cambio a XFile para compatibilidad universal
  XFile? _deliveryPhoto;
  String? _deliveryPhotoName;
  bool _isUploading = false;
  bool _isSavingProductPhoto = false;

  Timer? _proximityTimer;
  int _currentRadarInterval = 10;
  static const double unlockThreshold = 100.0;

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

  Future<void> _checkProximity() async {
    GeoPoint? targetLatLng;
    if (widget.order.status == OrderStatus.enRouteToPickup || widget.order.status == OrderStatus.active) {
      targetLatLng = widget.order.pickupLatLng;
    } else {
      targetLatLng = widget.order.dropoffLatLng;
    }

    if (targetLatLng != null) {
      try {
        // 🛡️ REFUERZO V19.2: Timeout de 5 segundos para el radar de proximidad
        Position pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
        ).timeout(const Duration(seconds: 5));
        
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
    if (kIsWeb) {
      // En Web simplemente abrimos la imagen para que el usuario la guarde manual
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
      return;
    }

    setState(() => _isSavingProductPhoto = true);
    try {
      // Esta lógica se mantiene solo para Nativo
      await http.get(Uri.parse(url));
      // 🛡️ REFUERZO V18.9: Evitamos rastro de Gal en la compilación Web
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("✅ Foto guardada (Simulado en Web)"),
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

  Future<void> _takePhoto(AppLocalizations l10n) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
      if (image != null) {
        // 🛡️ REFUERZO V19.2: Timeout para estampar coordenadas en el nombre del archivo
        Position pos;
        try {
          pos = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
          ).timeout(const Duration(seconds: 4));
        } catch (_) {
          // Si falla el GPS, usamos coordenadas 0 para no bloquear la foto
          pos = Position(longitude: 0, latitude: 0, timestamp: DateTime.now(), accuracy: 0, altitude: 0, altitudeAccuracy: 0, heading: 0, headingAccuracy: 0, speed: 0, speedAccuracy: 0);
        }

        final String dateStr = "${DateTime.now().day}-${DateTime.now().month}";
        final String lat = pos.latitude.toStringAsFixed(2);
        final String lng = pos.longitude.toStringAsFixed(2);
        final String clientName = widget.order.clientName.replaceAll(' ', '_');
        final String orderIdShort = widget.order.id.substring(0, 5);

        final String newName = "LAD_ORD_${orderIdShort}_${clientName}_${dateStr}_Lat${lat}_Lon$lng.jpg";
        
        setState(() {
          _deliveryPhoto = image; // Usamos el XFile directamente
          _deliveryPhotoName = newName;
        });

        // 🛡️ REFUERZO V18.9: Comentamos Gal para asegurar compilación limpia en Web
        /*
        if (!kIsWeb) {
           await Gal.putImage(image.path, album: "LAD_COURIER_EVIDENCE");
        }
        */
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("📸 ${l10n.order_details_evidence_msg}"),
            backgroundColor: Colors.green,
          ));
        }
      }
    } catch (e) { debugPrint("Error foto: $e"); }
  }

  Future<void> _startNavigation(GeoPoint dest, String id, bool isPickup) async {
    final l10n = AppLocalizations.of(context)!;
    
    if (isPickup && widget.order.status == OrderStatus.active) {
      setState(() => _isUploading = true);
      try {
        final messenger = await _userService.getUser(FirebaseAuth.instance.currentUser!.uid);
        final bool isLive = StripeModeService().isLive();
        final String? stripeId = isLive ? messenger?.stripeAccountIdLive : messenger?.stripeAccountId;

        if (stripeId == null) throw "Debes vincular tu cuenta Stripe para recibir pagos.";

        debugPrint("🚀 SISTEMA LAD: Intentando reservar fondos...");

        final HttpsCallable callable = FirebaseFunctions.instanceFor(region: 'us-central1')
            .httpsCallable('authorizeOrderPayment');
            
        final result = await callable.call({
          'amount': ((widget.order.price ?? 0.0) * 100).toInt(),
          'driverStripeAccountId': stripeId,
          'orderId': id,
        });

        if (result.data['success'] != true) {
          throw result.data['error'] ?? 'Fallo en la reserva de fondos.';
        }
      } catch (e) {
        if (context.mounted) {
          _showErrorDialog("Blindaje Financiero LAD", "Error: $e");
        }
        if (mounted) setState(() => _isUploading = false);
        return;
      }
    }

    // 🛡️ REFUERZO V2026.2: Navegación Multi-Plataforma (iPad vs Fire vs Android)
    Uri uri;
    if (kIsWeb) {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // 🍏 IPAD/IPHONE: Salto directo a Apple Maps Nativo
        uri = Uri.parse('https://maps.apple.com/?daddr=${dest.latitude},${dest.longitude}&dirflg=d');
      } else {
        // 🤖 AMAZON FIRE / TABLETS: Usamos el protocolo 'geo' para forzar el GPS del sistema
        // Si no hay app de mapas, Google Maps Web es el fallback automático
        uri = Uri.parse('geo:${dest.latitude},${dest.longitude}?q=${dest.latitude},${dest.longitude}(Destino+LAD)');
        
        // 🛡️ Doble seguridad para Amazon Silk:
        if (await canLaunchUrl(uri) == false) {
           uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${dest.latitude},${dest.longitude}&travelmode=driving');
        }
      }
    } else {
      // Android Nativo APK (Se mantiene tu flujo original de Google Maps App)
      uri = Uri.parse('google.navigation:q=${dest.latitude},${dest.longitude}');
    }

    await _orderService.updateOrderStatus(
        id, isPickup ? OrderStatus.enRouteToPickup : OrderStatus.enRouteToDelivery,
        message: isPickup ? l10n.order_details_en_route_pickup : l10n.order_details_en_route_delivery);
    
    setState(() => _isUploading = false);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showErrorDialog(String title, String msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.red)),
        content: Text(msg),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("ENTENDIDO"))],
      ),
    );
  }

  Future<void> _completeOrder(OrderModel order) async {
    if (_deliveryPhoto == null) return;
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => _isUploading = true);
    
    try {
      final messenger = await _userService.getUser(FirebaseAuth.instance.currentUser!.uid);
      
      final HttpsCallable callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('captureOrderPayment');

      try {
        final result = await callable.call({
          'orderId': order.id,
        });
        if (result.data['success'] != true) {
          throw result.data['error'] ?? "Error Stripe.";
        }
      } catch (stripeError) {
        // 🛡️ REFUERZO V2026.4: Si el error es que ya se cobró (re-intento), lo ignoramos y seguimos
        final String errorStr = stripeError.toString().toLowerCase();
        if (errorStr.contains("already captured") || errorStr.contains("already_captured")) {
           debugPrint("SISTEMA LAD: El pago ya estaba procesado. Continuando con el cierre...");
        } else {
          bool bypass = await _showBypassDialog(stripeError.toString(), l10n);
          if (!bypass) {
            if (mounted) setState(() => _isUploading = false);
            return;
          }
        }
      }

      final String fileName = _deliveryPhotoName ?? "delivery_${order.id}_${DateTime.now().millisecondsSinceEpoch}.jpg";
      final ref = FirebaseStorage.instance.ref().child('delivery_evidence').child(fileName);

      // Subida rápida de evidencia
      await ref.putData(await _deliveryPhoto!.readAsBytes());
      final String downloadUrl = await ref.getDownloadURL();

      // 🛡️ REFUERZO V2026.4: GPS Ultra-rápido (1 seg) para no bloquear al driver
      Position? completionPos;
      try {
        completionPos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.low)
        ).timeout(const Duration(seconds: 1)); 
      } catch (_) {}

      // Actualización final en Firestore (Fuego y Olvido)
      await FirebaseFirestore.instance.collection('orders').doc(order.id).set({
        'status': OrderStatus.completed,
        'statusMessage': '✅ ¡Pedido entregado con éxito!',
        'completionTimestamp': Timestamp.now(),
        'deliveryProofUrl': downloadUrl,
        'driverAuditSelfieUrl': messenger?.lastSessionSelfieUrl,
        'completionLatLng': completionPos != null 
            ? GeoPoint(completionPos.latitude, completionPos.longitude) 
            : null,
      }, SetOptions(merge: true));

      // 🚀 SALIDA INMEDIATA: Volvemos a la zona de trabajo
      if (mounted) {
        navigator.pop();
        scaffoldMessenger.showSnackBar(const SnackBar(
          content: Text("✅ MISIÓN FINALIZADA CON ÉXITO"),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      debugPrint("Error crítico en finalización: $e");
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text("Error: $e")));
        setState(() => _isUploading = false);
      }
    }
  }

  Future<bool> _showBypassDialog(String error, AppLocalizations l10n) async {
    return await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.order_details_bypass_title, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.red)),
        content: Text(l10n.order_details_bypass_body(error)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.common_cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text(l10n.order_details_bypass_btn, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;
  }

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
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.black, size: 28),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(
                chatId: widget.order.id, 
                title: widget.order.clientName,
                targetUserId: widget.order.clientId,
                senderName: widget.order.messengerName ?? "Driver",
              ))),
            ),
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
                label: Text(l10n.order_details_receipt_btn,
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
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
                try {
                  final String? driverId = FirebaseAuth.instance.currentUser?.uid;
                  if (driverId != null) {
                    final String fullAddr = order.pickupAddress.toUpperCase();
                    final RegExp zipRegex = RegExp(r'\b(\d{5}(?:-\d{4})?)\b');
                    final String? zip = zipRegex.firstMatch(fullAddr)?.group(0);

                    String? streetNum;
                    final allNumMatches = RegExp(r'\b\d{1,6}\b').allMatches(fullAddr);
                    for (var m in allNumMatches) {
                      if (m.group(0) != zip) {
                        streetNum = m.group(0);
                        break;
                      }
                    }

                    if (zip != null && streetNum != null) {
                      Position? pos;
                      try {
                        pos = await Geolocator.getCurrentPosition(
                            locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)).timeout(const Duration(seconds: 3));
                      } catch (_) {}

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
                        city: '',
                      );
                    }
                  }
                } catch (e) {
                  debugPrint("LAD Error aprendizaje: $e");
                }
                await _orderService.updateOrderStatus(order.id, OrderStatus.pickedUp, message: "📦 Paquete recogido.");
                if (mounted) Navigator.pop(context);
              }),
            if (isDeliveryPhase && !_isNearPoint)
              _btn(l10n.order_details_btn_go_delivery, Icons.directions_car, Colors.deepPurple, () => _startNavigation(order.dropoffLatLng!, order.id, false)),
            if (isDeliveryPhase) ...[
              if (_deliveryPhoto == null)
                _btn(
                  _isNearPoint ? l10n.order_details_btn_photo : l10n.order_details_geofence_lock,
                  Icons.camera_alt, 
                  _isNearPoint ? Colors.orange : Colors.grey[400]!, 
                  _isNearPoint ? () => _takePhoto(l10n) : null
                )
              else
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
