import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class StripeModeService {
  static final StripeModeService _instance = StripeModeService._internal();
  factory StripeModeService() => _instance;
  StripeModeService._internal();

  String _currentMode = 'test';
  String get currentMode => _currentMode;

  Future<void> initialize() async {
    try {
      final config = await FirebaseFirestore.instance
          .collection('admin_settings')
          .doc('stripe')
          .get();
      
      if (config.exists) {
        _currentMode = config.data()?['stripe_mode'] ?? 'test';
      }
      debugPrint("🛡️ SISTEMA LAD: StripeModeService inicializado en modo: $_currentMode");
    } catch (e) {
      debugPrint("⚠️ SISTEMA LAD: Error inicializando StripeModeService: $e");
    }
  }

  bool isLive() => _currentMode == 'live';
  bool isTest() => _currentMode == 'test';
}
