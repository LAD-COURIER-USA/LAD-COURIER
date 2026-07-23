import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // ✅ AÑADIDO PARA kIsWeb
import 'package:cloud_functions/cloud_functions.dart';
import 'package:local_auth/local_auth.dart'; 
import 'package:lad_courier/models/user_model.dart';
import 'package:lad_courier/services/location_service.dart';
import 'package:lad_courier/services/geocoding_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  CollectionReference get _usersRef => FirebaseFirestore.instance.collection('users');

  final LocationService _locationService = LocationService();
  FirebaseFunctions get _functions => FirebaseFunctions.instanceFor(region: 'us-central1');
  
  // 🛡️ REFUERZO V19.0: LocalAuthentication NUNCA se instancia en Web
  LocalAuthentication? _authInstance;
  LocalAuthentication? get _auth => kIsWeb ? null : (_authInstance ??= LocalAuthentication());

  /// 🔐 VALIDACIÓN DE IDENTIDAD BIOMÉTRICA (ADAPTABLE)
  Future<bool> authenticateBiometric({required String reason}) async {
    // 🛡️ PROTOCOLO SOBERANO: En Web (iPad/PC) saltamos biometría local.
    if (kIsWeb || _auth == null) {
      debugPrint("SISTEMA LAD: Saltando biometría local en Web (Protocolo V19.0).");
      return true; 
    }

    try {
      final bool canAuthenticateWithBiometrics = await _auth!.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth!.isDeviceSupported();

      if (!canAuthenticate) return true; 

      return await _auth!.authenticate(
          localizedReason: reason.isEmpty ? "Acceso Seguro: Confirma tu identidad" : reason,
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
            useErrorDialogs: true,
          )
      );
    } catch (e) {
      debugPrint("SISTEMA LAD ERROR Biometría: $e");
      return false;
    }
  }

  /// 🔄 SINCRONIZACIÓN MANUAL CON STRIPE
  Future<String> syncStripeStatus(String uid) async {
    try {
      final result = await _functions.httpsCallable('syncStripeStatus').call({'uid': uid});
      return result.data['status'] ?? 'pending';
    } catch (e) {
      debugPrint("Error en syncStripeStatus: $e");
      return 'error';
    }
  }

  /// 🛡️ VERIFICACIÓN BIOMÉTRICA (AMAZON REKOGNITION)
  Future<Map<String, dynamic>> verifyBiometricIdentity({
    required String selfieUrl,
    required String masterPhotoUrl,
  }) async {
    try {
      final result = await _functions.httpsCallable('verifyBiometricIdentity').call({
        'selfieUrl': selfieUrl,
        'masterPhotoUrl': masterPhotoUrl,
      });
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint("Error en verifyBiometricIdentity: $e");
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 🛡️ BÚNKER PERSONAL: Guarda una dirección privada para ahorrar API de Google
  Future<void> savePrivateAddress(String uid, GeocodingResponse res) async {
    try {
      final normalized = res.fullAddress.toUpperCase().trim();
      final docId = normalized.hashCode.toString();

      await _usersRef.doc(uid).collection('private_geodata').doc(docId).set({
        'fullAddress': normalized,
        'lat': res.latLng.latitude,
        'lng': res.latLng.longitude,
        'zipCode': res.zipCode,
        'city': res.city?.toUpperCase(),
        'state': res.state?.toUpperCase(),
        'streetNumber': res.streetNumber,
        'lastUsed': FieldValue.serverTimestamp(),
        'expiresAt': DateTime.now().add(const Duration(hours: 72)).millisecondsSinceEpoch, 
      });
      debugPrint("LAD BÚNKER: Dirección privada blindada.");
    } catch (e) {
      debugPrint("LAD ERROR Búnker: $e");
    }
  }

  /// 🛡️ BÚNKER PERSONAL: Busca si la dirección ya fue pagada a Google anteriormente
  Future<GeocodingResponse?> findPrivateAddress(String uid, String inputAddress) async {
    try {
      // 🧠 NORMALIZACIÓN AGRESIVA LAD: Eliminamos puntos, comas y espacios extra
      String clean(String s) => s.toUpperCase().replaceAll(RegExp(r'[,.\s]'), '');
      final normalizedInput = clean(inputAddress);
      
      final now = DateTime.now().millisecondsSinceEpoch;

      final snapshot = await _usersRef.doc(uid)
          .collection('private_geodata')
          .where('expiresAt', isGreaterThan: now) 
          .get();

      // Buscamos el match en memoria para ser más flexibles con los caracteres especiales
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final storedAddr = clean(data['fullAddress'] ?? '');
        
        if (storedAddr == normalizedInput) {
          await doc.reference.update({
            'lastUsed': FieldValue.serverTimestamp(),
            'expiresAt': DateTime.now().add(const Duration(hours: 72)).millisecondsSinceEpoch,
          });

          debugPrint("LAD BÚNKER: Dirección recuperada (Costo \$0)");
          return GeocodingResponse(
            latLng: GeoPoint(data['lat'], data['lng']),
            fullAddress: data['fullAddress'],
            zipCode: data['zipCode'],
            city: data['city'],
            state: data['state'],
            streetNumber: data['streetNumber'],
          );
        }
      }
    } catch (e) {
      debugPrint("LAD ERROR Búnker Search: $e");
    }
    return null;
  }

  Future<GeocodingResponse?> findPrivateAddressByCoords(String uid, double lat, double lng) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final snapshot = await _usersRef.doc(uid)
          .collection('private_geodata')
          .where('lat', isGreaterThan: lat - 0.0001)
          .where('lat', isLessThan: lat + 0.0001)
          .where('expiresAt', isGreaterThan: now)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if ((data['lng'] - lng).abs() < 0.0001) {
          await doc.reference.update({
            'lastUsed': FieldValue.serverTimestamp(),
            'expiresAt': DateTime.now().add(const Duration(hours: 72)).millisecondsSinceEpoch,
          });

          return GeocodingResponse(
            latLng: GeoPoint(data['lat'], data['lng']),
            fullAddress: data['fullAddress'],
            zipCode: data['zipCode'],
            city: data['city'],
            state: data['state'],
            streetNumber: data['streetNumber'],
          );
        }
      }
    } catch (e) {
      debugPrint("LAD ERROR Búnker GPS Search: $e");
    }
    return null;
  }

  /// 🛡️ VIGILANTE LAD: Comprueba si una identidad está en la lista negra
  Future<bool> isBlacklisted({String? stripeId, String? phone}) async {
    try {
      // Comprobar por Stripe ID
      if (stripeId != null) {
        final queryStripe = await FirebaseFirestore.instance.collection('blacklist_identities')
            .where('stripeId', isEqualTo: stripeId).limit(1).get();
        if (queryStripe.docs.isNotEmpty) return true;

        final queryStripeLive = await FirebaseFirestore.instance.collection('blacklist_identities')
            .where('stripeIdLive', isEqualTo: stripeId).limit(1).get();
        if (queryStripeLive.docs.isNotEmpty) return true;
      }

      // Comprobar por Hash de Teléfono
      if (phone != null) {
        final phoneHash = phone.hashCode.toString();
        final queryPhone = await FirebaseFirestore.instance.collection('blacklist_identities')
            .where('phoneHash', isEqualTo: phoneHash).limit(1).get();
        if (queryPhone.docs.isNotEmpty) return true;
      }

      return false;
    } catch (e) {
      debugPrint("SISTEMA LAD ERROR Vigilante: $e");
      return false;
    }
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _usersRef.doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) { rethrow; }
  }

  Future<void> updateMessengerActiveStatus(String uid, bool isActive, BuildContext context) async {
    try {
      final Map<String, dynamic> dataToUpdate = {
        'isMessengerActive': isActive,
      };

      if (isActive) {
        final position = await _locationService.getCurrentLocation(context);
        dataToUpdate['workZoneCenter'] = GeoPoint(position.latitude, position.longitude);
        dataToUpdate['lastActiveAt'] = FieldValue.serverTimestamp();
      } else {
        dataToUpdate['workZoneCenter'] = null;
      }

      await _usersRef.doc(uid).set(dataToUpdate, SetOptions(merge: true));
    } catch (e) { rethrow; }
  }

  Future<void> updateAvailableServices(String uid, List<String> services) async {
    try {
      await _usersRef.doc(uid).set({
        'availableServices': services,
      }, SetOptions(merge: true));
    } catch (e) { rethrow; }
  }

  Stream<UserModel?> getUserStream(String uid) {
    return _usersRef.doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return UserModel.fromFirestore(snapshot);
      }
      return null;
    });
  }

  Stream<List<UserModel>> getLinkedMessengersStream(String clientId) {
    return _usersRef.doc(clientId).snapshots().asyncExpand((clientDoc) {
      if (!clientDoc.exists) return Stream.value([]);
      final data = clientDoc.data() as Map<String, dynamic>;
      final List<String> messengerIds = List<String>.from(data['linkedMessengerIds'] ?? []);
      if (messengerIds.isEmpty) return Stream.value([]);
      return _usersRef
          .where(FieldPath.documentId, whereIn: messengerIds)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
    });
  }

  Future<void> linkMessengerToClient(String clientId, String messengerId) async {
    try {
      await _usersRef.doc(clientId).set({
        'linkedMessengerIds': FieldValue.arrayUnion([messengerId])
      }, SetOptions(merge: true));
    } catch (e) { rethrow; }
  }

  Future<void> unlinkMessenger(String clientId, String messengerId) async {
    try {
      await _usersRef.doc(clientId).set({
        'linkedMessengerIds': FieldValue.arrayRemove([messengerId])
      }, SetOptions(merge: true));
    } catch (e) { rethrow; }
  }

  Future<void> updateActiveRadioChannel(String userId, String? channelId, String? senderName) async {
    try {
      await _usersRef.doc(userId).set({
        'lastIncomingRadioChannel': channelId,
        'lastIncomingRadioName': senderName,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("SISTEMA LAD ERROR Radio Channel: $e");
    }
  }

  Future<String?> getPendingInvitationId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingId = prefs.getString('pending_messenger_invitation');
      if (pendingId != null) {
        await prefs.remove('pending_messenger_invitation');
      }
      return pendingId;
    } catch (e) { return null; }
  }
}
