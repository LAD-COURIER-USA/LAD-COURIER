import 'dart:async';
import 'package:flutter/foundation.dart'; // Equipo de comunicaciones seguro.
import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeepLinkService {
  DeepLinkService._privateConstructor();
  static final DeepLinkService instance = DeepLinkService._privateConstructor();

  final _appLinks = AppLinks();

  static const String _inviterIdKey = 'invitingMessengerId';

  Future<void> init() async {
    try {
      // === ¡MODERNIZADO! ===
      // Se corrige la llamada a la nueva API: getInitialLink()
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('DeepLinkService: Enlace inicial capturado: $initialUri');
        _processLink(initialUri);
      }

      _appLinks.uriLinkStream.listen((Uri uri) {
        debugPrint('DeepLinkService: Enlace de stream capturado: $uri');
        _processLink(uri);
      }, onError: (err) {
        debugPrint('DeepLinkService Error: No se pudo recibir el enlace del stream: $err');
      });

    } catch (e) {
      debugPrint('DeepLinkService Error: Fallo al inicializar el servicio de enlaces: $e');
    }
  }

  Future<void> _processLink(Uri uri) async {
    if (uri.host == 'ladcourier.com' && uri.pathSegments.length == 2 && uri.pathSegments[0] == 'invite') {
      final inviterId = uri.pathSegments[1];
      debugPrint('¡ID de referente capturado! ID: $inviterId');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_inviterIdKey, inviterId);
      debugPrint('ID de referente guardado en la memoria del dispositivo.');
    }
  }

  static Future<String?> getStoredInviterId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_inviterIdKey);
  }
}