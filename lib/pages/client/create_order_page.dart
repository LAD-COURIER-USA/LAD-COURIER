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

class CreateOrderPage extends StatefulWidget {
  final Map<String, dynamic>? selectedMessenger;
  final bool autoStartOCR;

  const CreateOrderPage({
    super.key,
    this.selectedMessenger,
    this.autoStartOCR = false
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

  // 🧠 Variables para el Auto-Aprendizaje
  GeocodingResponse? _pickupGoogleRes;
  GeocodingResponse? _dropoffGoogleRes;

  String _detectedCountryCode = "US"; // 🌍 PAÍS DETECTADO

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _currentMessenger = widget.selectedMessenger;
    _showDriverSelection = widget.selectedMessenger == null;
    
    _loadClientData();
    _loadLinkedMessengers();
    _loadGlobalMessengers();

    _pickupController.addListener(_onPickupChanged);
    _dropoffController.addListener(_onDropoffChanged);
    _descriptionController.addListener(_onDescriptionChanged); // 🚀 TRIGGER INTELIGENTE

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

  // 🚀 NUEVO: Valida direcciones cuando el cliente empieza a escribir la descripción
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
    // ⏳ RETRASO ESTRATÉGICO: 2.5 segundos de espera
    _debounce = Timer(Duration(milliseconds: force ? 100 : 2500), () async {
      if (!mounted) return;

      final String pickupText = _pickupController.text;
      // 📏 MÍNIMO 10 CARACTERES para no gastar API por gusto
      if (pickupText.length >= 10 && _validatedPickupLatLng == null) {
        // 1. Identificar Ancla Inconfundible (Estado + ZIP)
        final anchor = RegExp(r'\b(FL|GA|NC|NV|NY)\s+(\d{5})\b').firstMatch(pickupText.toUpperCase());
        String? zipStr;
        String? stateCode;
        
        if (anchor != null) {
          stateCode = anchor.group(1);
          zipStr = anchor.group(2);
        } else {
          zipStr = RegExp(r'\b\d{5}\b').firstMatch(pickupText)?.group(0);
        }

        String? streetNum;
        final allNumMatches = RegExp(r'\b\d{1,6}\b').allMatches(pickupText);
        for (var m in allNumMatches) {
          if (m.group(0) != zipStr) {
            streetNum = m.group(0);
            break;
          }
        }

        bool foundInGeodata = false;
        if (zipStr != null && streetNum != null) {
          final store = await _geodataService.findStoreByDna(
              zip: zipStr, 
              streetNumber: streetNum,
              countryCode: _detectedCountryCode,
              stateCode: stateCode
          );
          if (store != null && mounted) {
            foundInGeodata = true;
            setState(() {
              _isPickupVerified = true;
              _validatedPickupLatLng = GeoPoint(store['gps']['lat'], store['gps']['lon']);
              _validatedStoreAddress = pickupText;
            });
          }
        }

        if (!foundInGeodata && _clientModel?.mainAddress != null) {
           if (_normalize(pickupText).contains(_normalize(_clientModel!.mainAddress!))) {
             setState(() {
               _isPickupVerified = true;
               _validatedPickupLatLng = _clientModel!.workZoneCenter; 
               _validatedStoreAddress = pickupText;
             });
             foundInGeodata = true;
           }
        }

        // 3. Fallback a Geocoding API (Solo si no se encontró en LAD)
        if (!foundInGeodata) {
          final res = await _geocodingService.getFullDetails(pickupText);
          if (mounted && res != null) {
            setState(() {
              _isPickupVerified = false;
              _validatedPickupLatLng = res.latLng;
              _validatedStoreAddress = pickupText;
              _pickupGoogleRes = res; // Guardamos para el auto-aprendizaje
            });
          }
        }
      }

      final String dropoffText = _dropoffController.text;
      if (dropoffText.length >= 10 && _validatedDropoffLatLng == null) {
        bool found = false;
        
        if (_clientModel?.mainAddress != null) {
          if (_normalize(dropoffText).contains(_normalize(_clientModel!.mainAddress!))) {
            setState(() {
              _isDropoffVerified = true;
              _validatedDropoffLatLng = _clientModel!.workZoneCenter;
              _validatedDropoffAddress = dropoffText;
            });
            found = true;
          }
        }

        if (!found) {
          final res = await _geocodingService.getFullDetails(dropoffText);
          if (mounted && res != null) {
            setState(() {
              _isDropoffVerified = false;
              _validatedDropoffLatLng = res.latLng;
              _validatedDropoffAddress = dropoffText;
              _dropoffGoogleRes = res; // Guardamos para el auto-aprendizaje
            });
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
        .where('role', whereIn: ['MESSENGER', 'DRIVER']) // 🛡️ UNIFICACIÓN DE ROLES
        .where('isMessengerActive', isEqualTo: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _globalMessengers = snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
        });
      }
    });
  }

  String _normalize(String text) {
    return text.toLowerCase().trim()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll('ñ', 'n');
  }

  bool _isServiceMatch(List<dynamic> messengerServices, String selectedType) {
    if (messengerServices.isEmpty) return true; // 🛡️ SISTEMA LAD: Si no tiene servicios definidos, lo mostramos por defecto
    
    final services = messengerServices.map((s) => _normalize(s.toString())).toList();
    final selected = _normalize(selectedType);
    
    // Coincidencia exacta o contenida
    if (services.any((s) => s == selected || s.contains(selected) || selected.contains(s))) {
      return true;
    }

    // Lógica difusa por categorías (Español/Inglés/Kreyòl)
    if (selected.contains('courier') || selected.contains('paquet') || selected.contains('mensaj') || selected.contains('envio')) {
      return services.any((s) => 
        s.contains('paquet') || s.contains('courier') || s.contains('coursier') || 
        s.contains('correio') || s.contains('kouriye') || s.contains('mesaj') || 
        s.contains('envio') || s.contains('carta') || s.contains('docum'));
    } else if (selected.contains('shop') || selected.contains('compra') || selected.contains('encargo') || selected.contains('mandado')) {
      return services.any((s) => 
        s.contains('compra') || s.contains('shop') || s.contains('achat') || 
        s.contains('acha') || s.contains('komisyon') || s.contains('mandado') || 
        s.contains('super') || s.contains('comida') || s.contains('food'));
    } else if (selected.contains('logist') || selected.contains('carga') || selected.contains('flete') || selected.contains('mudanza')) {
      return services.any((s) => 
        s.contains('logist') || s.contains('carga') || s.contains('flete') || 
        s.contains('especializada') || s.contains('mudanza') || s.contains('truck') || s.contains('camion'));
    }
    return false;
  }

  Future<void> _pickProductPhoto() async {
    setState(() => _isUploadingPhoto = true);

    final url = await _storageService.uploadProductPhoto(
        "prod_${DateTime.now().millisecondsSinceEpoch}",
        context,
        onLocalPathPicked: (path) async {
          final ocrResult = await _ocrService.analyzeReceipt(path);

          if (mounted) {
            setState(() {
              _detectedCountryCode = ocrResult.countryCode ?? "US";
            });
          }

          Map<String, dynamic>? validatedStore;
          if (ocrResult.zipCode != null && ocrResult.streetNumber != null) {
            validatedStore = await _geodataService.findStoreByDna(
                zip: ocrResult.zipCode!,
                streetNumber: ocrResult.streetNumber!,
                countryCode: _detectedCountryCode,
                stateCode: ocrResult.stateCode
            );
          }

          if (mounted) {
            _showOcrSuggestions(ocrResult, validatedStore);
          }
        }
    );

    if (!mounted) return;
    if (url != null) setState(() => _productPhotoUrl = url);
    setState(() => _isUploadingPhoto = false);
  }

  void _showOcrSuggestions(OCRResult result, Map<String, dynamic>? validatedStore) {
    if (result.fullAddress == null && result.storeName == null && validatedStore == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No se detectó dirección clara. Por favor ingrésala manualmente.")));
      return;
    }

    final String? storeName = validatedStore != null ? validatedStore['name'] : result.storeName;
    final String? address = (validatedStore != null && validatedStore['address'] != null)
        ? validatedStore['address']['full']
        : result.fullAddress;
    final bool isVerified = validatedStore != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Row(
          children: [
            Icon(isVerified ? Icons.verified : (result.usedFLAI ? Icons.auto_awesome : Icons.search),
                color: isVerified ? Colors.green : (result.usedFLAI ? Colors.blue : Colors.grey), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(isVerified ? "UBICACIÓN EXACTA" : "DETECCIÓN AUTOMÁTICA",
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (storeName != null) ...[
              const Text("ESTABLECIMIENTO:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey)),
              const SizedBox(height: 4),
              Text(storeName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.black)),
              const SizedBox(height: 12),
            ],
            if (address != null) ...[
              const Text("DIRECCIÓN SUGERIDA:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey)),
              const SizedBox(height: 4),
              Text(address.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
            ],
            const SizedBox(height: 15),
            const Divider(),
            const SizedBox(height: 10),
            const Text(
                "Si la dirección sugerida no coincide con la del punto para la recogida del producto, favor editar manualmente.",
                style: TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 10),
            Text(isVerified
                ? "Ubicación verificada en nuestra base de datos. ¿Usar para auto-llenado?"
                : "¿Deseas auto-llenar los campos detectados en tu orden?",
                style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () { Navigator.pop(context); },
              child: const Text("CANCELAR", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900))
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (address != null) {
                  _pickupController.text = address;
                  if (validatedStore != null && validatedStore['gps'] != null) {
                    _validatedStoreAddress = address;
                    _isPickupVerified = true;
                    _validatedPickupLatLng = GeoPoint(
                        validatedStore['gps']['lat'],
                        validatedStore['gps']['lon']
                    );
                  } else {
                    _isPickupVerified = false;
                    _triggerDynamicFiltering();
                  }
                }
                if (storeName != null) {
                  _descriptionController.text = "RECOGER EN $storeName. ${_descriptionController.text}";
                }
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
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Por favor, completa los campos obligatorios."), backgroundColor: Colors.redAccent));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final pickup = _validatedPickupLatLng ?? await _geocodingService.getLatLng(_pickupController.text);
      final dropoff = _validatedDropoffLatLng ?? await _geocodingService.getLatLng(_dropoffController.text);

      if (!mounted) return;
      if (pickup == null || dropoff == null) {
        throw Exception("No pudimos localizar las direcciones. Verifica que sean correctas.");
      }

      if (_currentMessenger != null) {
        final driverId = _currentMessenger!['id'];
        final driverProfile = await _userService.getUser(driverId);
        
        if (!mounted) return;

        if (driverProfile != null) {
          final validationError = _checkDriverAvailability(driverProfile, pickup, dropoff);
          if (validationError != null) {
            setState(() => _isLoading = false);
            _showValidationFailedDialog(validationError);
            return;
          }
        }
      }

      if (_currentMessenger == null) {
        if (!mounted) return;
        Navigator.push(context, MaterialPageRoute(builder: (context) => DriverSelectionPage(
          pickupLatLng: pickup,
          dropoffLatLng: dropoff,
          pickupAddress: _pickupController.text,
          dropoffAddress: _dropoffController.text,
          serviceType: _selectedService,
          packageDetails: _descriptionController.text,
          productPhotoUrl: _productPhotoUrl,
          countryCode: _detectedCountryCode, 
        )));
      } else {
        await _createOrderDirect(pickup, dropoff);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _checkDriverAvailability(UserModel driver, GeoPoint pickup, GeoPoint dropoff) {
    if (!driver.isMessengerActive) return "Driver no disponible (Modo descanso).";
    if (!_isServiceMatch(driver.availableServices, _selectedService)) {
      return "Servicio ${_selectedService.toUpperCase()} no disponible con este driver.";
    }

    if (driver.workZoneCenter != null) {
      final plan = (driver.subscriptionType ?? 'lite').toLowerCase();
      double pickupLimit = 5.0;
      double dropoffLimit = 5.0;

      if (plan == 'standard' || plan == 'standart') {
        pickupLimit = 25.0;
        dropoffLimit = 25.0;
      } else if (plan == 'pro') {
        pickupLimit = 25.0;
        dropoffLimit = 120.0;
      }
      
      double distP = Geolocator.distanceBetween(
          driver.workZoneCenter!.latitude, driver.workZoneCenter!.longitude,
          pickup.latitude, pickup.longitude
      ) / 1609.34;

      double distD = Geolocator.distanceBetween(
          driver.workZoneCenter!.latitude, driver.workZoneCenter!.longitude,
          dropoff.latitude, dropoff.longitude
      ) / 1609.34;

      if (distP > pickupLimit) return "Punto de RECOGIDA fuera de zona (${pickupLimit}mi).";
      if (distD > dropoffLimit) return "Punto de ENTREGA fuera de zona (${dropoffLimit}mi).";
    } else {
      return "Zona de cobertura no configurada.";
    }
    return null; 
  }

  void _showValidationFailedDialog(String reason) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Expanded(child: Text("AVISO DE COBERTURA", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              reason.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.redAccent),
            ),
            const SizedBox(height: 15),
            const Text(
              "¿DESEAS BUSCAR OTRO DRIVER DISPONIBLE?",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 11, color: Colors.blueGrey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); },
            child: const Text("CANCELAR", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentMessenger = null;
                _showDriverSelection = true;
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text("BUSCAR OTRO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _createOrderDirect(GeoPoint p, GeoPoint d) async {
    final user = FirebaseAuth.instance.currentUser;
    if (_currentMessenger == null) return;

    await _orderService.createOrder(
      clientId: user!.uid, clientName: user.displayName ?? 'Cliente', clientPhotoUrl: user.photoURL,
      assignedMessengerId: _currentMessenger!['id'], messengerName: _currentMessenger!['name'],
      messengerPhotoUrl: _currentMessenger!['photoURL'], serviceType: _selectedService,
      pickupAddress: _pickupController.text, pickupLatLng: p, dropoffAddress: _dropoffController.text,
      dropoffLatLng: d, packageDetails: _descriptionController.text, productPhotoUrl: _productPhotoUrl,
      countryCode: _detectedCountryCode, 
    );

    // 🧠 AUTO-APRENDIZAJE: Si la dirección vino de Google, la enseñamos a LAD
    if (_pickupGoogleRes != null) {
      await _geodataService.registerNewValidatedStore(
          zip: _pickupGoogleRes!.zipCode ?? "",
          streetNumber: _pickupGoogleRes!.streetNumber ?? "",
          storeName: "Punto de Recogida",
          fullAddress: _pickupGoogleRes!.fullAddress,
          lat: _pickupGoogleRes!.latLng.latitude,
          lng: _pickupGoogleRes!.latLng.longitude,
          driverId: _currentMessenger!['id'],
          stateCode: _pickupGoogleRes!.state
      );
    }
    if (_dropoffGoogleRes != null) {
      await _geodataService.registerNewValidatedStore(
          zip: _dropoffGoogleRes!.zipCode ?? "",
          streetNumber: _dropoffGoogleRes!.streetNumber ?? "",
          storeName: "Punto de Entrega",
          fullAddress: _dropoffGoogleRes!.fullAddress,
          lat: _dropoffGoogleRes!.latLng.latitude,
          lng: _dropoffGoogleRes!.latLng.longitude,
          driverId: _currentMessenger!['id'],
          stateCode: _dropoffGoogleRes!.state
      );
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🚀 ¡ORDEN ENVIADA EXITOSAMENTE!"), backgroundColor: Colors.green));
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

  List<UserModel> get _filteredMessengers {
    final allCandidates = [..._linkedMessengers, ..._globalMessengers];
    final uniqueCandidates = <String, UserModel>{};
    for (var m in allCandidates) {
      uniqueCandidates[m.uid] = m;
    }

    final filtered = uniqueCandidates.values.where((m) {
      if (!m.isMessengerActive) return false;
      if (!_isServiceMatch(m.availableServices, _selectedService)) return false;
      if (m.workZoneCenter == null) return false;

      final plan = (m.subscriptionType ?? 'lite').toLowerCase();
      double pickupLimit = 5.0;
      double dropoffLimit = 5.0;

      if (plan == 'standard' || plan == 'standart') {
        pickupLimit = 25.0;
        dropoffLimit = 25.0;
      } else if (plan == 'pro') {
        pickupLimit = 25.0;
        dropoffLimit = 120.0;
      }

      if (_validatedPickupLatLng != null) {
        double distP = Geolocator.distanceBetween(
            m.workZoneCenter!.latitude, m.workZoneCenter!.longitude,
            _validatedPickupLatLng!.latitude, _validatedPickupLatLng!.longitude
        ) / 1609.34;
        if (distP > pickupLimit) return false;
      }

      if (_validatedDropoffLatLng != null) {
        double distD = Geolocator.distanceBetween(
            m.workZoneCenter!.latitude, m.workZoneCenter!.longitude,
            _validatedDropoffLatLng!.latitude, _validatedDropoffLatLng!.longitude
        ) / 1609.34;
        if (distD > dropoffLimit) return false;
      }

      return true;
    }).toList();

    if (_validatedPickupLatLng != null) {
      filtered.sort((a, b) {
        double distA = Geolocator.distanceBetween(
            a.workZoneCenter!.latitude, a.workZoneCenter!.longitude,
            _validatedPickupLatLng!.latitude, _validatedPickupLatLng!.longitude
        );
        double distB = Geolocator.distanceBetween(
            b.workZoneCenter!.latitude, b.workZoneCenter!.longitude,
            _validatedPickupLatLng!.latitude, _validatedPickupLatLng!.longitude
        );
        return distA.compareTo(distB);
      });
    }

    return filtered.length > 5 ? filtered.sublist(0, 5) : filtered;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(l10n.create_order_title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black, letterSpacing: 2)),
        centerTitle: true, backgroundColor: Colors.white, elevation: 0.5, foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // 1️⃣ TIPO DE SERVICIO
              _buildSectionTitle(l10n.create_order_service_type, Icons.layers_outlined, Colors.indigo),
              _buildServiceSelector(l10n),
              const SizedBox(height: 30),
              // 2️⃣ FOTO DEL PRODUCTO
              _buildSectionTitle(l10n.create_order_add_photo, Icons.camera_alt_outlined, Colors.teal),
              _buildPhotoPicker(l10n),
              const SizedBox(height: 30),
              // 3️⃣ DIRECCIÓN DE RECOGIDA
              _buildSectionTitle(l10n.create_order_pickup_label, Icons.location_on_outlined, Colors.deepPurple),
              _buildModernField(_pickupController, "PUNTO DE ORIGEN", Icons.storefront, Colors.deepPurple, isPickup: true, lines: 2),
              const SizedBox(height: 30),
              // 4️⃣ DIRECCIÓN DE ENTREGA
              _buildSectionTitle(l10n.create_order_dropoff_label, Icons.flag_outlined, Colors.orange),
              _buildModernField(_dropoffController, "PUNTO DE DESTINO", Icons.home_outlined, Colors.orange, isDropoff: true, lines: 2),
              const SizedBox(height: 30),
              // 5️⃣ DETALLES DEL PAQUETE (Trigger de Validación)
              _buildSectionTitle(l10n.create_order_description_label, Icons.assignment_outlined, Colors.blue),
              _buildModernField(_descriptionController, "DETALLES DEL PAQUETE / RECIBO", Icons.edit_note, Colors.blue, lines: 3),
              const SizedBox(height: 30),
              
              if (_showDriverSelection) ...[
                _buildSectionTitle(l10n.create_order_section_messenger, Icons.person_search_outlined, Colors.black),
                _buildDriverSwitcher(l10n),
              ],
              
              const SizedBox(height: 40),
              _buildActionButton(l10n),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(title.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: color, letterSpacing: 1.1)),
        ],
      ),
    );
  }

  Widget _buildDriverSwitcher(AppLocalizations l10n) {
    final messengers = _filteredMessengers;
    return Container(
      height: 150,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: messengers.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            bool isNone = _currentMessenger == null;
            return GestureDetector(
              onTap: () { setState(() { _currentMessenger = null; }); },
              child: _buildDriverAvatar(null, l10n.create_order_search_available, isNone),
            );
          }
          final m = messengers[index - 1];
          bool isSelected = _currentMessenger != null && _currentMessenger!['id'] == m.uid;
          return GestureDetector(
            onTap: () {
              setState(() {
                _currentMessenger = { 'id': m.uid, 'name': m.displayName, 'photoURL': m.photoURL, 'availableServices': m.availableServices };
              });
            },
            child: _buildDriverAvatar(m, m.displayName ?? "Driver", isSelected),
          );
        },
      ),
    );
  }

  Widget _buildDriverAvatar(UserModel? driver, String name, bool selected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 140,
      margin: const EdgeInsets.only(right: 15, bottom: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: selected ? Colors.black : Colors.grey[200]!, width: selected ? 2.5 : 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: selected ? 0.08 : 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey[100],
                backgroundImage: driver?.photoURL != null ? NetworkImage(driver!.photoURL!) : null,
                child: driver?.photoURL == null ? const Icon(Icons.person, color: Colors.grey, size: 24) : null,
              ),
              if (driver != null)
                Positioned(right: 0, bottom: 0, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: (driver.isMessengerActive && _isServiceMatch(driver.availableServices, _selectedService)) ? Colors.green : Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
            ],
          ),
          const SizedBox(height: 6),
          Text(name.toUpperCase(),
            textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: selected ? Colors.black : Colors.blueGrey),
          ),
          if (driver != null) ...[
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 10),
                const SizedBox(width: 2),
                Text(driver.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                const Icon(Icons.directions_car, color: Colors.blueGrey, size: 10),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildServiceSelector(AppLocalizations l10n) {
    final Map<String, String> serviceOptions = {
      'courier': l10n.driver_service_courier,
      'shopping': l10n.driver_service_shopping,
      'logistics': l10n.driver_service_logistics,
    };

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[200]!)),
      child: Column(
        children: serviceOptions.entries.map((entry) {
          final sKey = entry.key;
          final sLabel = entry.value;
          bool isSel = _selectedService == sKey;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedService = sKey;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: isSel ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: isSel ? Colors.black : Colors.transparent),
              ),
              child: Row(
                children: [
                  Icon(
                    sKey == 'courier' ? Icons.local_post_office_outlined : (sKey == 'shopping' ? Icons.shopping_bag_outlined : Icons.local_shipping_outlined),
                    color: isSel ? Colors.greenAccent : Colors.black54, size: 22,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(sLabel.toUpperCase(), style: TextStyle(color: isSel ? Colors.white : Colors.black, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
                  ),
                  if (isSel)
                    const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPhotoPicker(AppLocalizations l10n) {
    return GestureDetector(
      onTap: _isUploadingPhoto ? null : _pickProductPhoto,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.grey[200]!, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: _isUploadingPhoto
            ? const Center(child: CircularProgressIndicator(color: Colors.black))
            : _productPhotoUrl != null
            ? Stack(
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(23), child: Image.network(_productPhotoUrl!, width: double.infinity, height: 180, fit: BoxFit.cover)),
            Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(23), gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black26, Colors.transparent, Colors.black45]))),
            const Center(child: Icon(Icons.sync, color: Colors.white, size: 40)),
            Positioned(bottom: 15, left: 15, right: 15, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("RECIBO CAPTURADO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10)), IconButton(icon: const Icon(Icons.fullscreen, color: Colors.white), onPressed: () { _showFullImage(_productPhotoUrl!); })])),
          ],
        )
            : const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, size: 45, color: Colors.teal),
            SizedBox(height: 12),
            Text("SUBIR FOTO O RECIBO", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.w900, fontSize: 13)),
            SizedBox(height: 4),
            Text("ML KIT DETECTARÁ LA DIRECCIÓN", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildModernField(TextEditingController controller, String label, IconData icon, Color color, {int lines = 1, bool isPickup = false, bool isDropoff = false}) {
    Color fillColor = Colors.white;
    Color borderColor = Colors.grey[100]!;

    bool isVerified = (isPickup && _isPickupVerified) || (isDropoff && _isDropoffVerified);
    bool isKnown = (isPickup && _validatedPickupLatLng != null) || (isDropoff && _validatedDropoffLatLng != null);

    if (controller.text.isNotEmpty) {
      if (isVerified) {
        fillColor = Colors.green[50]!;
        borderColor = Colors.green[300]!;
      } else if (isKnown) {
        fillColor = Colors.amber[50]!;
        borderColor = Colors.amber[300]!;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: (controller.text.isNotEmpty && isKnown) ? 2 : 1),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 6))],
          ),
          child: TextFormField(
            controller: controller,
            maxLines: lines,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.black),
            decoration: InputDecoration(
              labelText: label.toUpperCase(),
              labelStyle: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1),
              prefixIcon: Icon(icon, color: isVerified ? Colors.green : color, size: 22),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            ),
            validator: (value) { return value == null || value.isEmpty ? "REQUERIDO" : null; },
          ),
        ),
        if (controller.text.isNotEmpty && isKnown)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Text(
              isVerified
                  ? "✓ UBICACIÓN EXACTA VERIFICADA (SISTEMA LAD)"
                  : "⚠ LA DIRECCIÓN NO ES TAN PRECISA, EL DRIVER HARÁ LO POSIBLE POR ENCONTRARLA.",
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isVerified ? Colors.green[700] : Colors.amber[800]
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton(AppLocalizations l10n) {
    final bool hasPayment = _clientModel?.defaultPaymentMethodId != null;

    return Column(
      children: [
        if (!hasPayment)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "DEBES VINCULAR UN MÉTODO DE PAGO EN TU PERFIL PARA SOLICITAR SERVICIOS.",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 10))],
          ),
          child: ElevatedButton(
            onPressed: (_isLoading || !hasPayment) ? null : _handleOrderAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: hasPayment ? Colors.black : Colors.grey[400],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 22),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              elevation: 0,
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.greenAccent)
                : Text(l10n.create_order_btn_send.toUpperCase(), 
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2)),
          ),
        ),
      ],
    );
  }
}
