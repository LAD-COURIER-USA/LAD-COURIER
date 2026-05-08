import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:lad_courier/l10n/app_localizations.dart';

class LocationService {
  /// Determina la posición actual del dispositivo.
  ///
  /// Cuando los servicios de ubicación no están habilitados o los permisos
  /// son denegados, la función `Future` devolverá un error.
  Future<Position> getCurrentLocation(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Comprueba si los servicios de ubicación están habilitados.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Los servicios de ubicación no están habilitados. No se puede continuar.
      return Future.error(l10n.service_location_disabled);
    }

    // 2. Comprueba y solicita los permisos.
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Los permisos fueron denegados.
        return Future.error(l10n.service_location_denied);
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Los permisos fueron denegados permanentemente.
      return Future.error(l10n.service_location_denied_forever);
    }

    // 3. Si los permisos están concedidos, obtenemos la ubicación.
    // Se usa alta precisión para máxima efectividad en campo.
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
    );
  }
}