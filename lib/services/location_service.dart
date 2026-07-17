import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
// ✅ AÑADIDO PARA kIsWeb
import 'package:lad_courier/l10n/app_localizations.dart';

class LocationService {
  /// Determina la posición actual del dispositivo con protocolo de seguridad LAD.
  Future<Position> getCurrentLocation(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Comprueba si los servicios de ubicación están habilitados.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error(l10n.service_location_disabled);
    }

    // 2. Comprueba y solicita los permisos.
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error(l10n.service_location_denied);
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(l10n.service_location_denied_forever);
    }

    // 🛡️ REFUERZO V19.2: Timeout Mandatorio para evitar "Forever Spinning"
    // En Web, el navegador puede tardar mucho en resolver si el usuario ignora el prompt.
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: AppleSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).timeout(
        const Duration(seconds: 12),
        onTimeout: () => throw 'TIMEOUT_GPS: El GPS no respondió a tiempo. Intenta de nuevo.',
      );
    } catch (e) {
      debugPrint("⚠️ SISTEMA LAD: Error obteniendo ubicación: $e");
      // Fallback: Intentar obtener la última posición conocida si la actual falla
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return lastKnown;
      }
      rethrow;
    }
  }
}
