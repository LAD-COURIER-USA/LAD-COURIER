import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart'; // 🚀 IMPORTACIÓN NECESARIA
import 'package:lad_courier/models/user_model.dart';
import 'package:lad_courier/services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  final CollectionReference _usersRef =
  FirebaseFirestore.instance.collection('users');

  final LocationService _locationService = LocationService();
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1'); // 🛡️ REGIÓN LAD

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

  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _usersRef.doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateMessengerActiveStatus(String uid, bool isActive, BuildContext context) async {
    try {
      final Map<String, dynamic> dataToUpdate = {
        'isMessengerActive': isActive,
      };

      if (isActive) {
        final position = await _locationService.getCurrentLocation(context);
        dataToUpdate['workZoneCenter'] = GeoPoint(position.latitude, position.longitude);
      } else {
        dataToUpdate['workZoneCenter'] = null;
      }

      await _usersRef.doc(uid).set(dataToUpdate, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateAvailableServices(String uid, List<String> services) async {
    try {
      await _usersRef.doc(uid).set({
        'availableServices': services,
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
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
    } catch (e) {
      rethrow;
    }
  }

  Future<void> unlinkMessenger(String clientId, String messengerId) async {
    try {
      await _usersRef.doc(clientId).set({
        'linkedMessengerIds': FieldValue.arrayRemove([messengerId])
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  Stream<int> getReferralsCountStream(String messengerId) {
    return _usersRef
        .where('invitingMessengerId', isEqualTo: messengerId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<String?> getPendingInvitationId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingId = prefs.getString('pending_messenger_invitation');
      if (pendingId != null) {
        await prefs.remove('pending_messenger_invitation');
      }
      return pendingId;
    } catch (e) {
      debugPrint("Error al recuperar invitación pendiente: $e");
      return null;
    }
  }

  /// ✨ ESTRATEGIA LAD DIGITAL SYSTEMS LLC: Procesamiento de Bonos de Reclutamiento
  /// Implementa la lógica de "10 nuevos referidos = Mes Gratis" con candados anti-fraude.
  Future<void> processReferralBonus(String recruiterId, String recruitedId) async {
    final recruiterRef = _usersRef.doc(recruiterId);
    final recruitedRef = _usersRef.doc(recruitedId);
    final now = DateTime.now();
    final currentMonthStr = "${now.year}-${now.month.toString().padLeft(2, '0')}";

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final recruiterDoc = await transaction.get(recruiterRef);
        final recruitedDoc = await transaction.get(recruitedRef);
        
        if (!recruiterDoc.exists || !recruitedDoc.exists) return;

        final recruiterData = recruiterDoc.data() as Map<String, dynamic>;
        final recruitedData = recruitedDoc.data() as Map<String, dynamic>;

        // 🛡️ REGLA DE ORO 1: Un driver solo cuenta UNA VEZ en la historia de LAD.
        if (recruitedData['hasBeenCountedForBonus'] == true) {
          debugPrint("SISTEMA LAD: Driver reclutado ya fue contado anteriormente. No aplica bono.");
          return;
        }

        // 🛡️ REGLA DE ORO 2: Conteo por ventana mensual (1 al 30/31).
        String? lastReferralMonth = recruiterData['currentReferralMonth'];
        int currentCount = recruiterData['monthlyDirectNetworkCount'] ?? 0;
        
        if (lastReferralMonth != currentMonthStr) {
          // Es un mes nuevo para este reclutador, reseteamos contadores
          currentCount = 0;
          debugPrint("SISTEMA LAD: Nuevo mes detectado ($currentMonthStr). Reseteando contadores de bono.");
        }

        int newCount = currentCount + 1;

        // 1. Marcar al reclutado como "Sello de un solo uso"
        transaction.update(recruitedRef, {
          'hasBeenCountedForBonus': true,
          'driverCategory': 'direct_network',
        });

        // 2. Actualizar al reclutador con el nuevo conteo y mes
        Map<String, dynamic> updates = {
          'monthlyDirectNetworkCount': newCount,
          'currentReferralMonth': currentMonthStr,
        };

        // 3. REGLA DE ORO 3: El bono se activa solo con 10 o más (Cero tolerancia a 9).
        if (newCount >= 10) {
          final nextMonth = DateTime(now.year, now.month + 1);
          final bonusMonthStr = "${nextMonth.year}-${nextMonth.month.toString().padLeft(2, '0')}";
          
          updates['lastBonusMonthEarned'] = bonusMonthStr;
          debugPrint("SISTEMA LAD: ¡Meta alcanzada! Bono de mes gratis otorgado para $bonusMonthStr");
        }

        transaction.update(recruiterRef, updates);
      });
    } catch (e) {
      debugPrint("Error en processReferralBonus: $e");
    }
  }
}
