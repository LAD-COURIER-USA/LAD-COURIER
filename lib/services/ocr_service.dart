import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_entity_extraction/google_mlkit_entity_extraction.dart';

class OCRResult {
  final String? storeName;
  final String? fullAddress;
  final String? streetNumber;
  final String? zipCode;
  final String? cityName;
  final String? streetName;
  final String? countryCode;
  final String? stateCode;
  final bool usedFLAI;

  OCRResult({
    this.storeName,
    this.fullAddress,
    this.streetNumber,
    this.zipCode,
    this.cityName,
    this.streetName,
    this.countryCode = "US",
    this.stateCode,
    this.usedFLAI = false,
  });

  OCRResult copyWith({
    String? storeName,
    String? fullAddress,
    String? streetNumber,
    String? zipCode,
    String? cityName,
    String? streetName,
    String? countryCode,
    String? stateCode,
    bool? usedFLAI,
  }) {
    return OCRResult(
      storeName: storeName ?? this.storeName,
      fullAddress: fullAddress ?? this.fullAddress,
      streetNumber: streetNumber ?? this.streetNumber,
      zipCode: zipCode ?? this.zipCode,
      cityName: cityName ?? this.cityName,
      streetName: streetName ?? this.streetName,
      countryCode: countryCode ?? this.countryCode,
      stateCode: stateCode ?? this.stateCode,
      usedFLAI: usedFLAI ?? this.usedFLAI,
    );
  }
}

class OCRService {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final _entityExtractor = EntityExtractor(language: EntityExtractorLanguage.english);

  // Determina si el hardware aguanta "IA Pesada"
  Future<bool> isHighEndDevice() async {
    if (kIsWeb) return false;
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        // S24 Ultra y similares (SDK 30+ y mucha RAM usualmente)
        return androidInfo.version.sdkInt >= 30;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        return !iosInfo.utsname.machine.contains('iPhone10') &&
            !iosInfo.utsname.machine.contains('iPhone9');
      }
    } catch (e) { debugPrint("Error hardware: $e"); }
    return false;
  }

  Future<OCRResult> analyzeReceipt(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      final String fullText = recognizedText.text.toUpperCase();
      final List<String> lines = recognizedText.text.split('\n').map((e) => e.trim().toUpperCase()).toList();

      // --- MOTOR DE RAZONAMIENTO "ADN POSTAL" ---
      String country = _detectCountryByADN(fullText);
      String? zip = _extractZipByCountry(fullText, country);
      String? state = _detectStateByCountry(fullText, country);
      String? city = _detectCity(fullText, zip);
      String? streetNum = _extractStreetNumber(fullText, zip);
      String? storeName = _detectStoreImproved(lines.take(12).toList());

      bool canUseFLAI = await isHighEndDevice();
      String? fullAddr;

      if (canUseFLAI) {
        // FLAI: Refinamiento por Entidades (IA de Google)
        final List<EntityAnnotation> annotations = await _entityExtractor.annotateText(fullText);
        for (var a in annotations) {
          if (a.entities.any((e) => e.type == EntityType.address)) {
            fullAddr = a.text.toUpperCase().replaceAll('\n', ' ').trim();
            break;
          }
        }
      }

      // 🛡️ FILTRO GLOBAL ANTI-BASURA LAD (V11): Limpiamos la dirección ANTES y DESPUÉS de reconstruir
      final List<String> uiJunk = ['RASTREADOR', 'ORDEN RECIBIDA', 'DETALLES', 'ESTADO', 'TRACKER', 'CHECKOUT', 'HISTORY', 'CERRAR', 'VOLVER'];
      
      // Si la dirección de la IA de Google tiene basura, la anulamos
      if (fullAddr != null && uiJunk.any((word) => fullAddr!.contains(word))) {
        fullAddr = null;
      }

      // Reconstrucción soberana si FLAI falló o no existe
      fullAddr ??= _reconstructAddress(lines, country, zip, streetNum);

      // Verificación final: si la dirección reconstruida todavía tiene basura, la matamos para forzar GPS
      if (fullAddr != null && uiJunk.any((word) => fullAddr!.contains(word))) {
        debugPrint("LAD IA: Dirección rechazada por contener basura de UI: $fullAddr");
        fullAddr = null;
      }

      return OCRResult(
        storeName: storeName,
        fullAddress: fullAddr,
        streetNumber: streetNum,
        zipCode: zip,
        cityName: city,
        stateCode: state,
        countryCode: country,
        usedFLAI: canUseFLAI,
      );
    } catch (e) {
      debugPrint('Error FLAI Service: $e');
      return OCRResult();
    }
  }

  String _detectCountryByADN(String text) {
    if (text.contains('CEP') || text.contains('BRASIL') || text.contains('BAIRRO')) return 'BR';
    if (text.contains('COLONIA') || text.contains('COL.') || text.contains('MEXICO')) return 'MX';
    if (RegExp(r'[A-Z]\d[A-Z]\s\d[A-Z]\d').hasMatch(text)) return 'CA';
    return 'US';
  }

  String? _extractZipByCountry(String text, String country) {
    switch (country) {
      case 'BR': return RegExp(r'\d{5}-\d{3}').firstMatch(text)?.group(0);
      case 'CA': return RegExp(r'[A-Z]\d[A-Z]\s?\d[A-Z]\d').firstMatch(text)?.group(0);
      case 'MX':
      case 'US': 
        // 🛡️ MEJORA LAD: Buscamos el ZIP que esté al final de una línea o cerca de un estado
        final zipMatch = RegExp(r'\b(FL|GA|NY|TX|CA|NC|NV|SC|WA|IL)\s+(\d{5})\b').firstMatch(text);
        if (zipMatch != null) return zipMatch.group(2);
        
        // Si no hay estado cerca, buscamos 5 dígitos que NO estén al inicio de una línea
        // (Esto evita que el número 26601 se robe el lugar del ZipCode)
        final loneZip = RegExp(r'(?<!^)\b\d{5}\b', multiLine: true).firstMatch(text);
        return loneZip?.group(0);
      default: return null;
    }
  }

  String? _detectStateByCountry(String text, String country) {
    if (country == 'US') {
      final match = RegExp(r'\b(FL|GA|NY|TX|CA|NC|NV|SC|WA|IL)\b').firstMatch(text);
      return match?.group(1);
    }
    if (country == 'BR') {
      final match = RegExp(r'\b(SP|RJ|MG|PR|RS|SC|BA)\b').firstMatch(text);
      return match?.group(1);
    }
    return null;
  }

  String? _detectCity(String text, String? zip) {
    // 🛡️ Buscamos patrones comunes: "City, ST" o "City ST 12345" o "City FL"
    final cityMatch = RegExp(r'\b([A-Z\s]{3,20})(?:,|\s+)(FL|GA|NY|TX|CA|NC|NV|SC|WA|IL|MD)\b').firstMatch(text);
    if (cityMatch != null) return cityMatch.group(1)!.trim();
    
    // Fallback: Si tenemos ZIP, la ciudad suele estar justo antes en la misma línea o la anterior
    if (zip != null) {
      final lines = text.split('\n');
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].contains(zip)) {
          // Intentar en la misma línea antes del ZIP
          final parts = lines[i].split(zip)[0].split(',');
          if (parts.isNotEmpty) {
            String c = parts.last.trim();
            if (c.length > 3 && !RegExp(r'\d').hasMatch(c)) return c;
          }
          
          // Intentar la línea anterior completa
          if (i > 0) {
            String prev = lines[i-1].trim();
            if (prev.length > 3 && prev.length < 20 && !RegExp(r'\d').hasMatch(prev)) return prev;
          }
        }
      }
    }
    return null;
  }

  String? _extractStreetNumber(String text, String? zip) {
    final lines = text.split('\n');
    
    // 🛡️ FILTRO MAESTRO LAD V9: Extracción Quirúrgica de Números
    // 1. Buscamos el Store ID (Formato # seguido de números)
    final storeIdRegex = RegExp(r'#\s*(\d{3,6})\b');
    final storeMatch = storeIdRegex.firstMatch(text);
    if (storeMatch != null) {
      debugPrint("LAD IA: Detectado Store ID (#${storeMatch.group(1)})");
      return storeMatch.group(1);
    }

    // 2. Buscamos números de calle real (acompañados de palabras clave)
    final streetKeywords = RegExp(r'\b(ST|AVE|HWY|RD|BLVD|LN|DR|WAY|DIXIE|MAIN|ROAD|PKWY|NE|NW|SE|SW|STREET|AVENUE|BOULEVARD)\b');
    for (var line in lines) {
      final cleanLine = line.trim().toUpperCase();
      // Solo aceptamos números puros de 1 a 6 dígitos
      final match = RegExp(r'\b(\d{1,6})\b.*' + streetKeywords.pattern).firstMatch(cleanLine);
      if (match != null) {
        String n = match.group(1)!;
        if (n != zip) return n;
      }
    }

    // 3. Fallback: Cualquier número puro de 3 a 6 dígitos (ignora alfanuméricos como 11B08)
    for (var line in lines) {
      final cleanLine = line.trim().toUpperCase();
      final tokens = cleanLine.split(RegExp(r'\s+'));
      for (var token in tokens) {
        if (RegExp(r'^\d{3,6}$').hasMatch(token)) {
          if (token != zip) return token;
        }
      }
    }
    
    return null;
  }

  String? _detectStoreImproved(List<String> lines) {
    final giants = ['WALMART', 'PUBLIX', 'TARGET', 'COSTCO', 'CVS', '7-ELEVEN', 'STARBUCKS', 'MCDONALD', 'LITTLE CAESAR', 'BURGER KING', 'BK #', 'DOMINO', 'CHILI', 'WENDY'];
    
    // 🚫 LISTA NEGRA: Palabras de la interfaz de usuario de las apps que debemos ignorar
    final uiBlacklist = ['RASTREADOR', 'PEDIDO', 'DETALLES', 'CERRAR', 'VOLVER', 'AYUDA', 'TRACKER', 'ORDER', 'CHECKOUT', 'HISTORY'];

    for (var line in lines) {
      final cleanLine = line.toUpperCase();
      
      // 1. Buscar Marcas Gigantes
      for (var g in giants) {
        if (cleanLine.contains(g)) {
          if (g == 'BK #') return 'BURGER KING';
          return cleanLine.contains('LITTLE') ? 'LITTLE CAESARS' : g;
        }
      }
      
      // 2. Si es una palabra de la Blacklist, la ignoramos
      if (uiBlacklist.any((b) => cleanLine.contains(b))) continue;

      // 3. Si la línea es el nombre del establecimiento (sin números, longitud media)
      if (cleanLine.length > 3 && cleanLine.length < 30 && !RegExp(r'\d').hasMatch(cleanLine)) {
        return cleanLine;
      }
    }
    return 'ESTABLECIMIENTO'; // Fallback genérico para triangulación
  }

  String? _reconstructAddress(List<String> lines, String country, String? zip, String? streetNum) {
    // 🛡️ ESTRATEGIA CORPORATIVA LAD (V6): Reconstrucción Blindada
    
    final List<String> uiBlacklist = ['RASTREADOR', 'ORDEN RECIBIDA', 'DETALLES', 'ESTADO', 'TRACKER', 'CHECKOUT', 'HISTORY', 'CERRAR', 'VOLVER'];

    // 1. Si tenemos ZIP, reconstruimos el entorno (Estrategia Proactiva)
    if (zip != null) {
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].contains(zip)) {
          String p1 = (i > 0) ? lines[i-1] : "";
          if (uiBlacklist.any((junk) => p1.contains(junk))) p1 = "";
          
          if (p1.length < 15 && !RegExp(r'\d').hasMatch(p1) && i > 1) {
             String p2 = lines[i-2];
             if (!uiBlacklist.any((junk) => p2.contains(junk))) p1 = "$p2 $p1";
          }
          String full = "$p1 ${lines[i]}";
          if (RegExp(r'\d').hasMatch(full)) {
            return _cleanExtraSpaces(full.replaceAll(RegExp(r'#\s*\d+'), ''));
          }
        }
      }
    }

    // 2. Búsqueda por Patrones de Calle (Ej: 123 NE 8TH ST)
    final streetKeywords = RegExp(r'\b(ST|AVE|HWY|RD|BLVD|LN|DR|WAY|DIXIE|MAIN|ROAD|PKWY|NE|NW|SE|SW|STREET|AVENUE)\b');
    for (var line in lines) {
      if (streetKeywords.hasMatch(line) && RegExp(r'\b\d{1,6}\b').hasMatch(line)) {
        if (!uiBlacklist.any((junk) => line.contains(junk))) {
          if (line.length > 8 && line.length < 60) {
            return _cleanExtraSpaces(line.replaceAll(RegExp(r'#\s*\d+'), ''));
          }
        }
      }
    }

    return null;
  }

  String _cleanExtraSpaces(String text) => text.replaceAll(RegExp(r'\s+'), ' ').trim();

  void dispose() {
    _textRecognizer.close();
    _entityExtractor.close();
  }
}
