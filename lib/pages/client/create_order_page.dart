// 🛡️ SISTEMA LAD - VERSIÓN PURIFICADA V14.7
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // 🛡️ PARA kIsWeb y defaultTargetPlatform
import 'package:flutter/services.dart'; 
import 'package:geolocator/geolocator.dart';
import 'package:lad_courier/services/geocoding_service.dart';
import 'package:lad_courier/services/order_service.dart';
import 'package:lad_courier/services/storage_service.dart';
import 'package:lad_courier/services/user_service.dart';
import 'package:lad_courier/services/ocr_service.dart';
import 'package:lad_courier/services/geodata_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lad_courier/l10n/app_localizations.dart';
import 'package:lad_courier/services/stripe_mode_service.dart'; // 🧬 IMPORTACIÓN DOBLE ADN
import 'package:lad_courier/pages/client/driver_selection_page.dart';
import 'package:lad_courier/models/user_model.dart';
import 'package:lad_courier/models/order_model.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart' as custom_tabs;
import 'package:photo_manager/photo_manager.dart';
import 'package:image_picker/image_picker.dart'; // ✅ AÑADIDO PARA XFile
import 'package:permission_handler/permission_handler.dart';

class CreateOrderPage extends StatefulWidget {
  final Map<String, dynamic>? selectedMessenger;
  final bool autoStartOCR;
  final OrderModel? reassignOrder;
  final Map<String, dynamic>? bridgeData;
  final XFile? initialImage; // 🛡️ NUEVO: Imagen inyectada desde el Dashboard

  const CreateOrderPage({
    super.key,
    this.selectedMessenger,
    this.autoStartOCR = false,
    this.reassignOrder,
    this.bridgeData,
    this.initialImage,
  });

  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  static const _screenshotChannel = MethodChannel('com.laddigital.smartshopper/screenshot');

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

  final String _detectedCountryCode = "US";
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    
    // 🛡️ REFUERZO V19.12: La escucha de screenshots ahora es GLOBAL en main.dart
    // para permitir el BINGO automático incluso con la App cerrada.
    // Aquí solo mantenemos el vigilante si fuera necesario, pero la navegación
    // la gestiona el búnker central.

    _prepareBingoVigilante();

    _currentMessenger = widget.selectedMessenger;
    _showDriverSelection = widget.selectedMessenger == null;

    if (widget.autoStartOCR) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoProcessLastImage();
      });
    }

    // 🛡️ REFUERZO V19.9: Si viene una imagen inyectada (Share o Notification), la procesamos ya
    if (widget.initialImage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _processImageWorkflow(widget.initialImage);
      });
    }

    if (widget.bridgeData != null) {
      final data = widget.bridgeData!;
      _pickupController.text = "${data['name'] ?? ''} - ${data['address'] ?? ''}";
      _validatedStoreAddress = _pickupController.text;
      
      if (data['lat'] != null && data['lon'] != null) {
        _validatedPickupLatLng = GeoPoint(
          double.parse(data['lat'].toString()), 
          double.parse(data['lon'].toString())
        );
        _isPickupVerified = true;
      }
      
      String desc = "SMARTSHOPPER: ";
      if (data['details'] != null) desc += "${data['details']} ";
      desc += "LOCAL ID: ${data['storeId'] ?? 'N/A'}";
      _descriptionController.text = desc;
    }

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
  }

  void _onPickupChanged() {
    if (_validatedStoreAddress != null && _pickupController.text != _validatedStoreAddress) {
      setState(() { 
        _validatedPickupLatLng = null; 
        _validatedStoreAddress = null; 
        _isPickupVerified = false; 
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
      });
    }
    _triggerDynamicFiltering();
  }

  void _onDescriptionChanged() {
    if (_descriptionController.text.length == 1) _triggerDynamicFiltering(force: true);
  }

  Future<void> _useCurrentLocation(bool isPickup) async {
    final Position? position = await _ensureLocationPermission();
    if (position == null || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      
      GeocodingResponse? res = await _userService.findPrivateAddressByCoords(
        uid, position.latitude, position.longitude
      );

      if (res == null) {
        res = await _geocodingService.getDetailsFromCoords(
          position.latitude, position.longitude
        );
        if (res != null) {
          _userService.savePrivateAddress(uid, res);
        }
      }

      if (res != null && mounted) {
        final confirmedRes = res;
        setState(() {
          if (isPickup) {
            _pickupController.text = confirmedRes.fullAddress.toUpperCase();
            _validatedPickupLatLng = confirmedRes.latLng;
            _validatedStoreAddress = _pickupController.text;
            _isPickupVerified = true; 
          } else {
            _dropoffController.text = confirmedRes.fullAddress.toUpperCase();
            _validatedDropoffLatLng = confirmedRes.latLng;
            _validatedDropoffAddress = _dropoffController.text;
            _isDropoffVerified = true;
          }
        });
      }
    } catch (e) {
      debugPrint("Error obteniendo ubicación: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _prepareBingoVigilante() async {
    await Permission.notification.request();
    try {
      await _screenshotChannel.invokeMethod('startScreenshotWatcher');
    } catch (e) {
      debugPrint("SISTEMA LAD ERROR: $e");
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
    _debounce?.cancel();
    _debounce = Timer(Duration(milliseconds: force ? 100 : 2500), () async {
      if (!mounted) return;
      
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
            setState(() { 
              _isPickupVerified = true; 
              _validatedPickupLatLng = GeoPoint(store['gps']['lat'], store['gps']['lon']); 
              _validatedStoreAddress = pickupText; 
            });
          }
        }
        
        if (!foundInGeodata) {
          final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
          GeocodingResponse? res = await _userService.findPrivateAddress(uid, pickupText);
          res ??= await _geocodingService.getFullDetails(pickupText);
          if (res != null) {
            final confirmedRes = res;
            _userService.savePrivateAddress(uid, confirmedRes);
            if (mounted) {
              setState(() { 
                _isPickupVerified = false; 
                _validatedPickupLatLng = confirmedRes.latLng; 
                _validatedStoreAddress = pickupText; 
              });
            }
          }
        }
      }

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
            setState(() { 
              _isDropoffVerified = true; 
              _validatedDropoffLatLng = GeoPoint(store['gps']['lat'], store['gps']['lon']); 
              _validatedDropoffAddress = dropoffText; 
            });
          }
        }
        
        if (!foundInGeodata) {
          final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
          GeocodingResponse? res = await _userService.findPrivateAddress(uid, dropoffText);
          res ??= await _geocodingService.getFullDetails(dropoffText);
          if (res != null) {
            final confirmedRes = res;
            _userService.savePrivateAddress(uid, confirmedRes);
            if (mounted) {
              setState(() { 
                _isDropoffVerified = false; 
                _validatedDropoffLatLng = confirmedRes.latLng;
                _validatedDropoffAddress = dropoffText; 
              });
            }
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
    FirebaseFirestore.instance.collection('users')
      .where('role', whereIn: ['MESSENGER', 'DRIVER']) // 🛡️ UNIFICACIÓN DE ROLES LAD
      .where('isMessengerActive', isEqualTo: true)
      .limit(50)
      .snapshots().listen((snapshot) { 
        if (mounted) setState(() => _globalMessengers = snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList()); 
      });
  }

  String _normalize(String text) => text.toLowerCase().trim()
    .replaceAll(RegExp(r'[áàäâ]'), 'a')
    .replaceAll(RegExp(r'[éèëê]'), 'e')
    .replaceAll(RegExp(r'[íìïî]'), 'i')
    .replaceAll(RegExp(r'[óòöô]'), 'o')
    .replaceAll(RegExp(r'[úùüû]'), 'u')
    .replaceAll('ñ', 'n');

  bool _isServiceMatch(List<dynamic> messengerServices, String selectedType) {
    if (messengerServices.isEmpty) return true;
    final services = messengerServices.map((s) => _normalize(s.toString())).toList();
    final selected = _normalize(selectedType);
    if (services.any((s) => s == selected || s.contains(selected) || selected.contains(s))) return true;
    if (selected.contains('courier')) return services.any((s) => s.contains('paquet') || s.contains('courier') || s.contains('envio'));
    if (selected.contains('shop')) return services.any((s) => s.contains('compra') || s.contains('shop') || s.contains('mandado'));
    if (selected.contains('logist')) return services.any((s) => s.contains('logist') || s.contains('carga') || s.contains('truck'));
    return false;
  }

  Future<Position?> _ensureLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("El GPS está desactivado.")));
      return null;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;
    return await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
  }

  Future<void> _autoProcessLastImage() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth) {
      if (mounted) _pickProductPhoto();
      return;
    }
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(onlyAll: true, filterOption: FilterOptionGroup(orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)]));
    if (paths.isEmpty) {
      if (mounted) _pickProductPhoto();
      return;
    }
    final List<AssetEntity> entities = await paths[0].getAssetListRange(start: 0, end: 1);
    if (entities.isEmpty) {
      if (mounted) _pickProductPhoto();
      return;
    }
    final dynamic file = await paths[0].getAssetListRange(start: 0, end: 1);
    if (file == null || file.isEmpty) {
      if (mounted) _pickProductPhoto();
      return;
    }
    // Nota: photo_manager devuelve AssetEntity, no File directamente.
    final actualFile = await (file[0] as dynamic).file;
    if (actualFile == null) {
      if (mounted) _pickProductPhoto();
      return;
    }
    _processImageWorkflow(actualFile);
  }

  Future<void> _pickProductPhoto() async {
    final l10n = AppLocalizations.of(context)!;
    if (!mounted) return;

    if (kIsWeb) {
      // 🛡️ REFUERZO V2026 WEB: Abrimos el picker directo para asegurar el gesto de usuario en iPad/Safari
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera, 
        imageQuality: 50,
        maxWidth: 1024,
      ).catchError((_) => picker.pickImage(source: ImageSource.gallery, imageQuality: 50));

      if (image != null && mounted) {
        debugPrint("SISTEMA LAD: Imagen capturada en iPad/Web. Iniciando workflow...");
        _processImageWorkflow(image);
        _ensureLocationPermission(); 
      }
    } else {
      // 📱 ANDROID NATIVO: Selector profesional Cámara/Galería
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(l10n.bingo_dialog_title, style: const TextStyle(fontWeight: FontWeight.w900)),
          content: Text(l10n.bingo_dialog_body),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.pop(context, ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: Text(l10n.common_camera, style: const TextStyle(fontWeight: FontWeight.w900))
            ),
            TextButton.icon(
              onPressed: () => Navigator.pop(context, ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: Text(l10n.common_gallery, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.deepPurple))
            ),
          ],
        ),
      );

      if (source != null && mounted) {
        // 🛡️ REFUERZO: Esperamos a que el diálogo de selección se cierre completamente
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;

        try {
          final ImagePicker picker = ImagePicker();
          final XFile? image = await picker.pickImage(source: source, imageQuality: 50);
          if (image != null && mounted) {
            debugPrint("SISTEMA LAD: Foto capturada. Iniciando OCR...");
            _processImageWorkflow(image);
          }
        } catch (e) {
          debugPrint("❌ SISTEMA LAD: Error en picker local: $e");
        }
      }
    }
  }

  Future<void> _processImageWorkflow(dynamic file) async {
    if (!mounted) return;
    
    // 🛡️ REFUERZO: Cerramos cualquier diálogo abierto antes de empezar
    if (Navigator.canPop(context)) {
      debugPrint("SISTEMA LAD: Limpiando diálogos previos...");
    }
    
    setState(() => _isUploadingPhoto = true);

    try {
      debugPrint("SISTEMA LAD: Iniciando workflow de imagen. File: $file");
      
      // 1. SUBIDA A STORAGE
      String? uploadedUrl = await _storageService.uploadFile('order_photos', "ticket_${DateTime.now().millisecondsSinceEpoch}", file);
      
      if (uploadedUrl == null) {
        throw "No se pudo subir la imagen al búnker. Revisa tu conexión.";
      }
      
      // 2. OCR UNIVERSAL
      String? localPath;
      if (!kIsWeb) {
        if (file is XFile) {
          localPath = file.path;
        } else if (file is String) {
          localPath = file;
        }
      }
      
      debugPrint("SISTEMA LAD: Lanzando OCR. localPath: $localPath, url: $uploadedUrl");

      final ocrResult = await _ocrService.analyzeReceiptUniversal(
        localPath: localPath,
        remoteUrl: uploadedUrl
      ).timeout(const Duration(seconds: 20), onTimeout: () => throw "El análisis del ticket está tardando demasiado.");
      
      // 3. UBICACIÓN PARA REFINAMIENTO
      final Position? position = await _ensureLocationPermission().timeout(const Duration(seconds: 5), onTimeout: () => null);
      String? gpsZip, gpsCity, gpsState;
      if (position != null) {
        try {
          final geo = await _geocodingService.getDetailsFromCoords(position.latitude, position.longitude);
          gpsZip = geo?.zipCode; gpsCity = geo?.city; gpsState = geo?.state;
        } catch (_) {}
      }

      final refined = _refineOcrAddress(ocrResult, gpsZip, gpsCity, gpsState);
      final String? finalFullAddr = refined['address'];
      Map<String, dynamic>? validatedStore;

      final String targetZip = ocrResult.zipCode ?? gpsZip ?? "33030";
      if (ocrResult.streetNumber != null) {
         validatedStore = await _geodataService.findStoreByDna(zip: targetZip, streetNumber: ocrResult.streetNumber!, countryCode: "US", stateCode: ocrResult.stateCode ?? gpsState);
         validatedStore ??= await _geodataService.findStoreByTriangulation(brand: ocrResult.storeName ?? 'ESTABLECIMIENTO', city: ocrResult.cityName ?? gpsCity, streetNumber: ocrResult.streetNumber!, stateCode: ocrResult.stateCode ?? gpsState ?? 'FL', userLat: position?.latitude, userLon: position?.longitude);
      }

      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
          _productPhotoUrl = uploadedUrl;
        });
        
        // 🚀 LANZAMIENTO SEGURO DE DIÁLOGO (Gesto de usuario)
        _showOcrSuggestions(ocrResult.copyWith(fullAddress: validatedStore != null ? null : finalFullAddr), validatedStore);
      }
    } catch (e) {
      debugPrint("❌ SISTEMA LAD ERROR en Workflow: $e");
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("AVISO BINGO"),
            content: Text(e.toString()),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("ENTENDIDO"))],
          )
        );
      }
    }
  }

  void _showOcrSuggestions(OCRResult result, Map<String, dynamic>? validatedStore) {
    if (!mounted) return;
    
    // 🛡️ EXTRACCIÓN SEGURA DE DATOS (Prevención de Crash V2026.2)
    String? storeName;
    String? address;
    
    try {
      if (validatedStore != null) {
        storeName = validatedStore['name']?.toString();
        final addrData = validatedStore['address'];
        if (addrData != null) {
          address = addrData is Map ? addrData['full']?.toString() : addrData.toString();
        }
      }
      
      // Fallback a los datos del OCR si el búnker no encontró nada mejor
      storeName ??= result.storeName;
      address ??= result.fullAddress;
    } catch (e) {
      debugPrint("❌ Error extrayendo datos para sugerencia: $e");
    }

    final bool isVerified = validatedStore != null;
    
    debugPrint("SISTEMA LAD: Abriendo diálogo OCR. Store: $storeName, Address: $address");

    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(dialogContext)!;
        return AlertDialog(
          scrollable: true, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: Row(
            children: [
              Icon(isVerified ? Icons.verified : Icons.auto_awesome, color: isVerified ? Colors.green : Colors.blue, size: 28), 
              const SizedBox(width: 12), 
              Expanded(child: Text(isVerified ? l10n.ocr_dialog_exact_title : l10n.ocr_dialog_auto_title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)))
            ]
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min, 
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              if (storeName != null && storeName.isNotEmpty) ...[
                Text(l10n.ocr_label_store, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey)), 
                const SizedBox(height: 4), 
                Text(storeName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)), 
                const SizedBox(height: 12)
              ],
              if (address != null && address.isNotEmpty) ...[
                Text(l10n.ocr_label_address, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey)), 
                const SizedBox(height: 4), 
                Text(address.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), 
                const SizedBox(height: 12)
              ],
              if (result.orderNumber != null) ...[
                Text(l10n.ocr_label_order, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey)), 
                const SizedBox(height: 4), 
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), 
                  decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green[200]!)), 
                  child: Text(result.orderNumber!, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.green))
                )
              ]
            ]
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext), 
              child: Text(l10n.common_cancel, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900))
            ),
            ElevatedButton(
              onPressed: () { 
                if (mounted) {
                  setState(() { 
                    if (address != null) { 
                      _pickupController.text = address; 
                      if (validatedStore != null && validatedStore['gps'] != null) { 
                        final gps = validatedStore['gps'];
                        _isPickupVerified = true; 
                        // Casting seguro a double para evitar crashes en tipos numéricos de Firestore
                        _validatedPickupLatLng = GeoPoint(
                          (gps['lat'] as num).toDouble(), 
                          (gps['lon'] as num).toDouble()
                        ); 
                      } else { 
                        _isPickupVerified = false; 
                        _triggerDynamicFiltering(); 
                      } 
                    } 
                    String extra = result.orderNumber != null ? "ORDEN #${result.orderNumber}. " : "";
                    if (storeName != null) {
                      String cleanStore = storeName.toUpperCase();
                      if (!_descriptionController.text.contains(cleanStore)) {
                        _descriptionController.text = "${extra}RECOGER EN $cleanStore. ${_descriptionController.text}";
                      }
                    }
                  }); 
                }
                Navigator.pop(dialogContext); 
              }, 
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black, 
                foregroundColor: Colors.white, 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ), 
              child: Text(l10n.ocr_btn_autofill, style: const TextStyle(fontWeight: FontWeight.w900))
            )
          ],
        );
      }
    );
  }

  void _handleOrderAction() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      final pickup = _validatedPickupLatLng ?? await _geocodingService.getLatLng(_pickupController.text);
      final dropoff = _validatedDropoffLatLng ?? await _geocodingService.getLatLng(_dropoffController.text);
      if (!mounted) return;
      if (pickup == null || dropoff == null) throw Exception("Direcciones no localizadas.");
      if (_currentMessenger == null) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => DriverSelectionPage(pickupLatLng: pickup, dropoffLatLng: dropoff, pickupAddress: _pickupController.text, dropoffAddress: _dropoffController.text, serviceType: _selectedService, packageDetails: _descriptionController.text, clientName: _clientModel?.displayName ?? 'Cliente', productPhotoUrl: _productPhotoUrl, countryCode: _detectedCountryCode)));
      } else {
        await _createOrderDirect(pickup, dropoff);
      }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  Future<void> _createOrderDirect(GeoPoint p, GeoPoint d) async {
    final user = FirebaseAuth.instance.currentUser;
    if (_currentMessenger == null || user == null) return;
    
    final bool isLive = StripeModeService().isLive();
    String finalClientName = _clientModel?.displayName ?? user.displayName ?? user.email!.split('@').first.toUpperCase();
    
    await _orderService.createOrder(
      clientId: user.uid, 
      clientName: finalClientName, 
      clientEmail: user.email, 
      clientPhotoUrl: user.photoURL, 
      assignedMessengerId: _currentMessenger!['id'], 
      messengerName: _currentMessenger!['name'], 
      messengerPhotoUrl: _currentMessenger!['photoURL'], 
      serviceType: _selectedService, 
      pickupAddress: _pickupController.text, 
      pickupLatLng: p, 
      dropoffAddress: _dropoffController.text, 
      dropoffLatLng: d, 
      packageDetails: _descriptionController.text, 
      productPhotoUrl: _productPhotoUrl, 
      countryCode: _detectedCountryCode, 
      stripeCustomerId: _clientModel?.getActiveCustomerId(isLive), 
      paymentMethodId: _clientModel?.getActivePaymentMethodId(isLive)
    );

    if (widget.reassignOrder != null) await FirebaseFirestore.instance.collection('orders').doc(widget.reassignOrder!.id).delete();
    if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🚀 ¡ORDEN ENVIADA EXITOSAMENTE!"), backgroundColor: Colors.green)); }
  }

  void _openSmartShopperResults(String categoryId, String categoryName) async {
    final Position? position = await _ensureLocationPermission();
    if (position == null || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    String? userChoice = await showDialog<String>(context: context, builder: (context) {
      final controller = TextEditingController();
      return AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)), title: Text(l10n.ss_dialog_title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), content: TextField(controller: controller, autofocus: true, decoration: InputDecoration(hintText: l10n.ss_dialog_hint, border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(15))))), actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.common_cancel)), ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white), child: Text(l10n.ss_btn_search))]);
    });
    if (userChoice == null) return;
    setState(() => _isLoading = true);
    try {
      final geo = await _geocodingService.getDetailsFromCoords(position.latitude, position.longitude);
      String smartQuery = userChoice.isEmpty ? "Tiendas cerca de mi en ${geo?.city ?? 'area'}, US" : "$userChoice cerca de mi en ${geo?.city ?? 'area'}, US";
      final Uri url = Uri.parse("https://www.google.com/search?q=${Uri.encodeComponent(smartQuery)}");
      if (!mounted) return;
      setState(() => _isLoading = false);
      await custom_tabs.launchUrl(url, prefersDeepLink: false, customTabsOptions: custom_tabs.CustomTabsOptions(colorSchemes: custom_tabs.CustomTabsColorSchemes.defaults(toolbarColor: Colors.black), showTitle: true, urlBarHidingEnabled: true));
    } catch (e) { if (mounted) { setState(() => _isLoading = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"))); } }
  }

  void _showFullImage(String url) {
    showDialog(context: context, builder: (context) => Dialog(backgroundColor: Colors.black, child: InteractiveViewer(child: Image.network(url))));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(title: Text(l10n.create_order_title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black, letterSpacing: 1.5)), centerTitle: true, backgroundColor: Colors.white, elevation: 0.5, foregroundColor: Colors.black),
      body: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 24), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 20),
        _buildSectionTitle(l10n.create_order_service_type, Icons.layers_outlined, Colors.indigo[900]!),
        _buildServiceSelector(l10n),
        if (_selectedService == 'shopping') ...[const SizedBox(height: 20), _buildSmartShopperGrid(l10n)],
        const SizedBox(height: 30),
        _buildSectionTitle(l10n.create_order_add_photo, Icons.camera_alt_outlined, Colors.teal[900]!),
        _buildPhotoPicker(l10n),
        const SizedBox(height: 30),
        _buildSectionTitle(l10n.create_order_pickup_label, Icons.location_on_outlined, Colors.deepPurple[900]!),
          _buildModernField(_pickupController, l10n.create_order_pickup_origin, Icons.storefront, Colors.deepPurple[900]!, isPickup: true, lines: 2),
        const SizedBox(height: 30),
        _buildSectionTitle(l10n.create_order_dropoff_label, Icons.flag_outlined, Colors.orange[900]!),
        _buildModernField(_dropoffController, l10n.create_order_dropoff_dest, Icons.home_outlined, Colors.orange[900]!, isDropoff: true, lines: 2),
        const SizedBox(height: 30),
        _buildSectionTitle(l10n.create_order_description_label, Icons.assignment_outlined, Colors.blue[900]!),
        _buildModernField(_descriptionController, l10n.create_order_details_label, Icons.edit_note, Colors.blue[900]!, lines: 3),
        if (_showDriverSelection) ...[const SizedBox(height: 30), _buildSectionTitle(l10n.create_order_section_messenger, Icons.person_search_outlined, Colors.black), _buildDriverSwitcher(l10n)],
        const SizedBox(height: 40),
        _buildActionButton(l10n),
        const SizedBox(height: 50),
      ]))),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 15, left: 4), 
    child: Row(
      children: [
        Icon(icon, size: 18, color: color), 
        const SizedBox(width: 8), 
        Expanded(
          child: Text(
            title.toUpperCase(), 
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: color, letterSpacing: 1.1),
            overflow: TextOverflow.ellipsis,
          ),
        )
      ],
    ),
  );

  Widget _buildSmartShopperGrid(AppLocalizations l10n) => Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.15), width: 2), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 8))]), child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Row(children: [Icon(Icons.auto_awesome, color: Colors.deepPurple, size: 26), SizedBox(width: 12), Expanded(child: Text("MAGIA SMART SHOPPER", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.black, letterSpacing: 1.2)))]),
    const SizedBox(height: 18),
    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blueGrey[50], borderRadius: BorderRadius.circular(15)), child: const Text("🛒 Haz tu compra online (Pickup). Al finalizar, toma una CAPTURA DE PANTALLA de tu ticket.\n\n✨ LAD debería avisarte arriba. Si el aviso no sale, solo regresa aquí y toca el botón de abajo.", style: TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.bold, height: 1.4))),
    const SizedBox(height: 20),
    SizedBox(width: double.infinity, height: 60, child: ElevatedButton.icon(onPressed: () => _openSmartShopperResults("UNIVERSAL", "Cualquier cosa"), icon: const Icon(Icons.search, color: Colors.white), label: const Text("IR A BUSCAR Y COMPRAR", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)), style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple[800], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 4))),
    const SizedBox(height: 12),
    SizedBox(width: double.infinity, height: 50, child: OutlinedButton.icon(onPressed: () => _autoProcessLastImage(), icon: const Icon(Icons.wallpaper, color: Colors.deepPurple), label: const Text("YA TENGO MI TICKET", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.deepPurple)), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.deepPurple, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))))),
  ]));

  Widget _buildServiceSelector(AppLocalizations l10n) {
    final options = { 'courier': l10n.driver_service_courier, 'shopping': "SmartShopper - Compras Online", 'logistics': l10n.driver_service_logistics };
    return Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[200]!)), child: Column(children: options.entries.map((e) {
      bool isSel = _selectedService == e.key;
      return GestureDetector(onTap: () { setState(() => _selectedService = e.key); }, child: AnimatedContainer(duration: const Duration(milliseconds: 250), margin: const EdgeInsets.symmetric(vertical: 4), padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16), decoration: BoxDecoration(color: isSel ? Colors.black : Colors.white, borderRadius: BorderRadius.circular(15)), child: Row(children: [Icon(e.key == 'courier' ? Icons.local_post_office_outlined : (e.key == 'shopping' ? Icons.shopping_bag_outlined : Icons.local_shipping_outlined), color: isSel ? Colors.greenAccent : Colors.black54, size: 22), const SizedBox(width: 15), Expanded(child: Text(e.value.toUpperCase(), style: TextStyle(color: isSel ? Colors.white : Colors.black, fontWeight: FontWeight.w900, fontSize: 12))), if (isSel) const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20)])));
    }).toList()));
  }

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

  Widget _buildPhotoPicker(AppLocalizations l10n) => GestureDetector(
    onTap: _isUploadingPhoto ? null : _pickProductPhoto,
    child: Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey[200]!, width: 2),
      ),
      child: _isUploadingPhoto
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _productPhotoUrl != null
              ? Stack(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(23),
                    child: Image.network(_productPhotoUrl!, width: double.infinity, height: 180, fit: BoxFit.cover),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(23)),
                      color: Colors.black26,
                    ),
                  ),
                  const Center(child: Icon(Icons.sync, color: Colors.white, size: 40)),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: IconButton(
                      icon: const Icon(Icons.fullscreen, color: Colors.white),
                      onPressed: () => _showFullImage(_productPhotoUrl!),
                    ),
                  ),
                ])
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_a_photo, size: 45, color: Colors.teal),
                    const SizedBox(height: 12),
                    Text(
                      l10n.create_order_add_photo.toUpperCase(),
                      style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                  ],
                ),
    ),
  );

  Widget _buildModernField(TextEditingController controller, String label, IconData icon, Color color, {int lines = 1, bool isPickup = false, bool isDropoff = false}) {
    final l10n = AppLocalizations.of(context)!;
    bool isVer = (isPickup && _isPickupVerified) || (isDropoff && _isDropoffVerified);
    bool isKnown = (isPickup && _validatedPickupLatLng != null) || (isDropoff && _validatedDropoffLatLng != null);
    
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        decoration: BoxDecoration(
          color: isVer ? Colors.green[50] : (isKnown ? Colors.amber[50] : Colors.white), 
          borderRadius: BorderRadius.circular(18), 
          border: Border.all(color: isVer ? Colors.green[700]! : (isKnown ? Colors.amber[700]! : Colors.grey[400]!), width: isKnown ? 2 : 1),
        ),
        child: TextFormField(
          controller: controller, 
          maxLines: lines, 
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black), 
          decoration: InputDecoration(
            labelText: label.toUpperCase(), 
            labelStyle: TextStyle(color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w900, fontSize: 11),
            prefixIcon: Icon(icon, color: isVer ? Colors.green[900] : color, size: 24), 
            suffixIcon: (isPickup || isDropoff) 
                ? IconButton(
                    icon: Icon(Icons.my_location, color: isVer ? Colors.green : Colors.grey), 
                    onPressed: () => _useCurrentLocation(isPickup),
                    tooltip: l10n.create_order_gps_tooltip,
                  )
                : null,
            border: InputBorder.none, 
            contentPadding: const EdgeInsets.all(20)
          )
        )
      ),
      if (controller.text.isNotEmpty && isKnown) Padding(padding: const EdgeInsets.only(top: 8, left: 12), child: Text(isVer ? l10n.create_order_verified_msg : l10n.create_order_unverified_msg, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isVer ? Colors.green[900] : Colors.amber[900]))),
    ]);
  }

  Widget _buildActionButton(AppLocalizations l10n) {
    // 🛡️ PASE VIP: El inspector no necesita tarjeta vinculada
    final bool isLive = StripeModeService().isLive();
    bool hasP = (_clientModel?.isVipTester ?? false) || _clientModel?.getActivePaymentMethodId(isLive) != null;
    return Column(children: [
      if (!hasP) Padding(padding: const EdgeInsets.only(bottom: 20), child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.red[200]!)), child: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.red), SizedBox(width: 10), Expanded(child: Text("DEBES VINCULAR UN MÉTODO DE PAGO EN TU PERFIL PARA SOLICITAR SERVICIOS.", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)))]))),
      SizedBox(width: double.infinity, height: 65, child: ElevatedButton(onPressed: (_isLoading || !hasP) ? null : _handleOrderAction, style: ElevatedButton.styleFrom(backgroundColor: hasP ? Colors.black : Colors.grey[400], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))), child: _isLoading ? const CircularProgressIndicator(color: Colors.greenAccent) : Text(l10n.create_order_btn_send.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white)))),
    ]);
  }

  List<UserModel> get _filteredMessengers {
    final all = [..._linkedMessengers, ..._globalMessengers];
    final unique = <String, UserModel>{};
    for (var m in all) { unique[m.uid] = m; }
    final filtered = unique.values.where((m) {
      if (widget.reassignOrder != null && m.uid == widget.reassignOrder!.assignedMessengerId) return false;
      if (!m.isMessengerActive || !_isServiceMatch(m.availableServices, _selectedService) || m.workZoneCenter == null) return false;
      final plan = (m.subscriptionType ?? 'lite').toLowerCase();
      // 🛡️ BLINDAJE DE ORTOGRAFÍA LAD: Roberto Macías tiene 'standart' con T
      final bool isPremium = plan == 'pro' || plan == 'standard' || plan == 'standart';
      double pLimit = isPremium ? 25.0 : 5.0;
      double dLimit = plan == 'pro' ? 120.0 : (isPremium ? 25.0 : 5.0);
      if (_validatedPickupLatLng != null) { if (Geolocator.distanceBetween(m.workZoneCenter!.latitude, m.workZoneCenter!.longitude, _validatedPickupLatLng!.latitude, _validatedPickupLatLng!.longitude) / 1609.34 > pLimit) return false; }
      if (_validatedDropoffLatLng != null) { if (Geolocator.distanceBetween(m.workZoneCenter!.latitude, m.workZoneCenter!.longitude, _validatedDropoffLatLng!.latitude, _validatedDropoffLatLng!.longitude) / 1609.34 > dLimit) return false; }
      return true;
    }).toList();
    if (_validatedPickupLatLng != null) filtered.sort((a, b) => Geolocator.distanceBetween(a.workZoneCenter!.latitude, a.workZoneCenter!.longitude, _validatedPickupLatLng!.latitude, _validatedPickupLatLng!.longitude).compareTo(Geolocator.distanceBetween(b.workZoneCenter!.latitude, b.workZoneCenter!.longitude, _validatedPickupLatLng!.latitude, _validatedPickupLatLng!.longitude)));
    return filtered.length > 5 ? filtered.sublist(0, 5) : filtered;
  }

  Map<String, dynamic> _refineOcrAddress(OCRResult ocr, String? gZip, String? gCity, String? gState) {
    String? finalFullAddr = ocr.fullAddress;
    // 🛡️ REGLA DE SOBERANÍA LAD V14.3: Si el ticket tiene un ZIP de 5 dígitos, ignoramos el GPS por completo.
    final bool hasZipOnTicket = ocr.zipCode != null || (finalFullAddr != null && RegExp(r'\b\d{5}\b').hasMatch(finalFullAddr));

    if (hasZipOnTicket && finalFullAddr != null) {
       debugPrint("LAD IA: Ticket Soberano detectado. Blindando dirección del GPS.");
       return {'address': finalFullAddr.toUpperCase(), 'store': null};
    }

    // 🩹 REGLA DE PRÓTESIS POSTAL: Solo si el ticket NO tiene ZIP, usamos las muletas del GPS.
    if (finalFullAddr != null) {
       String patch = "";
       if (gCity != null && !finalFullAddr.toUpperCase().contains(gCity.toUpperCase())) patch += ", $gCity";
       if (gState != null && !finalFullAddr.toUpperCase().contains(gState.toUpperCase())) patch += ", $gState";
       if (gZip != null && !finalFullAddr.contains(gZip)) patch += " $gZip";
       finalFullAddr = "$finalFullAddr$patch".toUpperCase();
    }
    return {'address': finalFullAddr, 'store': null};
  }
}
