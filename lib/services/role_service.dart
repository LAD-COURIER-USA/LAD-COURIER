import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// 🛡️ REFUERZO V19.0: RoleService Purificado para Web
class RoleService {
  RoleService._privateConstructor();
  static final RoleService instance = RoleService._privateConstructor();

  // El canal solo se crea en nativo para evitar llamadas de Platform en web
  static const _platform = MethodChannel('com.example.lad_courier/launcher');

  final _roleController = StreamController<String>.broadcast();
  Stream<String> get roleStream => _roleController.stream;

  void initialize() {
    if (kIsWeb) {
      debugPrint("RoleService: Modo Web activado. Sincronización nativa omitida.");
      return;
    }
    
    _platform.setMethodCallHandler(_handleNativeMethodCall);
    checkRole();
  }

  Future<dynamic> _handleNativeMethodCall(MethodCall call) async {
    if (kIsWeb) return;
    if (call.method == 'roleChanged') {
      checkRole();
    }
  }

  Future<void> checkRole() async {
    if (kIsWeb) return;
    
    String newRole;
    try {
      final String? result = await _platform.invokeMethod('getLauncherRole');
      newRole = result?.toUpperCase() ?? 'UNKNOWN';
    } catch (e) {
      newRole = "ERROR";
    }
    _roleController.add(newRole);
  }

  void dispose() {
    _roleController.close();
  }
}
