import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BillingService {
  static final BillingService _instance = BillingService._internal();
  factory BillingService() => _instance;
  BillingService._internal();

  /// Fee fijo por cada orden exitosa (Recogida y Entregada)
  static const double serviceFee = 0.50;

  void initialize() => debugPrint("✅ SISTEMA LAD: BillingService (Fee por Orden) Inicializado.");
  void dispose() => debugPrint("SISTEMA LAD: BillingService Recursos liberados.");

  /// Registra el cobro de la comisión tras una entrega exitosa
  Future<void> processOrderFee(String orderId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      // Aquí iría la lógica para cargar los $0.50 al balance del driver o cobrarlo vía Stripe
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'serviceFeeCharged': serviceFee,
        'feeStatus': 'pending_collection', // O 'paid' si se descuenta de una wallet interna
      });
      debugPrint("SISTEMA LAD: Fee de $serviceFee registrado para la orden $orderId");
    } catch (e) {
      debugPrint("SISTEMA LAD ERROR: No se pudo registrar el fee: $e");
    }
  }
}