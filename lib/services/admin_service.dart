import 'package:cloud_firestore/cloud_firestore.dart';
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
}
