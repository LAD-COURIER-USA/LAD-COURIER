import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lad_courier/services/geocoding_service.dart';
import 'package:lad_courier/services/order_service.dart';
import 'package:lad_courier/services/storage_service.dart';
import 'package:lad_courier/services/user_service.dart';
import 'package:lad_courier/services/ocr_service.dart';
import 'package:lad_courier/services/geodata_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lad_courier/l10n/app_localizations.dart';
import 'package:lad_courier/pages/client/driver_selection_page.dart';
import 'package:lad_courier/models/user_model.dart';
import 'package:lad_courier/models/order_model.dart'; // 🛡️ IMPORTACIÓN AÑADIDA

class CreateOrderPage extends StatefulWidget {
  final Map<String, dynamic>? selectedMessenger;
  final bool autoStartOCR;
  final OrderModel? reassignOrder; // 🔄 NUEVO: Soporte para reasignación

  const CreateOrderPage({
    super.key,
    this.selectedMessenger,
    this.autoStartOCR = false,
    this.reassignOrder,
  });

  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final OrderService _orderService = OrderService();
  final GeocodingService _geocodingService = GeocodingService();
  final StorageService _storageService = StorageService();
  final UserService _userService = UserService();
  final OCRService _ocrService = OCRService();
  final GeodataService _geodataService = GeodataService();

  bool _isLoading = false;
  String _selectedService = 'courier';
  String? _productPhotoUrl;
  bool _isUploadingPhoto = false;

  Map<String, dynamic>? _currentMessenger;
  List<UserModel> _linkedMessengers = [];
  List<UserModel> _globalMessengers = [];
  UserModel? _clientModel;
  bool _showDriverSelection = false;

  GeoPoint? _validatedPickupLatLng;
  String? _validatedStoreAddress;
  bool _isPickupVerified = false;

  GeoPoint? _validatedDropoffLatLng;
  String? _validatedDropoffAddress;
  bool _isDropoffVerified = false;

  GeocodingResponse? _pickupGoogleRes;
  GeocodingResponse? _dropoffGoogleRes;

  String _detectedCountryCode = "US";

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _currentMessenger = widget.selectedMessenger;
    _showDriverSelection = widget.selectedMessenger == null;

    if (widget.reassignOrder != null) {
      _pickupController.text = widget.reassignOrder!.pickupAddress;
      _dropoffController.text = widget.reassignOrder!.dropoffAddress;
      _descriptionController.text = widget.reassignOrder!.packageDetails ?? '';
      _selectedService = widget.reassignOrder!.serviceType;
      _productPhotoUrl = widget.reassignOrder!.productPhotoUrl;
      _validatedPickupLatLng = widget.reassignOrder!.pickupLatLng;
      _validatedDropoffLatLng = widget.reassignOrder!.dropoffLatLng;
      _isPickupVerified = true; 
      _isDropoffVerified = true;
      _currentMessenger = null; 
      _showDriverSelection = true;
    }

    _loadClientData();
    _loadLinkedMessengers();
    _loadGlobalMessengers();

    _pickupController.addListener(_onPickupChanged);
    _dropoffController.addListener(_onDropoffChanged);
    _descriptionController.addListener(_onDescriptionChanged);

    if (widget.autoStartOCR) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pickProductPhoto();
      });
    }
  }

  void _onPickupChanged() {
    if (_validatedStoreAddress != null && _pickupController.text != _validatedStoreAddress) {
      setState(() {
        _validatedPickupLatLng = null;
        _validatedStoreAddress = null;
        _isPickupVerified = false;
        _pickupGoogleRes = null;
      });
    }
    _triggerDynamicFiltering();
  }

  void _onDropoffChanged() {
    if (_validatedDropoffAddress != null && _dropoffController.text != _validatedDropoffAddress) {
      setState(() {
        _validatedDropoffLatLng = null;
        _validatedDropoffAddress = null;
        _isDropoffVerified = false;
        _dropoffGoogleRes = null;
      });
    }
    _triggerDynamicFiltering();
  }

  void _onDescriptionChanged() {
    if (_descriptionController.text.length == 1) {
      _triggerDynamicFiltering(force: true);
    }
  }

  Future<void> _loadClientData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final user = await _userService.getUser(uid);
      if (mounted) setState(() => _clientModel = user);
    }
  }

  void _triggerDynamicFiltering({bool force = false}) {
    if (_debounce?.isActive ?? false) {
      _debounce?.cancel();
    }
    _debounce = Timer(Duration(milliseconds: force ? 100 : 2500), () async {
      if (!mounted) return;

      // VALIDACIÓN PICKUP
      final String pickupText = _pickupController.text;
      if (pickupText.length >= 10 && _validatedPickupLatLng == null) {
        final anchor = RegExp(r'\b(FL|GA|NC|NV|NY)\s+(\d{5})\b').firstMatch(pickupText.toUpperCase());
        String? zipStr = anchor != null ? anchor.group(2) : RegExp(r'\b\d{5}\b').firstMatch(pickupText)?.group(0);
        String? stateCode = anchor?.group(1);
        String? streetNum;
        final allNumMatches = RegExp(r'\b\d{1,6}\b').allMatches(pickupText);
        for (var m in allNumMatches) { if (m.group(0) != zipStr) { streetNum = m.group(0); break; } }

        bool foundInGeodata = false;
        if (zipStr != null && streetNum != null) {
          final store = await _geodataService.findStoreByDna(zip: zipStr, streetNumber: streetNum, countryCode: _detectedCountryCode, stateCode: stateCode);
          if (store != null && mounted) {
            foundInGeodata = true;
            setState(() { _isPickupVerified = true; _validatedPickupLatLng = GeoPoint(store['gps']['lat'], store['gps']['lon']); _validatedStoreAddress = pickupText; });
          }
        }
        if (!foundInGeodata && _clientModel?.mainAddress != null) {
          if (_normalize(pickupText).contains(_normalize(_clientModel!.mainAddress!))) {
            setState(() { _isPickupVerified = true; _validatedPickupLatLng = _clientModel!.workZoneCenter; _validatedStoreAddress = pickupText; });
            foundInGeodata = true;
          }
        }
        if (!foundInGeodata) {
          final res = await _geocodingService.getFullDetails(pickupText);
          if (mounted && res != null) {
            setState(() { _isPickupVerified = false; _validatedPickupLatLng = res.latLng; _validatedStoreAddress = pickupText; _pickupGoogleRes = res; });
          }
        }
      }

      // VALIDACIÓN DROPOFF
      final String dropoffText = _dropoffController.text;
      if (dropoffText.length >= 10 && _validatedDropoffLatLng == null) {
        final anchor = RegExp(r'\b(FL|GA|NC|NV|NY)\s+(\d{5})\b').firstMatch(dropoffText.toUpperCase());
        String? zipStr = anchor != null ? anchor.group(2) : RegExp(r'\b\d{5}\b').firstMatch(dropoffText)?.group(0);
        String? stateCode = anchor?.group(1);
        String? streetNum;
        final allNumMatches = RegExp(r'\b\d{1,6}\b').allMatches(dropoffText);
        for (var m in allNumMatches) { if (m.group(0) != zipStr) { streetNum = m.group(0); break; } }

        bool foundInGeodata = false;
        if (zipStr != null && streetNum != null) {
          final store = await _geodataService.findStoreByDna(zip: zipStr, streetNumber: streetNum, countryCode: _detectedCountryCode, stateCode: stateCode);
          if (store != null && mounted) {
            foundInGeodata = true;
            setState(() { _isDropoffVerified = true; _validatedDropoffLatLng = GeoPoint(store['gps']['lat'], store['gps']['lon']); _validatedDropoffAddress = dropoffText; });
          }
        }
        if (!foundInGeodata && _clientModel?.mainAddress != null) {
          if (_normalize(dropoffText).contains(_normalize(_clientModel!.mainAddress!))) {
            setState(() { _isDropoffVerified = true; _validatedDropoffLatLng = _clientModel!.workZoneCenter; _validatedDropoffAddress = dropoffText; });
            foundInGeodata = true;
          }
        }
        if (!foundInGeodata) {
          final res = await _geocodingService.getFullDetails(dropoffText);
          if (mounted && res != null) {
            setState(() { _isDropoffVerified = false; _validatedDropoffLatLng = res.latLng; _validatedDropoffAddress = dropoffText; _dropoffGoogleRes = res; });
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _pickupController.removeListener(_onPickupChanged);
    _dropoffController.removeListener(_onDropoffChanged);
    _descriptionController.removeListener(_onDescriptionChanged);
    _pickupController.dispose();
    _dropoffController.dispose();
    _descriptionController.dispose();
    _ocrService.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadLinkedMessengers() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _userService.getLinkedMessengersStream(uid).listen((messengers) {
        if (mounted) setState(() => _linkedMessengers = messengers);
      });
    }
  }

  Future<void> _loadGlobalMessengers() async {
    FirebaseFirestore.instance
        .collection('users')
        .where('role', whereIn: ['MESSENGER', 'DRIVER'])
        .where('isMessengerActive', isEqualTo: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      if (mounted) setState(() => _globalMessengers = snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
    });
  }

  String _normalize(String text) {
    return text.toLowerCase().trim()
        .replaceAll(RegExp(r'[áàäâ]'), 'a').replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i').replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u').replaceAll('ñ', 'n');
  }

  bool _isServiceMatch(List<dynamic> messengerServices, String selectedType) {
    if (messengerServices.isEmpty) return true;
    final services = messengerServices.map((s) => _normalize(s.toString())).toList();
    final selected = _normalize(selectedType);
    if (services.any((s) => s == selected || s.contains(selected) || selected.contains(s))) return true;

    if (selected.contains('courier') || selected.contains('paquet') || selected.contains('mensaj') || selected.contains('envio')) {
      return services.any((s) => s.contains('paquet') || s.contains('courier') || s.contains('coursier') || s.contains('mesaj') || s.contains('envio'));
    } else if (selected.contains('shop') || selected.contains('compra') || selected.contains('encargo')) {
      return services.any((s) => s.contains('compra') || s.contains('shop') || s.contains('acha') || s.contains('mandado'));
    } else if (selected.contains('logist') || selected.contains('carga') || selected.contains('flete')) {
      return services.any((s) => s.contains('logist') || s.contains('carga') || s.contains('flete') || s.contains('truck'));
    }
    return false;
  }

  Future<void> _pickProductPhoto() async {
    setState(() => _isUploadingPhoto = true);
    final url = await _storageService.uploadProductPhoto("prod_${DateTime.now().millisecondsSinceEpoch}", context, onLocalPathPicked: (path) async {
      final ocrResult = await _ocrService.analyzeReceipt(path);
      if (mounted) setState(() => _detectedCountryCode = ocrResult.countryCode ?? "US");
      Map<String, dynamic>? validatedStore;
      if (ocrResult.zipCode != null && ocrResult.streetNumber != null) {
        validatedStore = await _geodataService.findStoreByDna(zip: ocrResult.zipCode!, streetNumber: ocrResult.streetNumber!, countryCode: _detectedCountryCode, stateCode: ocrResult.stateCode);
      }
      if (mounted) _showOcrSuggestions(ocrResult, validatedStore);
    });
    if (mounted && url != null) setState(() => _productPhotoUrl = url);
    setState(() => _isUploadingPhoto = false);
  }

  void _showOcrSuggestions(OCRResult result, Map<String, dynamic>? validatedStore) {
    if (result.fullAddress == null && result.storeName == null && validatedStore == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No se detectó dirección clara. Por favor ingrésala manualmente.")));
      return;
    }
    final String? storeName = validatedStore != null ? validatedStore['name'] : result.storeName;
    final String? address = (validatedStore != null && validatedStore['address'] != null) ? validatedStore['address']['full'] : result.fullAddress;
    final bool isVerified = validatedStore != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Row(children: [Icon(isVerified ? Icons.verified : Icons.auto_awesome, color: isVerified ? Colors.green : Colors.blue, size: 28), const SizedBox(width: 12), Expanded(child: Text(isVerified ? "UBICACIÓN EXACTA" : "DETECCIÓN AUTOMÁTICA", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)))]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (storeName != null) ...[const Text("ESTABLECIMIENTO:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey)), const SizedBox(height: 4), Text(storeName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)), const SizedBox(height: 12)],
          if (address != null) ...[const Text("DIRECCIÓN SUGERIDA:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey)), const SizedBox(height: 4), Text(address.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))],
          const Divider(), const Text("Si la dirección sugerida no coincide, favor editar manualmente.", style: TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900))),
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (address != null) { _pickupController.text = address; if (validatedStore != null) { _isPickupVerified = true; _validatedPickupLatLng = GeoPoint(validatedStore['gps']['lat'], validatedStore['gps']['lon']); } else { _isPickupVerified = false; _triggerDynamicFiltering(); } }
                if (storeName != null) _descriptionController.text = "RECOGER EN $storeName. ${_descriptionController.text}";
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text("AUTO-LLENAR", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _handleOrderAction() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      final pickup = _validatedPickupLatLng ?? await _geocodingService.getLatLng(_pickupController.text);
      final dropoff = _validatedDropoffLatLng ?? await _geocodingService.getLatLng(_dropoffController.text);
      if (!mounted) return;
      if (pickup == null || dropoff == null) throw Exception("No pudimos localizar las direcciones.");
      if (_currentMessenger != null) {
        final driverProfile = await _userService.getUser(_currentMessenger!['id']);
        if (!mounted) return;
        if (driverProfile != null) {
          final error = _checkDriverAvailability(driverProfile, pickup, dropoff);
          if (error != null) { setState(() => _isLoading = false); _showValidationFailedDialog(error); return; }
        }
      }
      if (_currentMessenger == null) {
        if (!mounted) return;
        Navigator.push(context, MaterialPageRoute(builder: (context) => DriverSelectionPage(pickupLatLng: pickup, dropoffLatLng: dropoff, pickupAddress: _pickupController.text, dropoffAddress: _dropoffController.text, serviceType: _selectedService, packageDetails: _descriptionController.text, productPhotoUrl: _productPhotoUrl, countryCode: _detectedCountryCode)));
      } else {
        await _createOrderDirect(pickup, dropoff);
      }
    } catch (e) { 
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)); 
    }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  String? _checkDriverAvailability(UserModel driver, GeoPoint pickup, GeoPoint dropoff) {
    if (!driver.isMessengerActive) return "Driver no disponible.";
    if (!_isServiceMatch(driver.availableServices, _selectedService)) return "Servicio no disponible.";
    if (driver.workZoneCenter != null) {
      final plan = (driver.subscriptionType ?? 'lite').toLowerCase();
      double pLimit = (plan == 'pro' || plan == 'standard') ? 25.0 : 5.0;
      double dLimit = plan == 'pro' ? 120.0 : (plan == 'standard' ? 25.0 : 5.0);
      double distP = Geolocator.distanceBetween(driver.workZoneCenter!.latitude, driver.workZoneCenter!.longitude, pickup.latitude, pickup.longitude) / 1609.34;
      double distD = Geolocator.distanceBetween(driver.workZoneCenter!.latitude, driver.workZoneCenter!.longitude, dropoff.latitude, dropoff.longitude) / 1609.34;
      if (distP > pLimit) return "Recogida fuera de zona.";
      if (distD > dLimit) return "Entrega fuera de zona.";
    } else { return "Zona no configurada."; }
    return null;
  }

  void _showValidationFailedDialog(String reason) {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text("AVISO DE COBERTURA", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
      content: Text(reason.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
        ElevatedButton(onPressed: () { Navigator.pop(context); setState(() { _currentMessenger = null; _showDriverSelection = true; }); }, child: const Text("BUSCAR OTRO")),
      ],
    ));
  }

  Future<void> _createOrderDirect(GeoPoint p, GeoPoint d) async {
    final user = FirebaseAuth.instance.currentUser;
    if (_currentMessenger == null) return;
    await _orderService.createOrder(
      clientId: user!.uid, clientName: user.displayName ?? 'Cliente', clientEmail: user.email, clientPhotoUrl: user.photoURL,
      assignedMessengerId: _currentMessenger!['id'], messengerName: _currentMessenger!['name'], messengerPhotoUrl: _currentMessenger!['photoURL'],
      serviceType: _selectedService, pickupAddress: _pickupController.text, pickupLatLng: p, dropoffAddress: _dropoffController.text, dropoffLatLng: d,
      packageDetails: _descriptionController.text, productPhotoUrl: _productPhotoUrl, countryCode: _detectedCountryCode,
      stripeCustomerId: _clientModel?.stripeCustomerId, paymentMethodId: _clientModel?.defaultPaymentMethodId,
    );
    if (_pickupGoogleRes != null) _geodataService.registerNewValidatedStore(zip: _pickupGoogleRes!.zipCode ?? "", streetNumber: _pickupGoogleRes!.streetNumber ?? "", storeName: "Punto de Recogida", fullAddress: _pickupGoogleRes!.fullAddress, lat: _pickupGoogleRes!.latLng.latitude, lng: _pickupGoogleRes!.latLng.longitude, driverId: _currentMessenger!['id'], stateCode: _pickupGoogleRes!.state);
    if (_dropoffGoogleRes != null) _geodataService.registerNewValidatedStore(zip: _dropoffGoogleRes!.zipCode ?? "", streetNumber: _dropoffGoogleRes!.streetNumber ?? "", storeName: "Punto de Entrega", fullAddress: _dropoffGoogleRes!.fullAddress, lat: _dropoffGoogleRes!.latLng.latitude, lng: _dropoffGoogleRes!.latLng.longitude, driverId: _currentMessenger!['id'], stateCode: _dropoffGoogleRes!.state);
    
    // 🛡️ SISTEMA LAD: Si es una reasignación, eliminamos la orden rechazada anterior
    if (widget.reassignOrder != null) {
      await FirebaseFirestore.instance.collection('orders').doc(widget.reassignOrder!.id).delete();
    }

    if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🚀 ¡ORDEN ENVIADA EXITOSAMENTE!"), backgroundColor: Colors.green)); }
  }

  void _showFullImage(String url) {
    showDialog(context: context, builder: (context) => Dialog(backgroundColor: Colors.black, child: InteractiveViewer(child: Image.network(url))));
  }

  List<UserModel> get _filteredMessengers {
    final all = [..._linkedMessengers, ..._globalMessengers];
    final unique = <String, UserModel>{};
    for (var m in all) { unique[m.uid] = m; }
    final filtered = unique.values.where((m) {
      if (!m.isMessengerActive || !_isServiceMatch(m.availableServices, _selectedService) || m.workZoneCenter == null) return false;
      final plan = (m.subscriptionType ?? 'lite').toLowerCase();
      double pLimit = (plan == 'pro' || plan == 'standard') ? 25.0 : 5.0;
      double dLimit = plan == 'pro' ? 120.0 : (plan == 'standard' ? 25.0 : 5.0);
      if (_validatedPickupLatLng != null) { if (Geolocator.distanceBetween(m.workZoneCenter!.latitude, m.workZoneCenter!.longitude, _validatedPickupLatLng!.latitude, _validatedPickupLatLng!.longitude) / 1609.34 > pLimit) return false; }
      if (_validatedDropoffLatLng != null) { if (Geolocator.distanceBetween(m.workZoneCenter!.latitude, m.workZoneCenter!.longitude, _validatedDropoffLatLng!.latitude, _validatedDropoffLatLng!.longitude) / 1609.34 > dLimit) return false; }
      return true;
    }).toList();
    if (_validatedPickupLatLng != null) filtered.sort((a, b) => Geolocator.distanceBetween(a.workZoneCenter!.latitude, a.workZoneCenter!.longitude, _validatedPickupLatLng!.latitude, _validatedPickupLatLng!.longitude).compareTo(Geolocator.distanceBetween(b.workZoneCenter!.latitude, b.workZoneCenter!.longitude, _validatedPickupLatLng!.latitude, _validatedPickupLatLng!.longitude)));
    return filtered.length > 5 ? filtered.sublist(0, 5) : filtered;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          l10n.create_order_title.toUpperCase(), 
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black, letterSpacing: 1.5)
        ), 
        centerTitle: true, 
        backgroundColor: Colors.white, 
        elevation: 0.5,
        foregroundColor: Colors.black, // Asegura contraste en botones de regreso
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24), 
        child: Form(
          key: _formKey, 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, 
            children: [
              const SizedBox(height: 20), 
              _buildSectionTitle(l10n.create_order_service_type, Icons.layers_outlined, Colors.indigo[900]!), 
              _buildServiceSelector(l10n),
              const SizedBox(height: 30), 
              _buildSectionTitle(l10n.create_order_add_photo, Icons.camera_alt_outlined, Colors.teal[900]!), 
              _buildPhotoPicker(l10n),
              const SizedBox(height: 30), 
              _buildSectionTitle(l10n.create_order_pickup_label, Icons.location_on_outlined, Colors.deepPurple[900]!), 
              _buildModernField(_pickupController, "PUNTO DE ORIGEN", Icons.storefront, Colors.deepPurple[900]!, isPickup: true, lines: 2),
              const SizedBox(height: 30), 
              _buildSectionTitle(l10n.create_order_dropoff_label, Icons.flag_outlined, Colors.orange[900]!), 
              _buildModernField(_dropoffController, "PUNTO DE DESTINO", Icons.home_outlined, Colors.orange[900]!, isDropoff: true, lines: 2),
              const SizedBox(height: 30), 
              _buildSectionTitle(l10n.create_order_description_label, Icons.assignment_outlined, Colors.blue[900]!), 
              _buildModernField(_descriptionController, "DETALLES DEL PAQUETE / RECIBO", Icons.edit_note, Colors.blue[900]!, lines: 3),
              if (_showDriverSelection) ...[
                const SizedBox(height: 30), 
                _buildSectionTitle(l10n.create_order_section_messenger, Icons.person_search_outlined, Colors.black), 
                _buildDriverSwitcher(l10n)
              ],
              const SizedBox(height: 40), 
              _buildActionButton(l10n), 
              const SizedBox(height: 50),
            ]
          )
        )
      ),
    );
  }

  // --- WIDGETS DE APOYO (REVISADOS) ---
  Widget _buildSectionTitle(String title, IconData icon, Color color) => Padding(padding: const EdgeInsets.only(bottom: 15, left: 4), child: Row(children: [Icon(icon, size: 18, color: color), const SizedBox(width: 8), Text(title.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: color, letterSpacing: 1.1))]));

  Widget _buildDriverSwitcher(AppLocalizations l10n) {
    final messengers = _filteredMessengers;
    return SizedBox(height: 150, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: messengers.length + 1, itemBuilder: (context, index) {
      if (index == 0) return GestureDetector(onTap: () => setState(() => _currentMessenger = null), child: _buildDriverAvatar(null, l10n.create_order_search_available, _currentMessenger == null));
      final m = messengers[index - 1];
      return GestureDetector(onTap: () => setState(() => _currentMessenger = { 'id': m.uid, 'name': m.displayName, 'photoURL': m.photoURL, 'availableServices': m.availableServices }), child: _buildDriverAvatar(m, m.displayName ?? "Driver", _currentMessenger != null && _currentMessenger!['id'] == m.uid));
    }));
  }

  Widget _buildDriverAvatar(UserModel? driver, String name, bool selected) => AnimatedContainer(duration: const Duration(milliseconds: 300), width: 140, margin: const EdgeInsets.only(right: 15, bottom: 5), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), border: Border.all(color: selected ? Colors.black : Colors.grey[200]!, width: selected ? 2.5 : 1)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Stack(children: [CircleAvatar(radius: 24, backgroundColor: Colors.grey[100], backgroundImage: driver?.photoURL != null ? NetworkImage(driver!.photoURL!) : null, child: driver?.photoURL == null ? const Icon(Icons.person, color: Colors.grey, size: 24) : null), if (driver != null) Positioned(right: 0, bottom: 0, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: (driver.isMessengerActive && _isServiceMatch(driver.availableServices, _selectedService)) ? Colors.green : Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))))]),
    const SizedBox(height: 6), Text(name.toUpperCase(), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: selected ? Colors.black : Colors.blueGrey)),
    if (driver != null) ...[const SizedBox(height: 2), Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.star, color: Colors.amber, size: 10), const SizedBox(width: 2), Text(driver.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold))])]
  ]));

  Widget _buildServiceSelector(AppLocalizations l10n) {
    final options = {'courier': l10n.driver_service_courier, 'shopping': l10n.driver_service_shopping, 'logistics': l10n.driver_service_logistics};
    return Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[200]!)), child: Column(children: options.entries.map((e) {
      bool isSel = _selectedService == e.key;
      return GestureDetector(onTap: () => setState(() => _selectedService = e.key), child: AnimatedContainer(duration: const Duration(milliseconds: 250), margin: const EdgeInsets.symmetric(vertical: 4), padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16), decoration: BoxDecoration(color: isSel ? Colors.black : Colors.white, borderRadius: BorderRadius.circular(15)), child: Row(children: [Icon(e.key == 'courier' ? Icons.local_post_office_outlined : (e.key == 'shopping' ? Icons.shopping_bag_outlined : Icons.local_shipping_outlined), color: isSel ? Colors.greenAccent : Colors.black54, size: 22), const SizedBox(width: 15), Expanded(child: Text(e.value.toUpperCase(), style: TextStyle(color: isSel ? Colors.white : Colors.black, fontWeight: FontWeight.w900, fontSize: 12))), if (isSel) const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20)])));
    }).toList()));
  }

  Widget _buildPhotoPicker(AppLocalizations l10n) => GestureDetector(onTap: _isUploadingPhoto ? null : _pickProductPhoto, child: Container(height: 180, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.grey[200]!, width: 2)), child: _isUploadingPhoto ? const Center(child: CircularProgressIndicator(color: Colors.black)) : _productPhotoUrl != null ? Stack(children: [ClipRRect(borderRadius: BorderRadius.circular(23), child: Image.network(_productPhotoUrl!, width: double.infinity, height: 180, fit: BoxFit.cover)), Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(23), color: Colors.black26)), const Center(child: Icon(Icons.sync, color: Colors.white, size: 40)), Positioned(right: 10, bottom: 10, child: IconButton(icon: const Icon(Icons.fullscreen, color: Colors.white), onPressed: () => _showFullImage(_productPhotoUrl!)))]) : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 45, color: Colors.teal), SizedBox(height: 12), Text("SUBIR FOTO O RECIBO", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.w900, fontSize: 13))] )));

  Widget _buildModernField(TextEditingController controller, String label, IconData icon, Color color, {int lines = 1, bool isPickup = false, bool isDropoff = false}) {
    bool isVer = (isPickup && _isPickupVerified) || (isDropoff && _isDropoffVerified);
    bool isKnown = (isPickup && _validatedPickupLatLng != null) || (isDropoff && _validatedDropoffLatLng != null);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        decoration: BoxDecoration(
          color: isVer ? Colors.green[50] : (isKnown ? Colors.amber[50] : Colors.white), 
          borderRadius: BorderRadius.circular(18), 
          border: Border.all(color: isVer ? Colors.green[700]! : (isKnown ? Colors.amber[700]! : Colors.grey[400]!), width: isKnown ? 2 : 1)
        ), 
        child: TextFormField(
          controller: controller, 
          maxLines: lines, 
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black), // Texto más grande y negro sólido
          decoration: InputDecoration(
            labelText: label.toUpperCase(), 
            labelStyle: TextStyle(color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w900, fontSize: 11), // Etiquetas con el color de la sección pero más fuertes
            prefixIcon: Icon(icon, color: isVer ? Colors.green[900] : color, size: 24), 
            border: InputBorder.none, 
            contentPadding: const EdgeInsets.all(20)
          )
        )
      ),
      if (controller.text.isNotEmpty && isKnown) Padding(padding: const EdgeInsets.only(top: 8, left: 12), child: Text(isVer ? "✓ UBICACIÓN EXACTA VERIFICADA (SISTEMA LAD)" : "⚠ LA DIRECCIÓN NO ES TAN PRECISA, EL DRIVER HARÁ LO POSIBLE POR ENCONTRARLA.", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isVer ? Colors.green[900] : Colors.amber[900]))),
    ]);
  }

  Widget _buildActionButton(AppLocalizations l10n) {
    bool hasP = _clientModel?.defaultPaymentMethodId != null;
    return Column(children: [
      if (!hasP) Padding(padding: const EdgeInsets.only(bottom: 20), child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.red[200]!)), child: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.red), SizedBox(width: 10), Expanded(child: Text("DEBES VINCULAR UN MÉTODO DE PAGO EN TU PERFIL PARA SOLICITAR SERVICIOS.", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)))]))),
      SizedBox(width: double.infinity, height: 65, child: ElevatedButton(onPressed: (_isLoading || !hasP) ? null : _handleOrderAction, style: ElevatedButton.styleFrom(backgroundColor: hasP ? Colors.black : Colors.grey[400], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))), child: _isLoading ? const CircularProgressIndicator(color: Colors.greenAccent) : Text(l10n.create_order_btn_send.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white)))),
    ]);
  }
}
