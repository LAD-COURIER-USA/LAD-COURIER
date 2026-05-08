import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// Esta clase es una unidad de inteligencia aislada.
// Su única misión: hablar con la capa nativa.
class RoleService {
  // Patrón Singleton: Asegura que solo exista UNA instancia de este servicio.
  RoleService._privateConstructor();
  static final RoleService instance = RoleService._privateConstructor();

  // El canal de comunicación corregido para el proyecto.
  static const _platform = MethodChannel('com.example.lad_courier/launcher');

  // Un "transmisor de radio" que emitirá el rol cada vez que cambie.
  final _roleController = StreamController<String>.broadcast();

  // El stream público al que la UI puede suscribirse.
  Stream<String> get roleStream => _roleController.stream;

  // Método de inicialización: establece la comunicación.
  void initialize() {
    _platform.setMethodCallHandler(_handleNativeMethodCall);
    // Realiza la primera verificación del rol al arrancar.
    checkRole();
  }

  // Maneja las señales que vienen DESDE Kotlin HACIA Flutter.
  Future<dynamic> _handleNativeMethodCall(MethodCall call) async {
    if (call.method == 'roleChanged') {
      debugPrint("RoleService: Señal de cambio de rol recibida desde Nativo. Re-verificando...");
      checkRole();
    }
  }

  // Interroga a la capa nativa y transmite el resultado.
  Future<void> checkRole() async {
    String newRole;
    try {
      final String? result = await _platform.invokeMethod('getLauncherRole');
      newRole = result?.toUpperCase() ?? 'UNKNOWN';
    } on PlatformException catch (e) {
      newRole = "Error: ${e.message}";
    }
    // Emite el nuevo rol a todos los que estén escuchando.
    _roleController.add(newRole);
  }

  // Cierra el transmisor cuando ya no se necesita.
  void dispose() {
    _roleController.close();
  }
}