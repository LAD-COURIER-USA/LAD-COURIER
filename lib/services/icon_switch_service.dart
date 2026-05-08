import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// =========================================================================
// IconSwitchService: El Interruptor Maestro de Iconos
// =========================================================================
// Esta unidad de élite tiene una única misión: comunicarse con el sistema
// operativo Android para activar y desactivar los alias de la aplicación,
// cambiando así el icono visible para el usuario.
// =========================================================================
class IconSwitchService {
  // El canal de comunicación con la plataforma nativa.
  // Debe coincidir exactamente con el nombre del canal en MainActivity.kt.
  static const _platform = MethodChannel('com.elmensajero.app/launcher');

  /// Activa el icono correspondiente al rol seleccionado y desactiva los demás.
  ///
  /// [targetRole] debe ser 'CLIENT' o 'MESSENGER'.
  static Future<void> switchLauncherIcon({required String targetRole}) async {
    try {
      debugPrint("IconSwitchService: Orden recibida. Cambiando icono a '$targetRole'.");
      
      // Enviamos la orden a la plataforma nativa a través del canal.
      await _platform.invokeMethod('switchIcon', {
        'role': targetRole,
      });

      debugPrint("IconSwitchService: Orden de cambio de icono ejecutada con éxito.");
    } on PlatformException catch (e) {
      // Si la plataforma nativa devuelve un error, lo registramos.
      debugPrint("IconSwitchService: Error al cambiar el icono. Causa: ${e.message}");
    }
  }
}
