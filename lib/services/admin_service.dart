import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ AÑADIDO PARA RESET DE CLAVE
import 'package:flutter/foundation.dart'; // ✅ AÑADIDO PARA debugPrint
import '../models/user_model.dart';
import '../models/order_model.dart';

class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🛡️ HILO 1: Obtener Drivers Pendientes de Verificación
  Stream<List<UserModel>> getPendingVerifications() {
    return _db.collection('users')
        .where('verificationStatus', isEqualTo: 'APROBADO_DOC')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }

  // 🛡️ HILO 2: Sistema de Reclamaciones y Sugerencias (El Buzón del Búnker)
  Stream<QuerySnapshot> getDisputesAndSuggestions() {
    return _db.collection('support_tickets')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // 📊 HILO 3: Inteligencia de Marketing (Agregados para Gráficos)
  Future<Map<String, double>> getServicePopularity() async {
    final query = await _db.collection('orders').limit(1000).get();
    Map<String, double> stats = {
      'Courier': 0,
      'Logistics': 0,
      'SmartShopper': 0,
    };

    for (var doc in query.docs) {
      final type = doc.data()['type'] ?? 'Courier';
      if (stats.containsKey(type)) {
        stats[type] = stats[type]! + 1;
      }
    }
    return stats;
  }

  // 🚀 ACCIÓN: Aprobar Verificación de Driver
  Future<void> approveDriver(String uid) async {
    await _db.collection('users').doc(uid).update({
      'verificationStatus': 'APROBADO',
      'isIdentityVerified': true,
      'approvedAt': FieldValue.serverTimestamp(),
    });
  }

  // 🛡️ ACCIÓN: Suspender Microfranquicia (Temporal o Indefinida)
  Future<void> suspendDriver({
    required String uid, 
    required String reason, 
    DateTime? until,
  }) async {
    await _db.collection('users').doc(uid).update({
      'driverFranchiseStatus': 'SUSPENDED',
      'suspensionMessage': reason,
      'suspendedUntil': until != null ? Timestamp.fromDate(until) : null,
      'role': 'CLIENT', // 🚀 Lo bajamos a Cliente de inmediato
    });
  }

  // 🛡️ ACCIÓN: Revocación Permanente con Blindaje de Identidad (TRIDENTE)
  Future<void> revokeDriverFranchise(UserModel driver, String reason) async {
    // 1. Marcar al usuario como REVOCADO
    await _db.collection('users').doc(driver.uid).update({
      'driverFranchiseStatus': 'REVOKED',
      'suspensionMessage': reason,
      'role': 'CLIENT',
      'verificationStatus': 'REVOCADO',
    });

    // 2. Registrar en la LISTA NEGRA (El Tridente)
    final Map<String, dynamic> blacklistData = {
      'revokedAt': FieldValue.serverTimestamp(),
      'reason': reason,
      'originalUid': driver.uid,
    };

    if (driver.stripeAccountId != null) blacklistData['stripeId'] = driver.stripeAccountId;
    if (driver.stripeAccountIdLive != null) blacklistData['stripeIdLive'] = driver.stripeAccountIdLive;
    if (driver.phoneNumber != null) blacklistData['phoneHash'] = driver.phoneNumber.hashCode.toString();
    
    // El deviceId se guarda si lo capturamos en el login
    // blacklistData['deviceId'] = driver.deviceId; 

    await _db.collection('blacklist_identities').doc(driver.uid).set(blacklistData);
    debugPrint("SISTEMA LAD: Identidad del driver $driver.uid enviada al abismo de la lista negra.");
  }

  // 🛡️ ACCIÓN: Restaurar Privilegios
  Future<void> restoreDriverFranchise(String uid) async {
    await _db.collection('users').doc(uid).update({
      'driverFranchiseStatus': 'ACTIVE',
      'suspensionMessage': null,
      'suspendedUntil': null,
    });
  }

  // 🛰️ HILO 4: Drivers Online para el Mapa
  Stream<List<UserModel>> getOnlineDrivers() {
    return _db.collection('users')
        .where('isMessengerActive', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }

  // 🛰️ HILO 5: Misiones en curso (Activas, En Camino, Recogidas)
  Stream<List<OrderModel>> getActiveMissions() {
    return _db.collection('orders')
        .where('status', whereIn: ['active', 'enRouteToPickup', 'pickedUp', 'enRouteToDelivery'])
        .snapshots()
        .map((snap) => snap.docs.map((doc) => OrderModel.fromFirestore(doc)).toList());
  }

  // 📸 HILO 6: Archivo de Evidencias (Órdenes Completadas)
  Stream<List<OrderModel>> getCompletedOrdersHistory() {
    return _db.collection('orders')
        .where('status', isEqualTo: 'completed')
        .orderBy('completionTimestamp', descending: true)
        .limit(50) // Últimas 50 entregas para no saturar
        .snapshots()
        .map((snap) => snap.docs.map((doc) => OrderModel.fromFirestore(doc)).toList());
  }

  // 🚀 ACCIÓN: Marcar Evidencia para Conservación Permanente
  Future<void> flagOrderForInvestigation(String orderId, bool investigationActive) async {
    await _db.collection('orders').doc(orderId).update({
      'underInvestigation': investigationActive,
      'investigationDate': investigationActive ? FieldValue.serverTimestamp() : null,
    });
  }

  // 🚀 ACCIÓN: Resolver Discrepancia
  Future<void> resolveTicket(String ticketId, String resolution) async {
    await _db.collection('support_tickets').doc(ticketId).update({
      'status': 'RESOLVED',
      'resolution': resolution,
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }

  // 🛡️ ACCIÓN: Reset de Seguridad (Expulsar piratas)
  Future<void> resetUserSecurity(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      debugPrint("SISTEMA LAD: Email de reset enviado a $email para expulsar posibles intrusos.");
    } catch (e) {
      throw "No se pudo enviar el correo de recuperación: $e";
    }
  }

  // 🛡️ ACCIÓN: Eliminación de Respeto (Sin lista negra)
  Future<void> softDeleteUser(String uid) async {
    // 1. Borramos el documento de Firestore para que no pueda operar
    await _db.collection('users').doc(uid).delete();
    
    // Nota: La eliminación de Firebase Auth requiere una Cloud Function 
    // que ya tenemos programada ('deleteUserAccount')
  }
}
