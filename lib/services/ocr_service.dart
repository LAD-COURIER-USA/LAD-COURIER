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
  final String? orderNumber; // 🍔 NUEVO: Para tickets de comida
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
    this.orderNumber,
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
    String? orderNumber,
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
      orderNumber: orderNumber ?? this.orderNumber,
      usedFLAI: usedFLAI ?? this.usedFLAI,
    );
  }
}

class OCRService {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final _entityExtractor = EntityExtractor(language: EntityExtractorLanguage.english);

  // Determina si el hardware aguanta "IA Pesada"
  Future<bool> isHighEndDevice() async {
    // 🛡️ REFUERZO V19.0: En Web no hay IA local pesada.
    if (kIsWeb) return false;
    
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      // Usamos el enum de foundation para máxima seguridad
      if (defaultTargetPlatform == TargetPlatform.android) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        return androidInfo.version.sdkInt >= 30;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
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
      
      // 🛡️ FILTRO RADICAL LAD: Eliminamos basura de status bar y UI antes de procesar
      final String rawFullText = recognizedText.text.toUpperCase();
      final String fullText = rawFullText
          .replaceAll(RegExp(r'\b\d{1,2}:\d{2}\b'), '') // Borrar la hora (12:53)
          .replaceAll(RegExp(r'\b[45]G\b'), '')          // Borrar 4G/5G
          .replaceAll(RegExp(r'\bLL\s+\d+\b'), '')      // Borrar ruido de señal (LL 82)
          .trim();

      final List<String> lines = fullText.split('\n').map((e) => e.trim()).toList();

      // --- MOTOR DE RAZONAMIENTO "ADN POSTAL" ---
      String country = _detectCountryByADN(fullText);
      String? zip = _extractZipByCountry(fullText, country);
      String? state = _detectStateByCountry(fullText, country);
      String? city = _detectCity(fullText, zip);
      String? streetNum = _extractStreetNumber(fullText, zip);
      String? orderNum = _extractOrderNumber(lines);
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

      // 🛡️ FILTRO GLOBAL ANTI-BASURA LAD (V12): Limpiamos la dirección ANTES y DESPUÉS de reconstruir
      final List<String> uiJunk = [
        'RASTREADOR', 'ORDEN RECIBIDA', 'DETALLES', 'ESTADO', 'TRACKER', 'CHECKOUT', 'HISTORY', 
        'CERRAR', 'VOLVER', 'ESTÁS EN', 'ESTAS EN', 'TU ORDEN', 'ORDEN PREPARADA', 'ORDEN LISTA'
      ];
      
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
        orderNumber: orderNum,
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
        // 🛡️ MEJORA LAD: Solo aceptamos ZIP Codes que no sean números de calle
        final zipMatch = RegExp(r'\b(FL|GA|NY|TX|CA|NC|NV|SC|WA|IL|MD)\s+(\d{5})\b').firstMatch(text);
        if (zipMatch != null) return zipMatch.group(2);
        
        // Si no hay estado cerca, buscamos 5 dígitos al final de una línea o aislados
        final loneZip = RegExp(r'\b\d{5}\b$').firstMatch(text);
        if (loneZip != null) {
           // 🛡️ VALIDACIÓN DE ADN GEOGRÁFICO: Si el número empieza por algo distinto a 3 (en FL), 
           // probablemente no es un ZIP, es un Street Number. Devolvemos null para forzar GPS.
           if (loneZip.group(0)!.startsWith('2') || loneZip.group(0)!.startsWith('1')) {
              return null; 
           }
           return loneZip.group(0);
        }
        return null;
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
    if (cityMatch != null) {
      String city = cityMatch.group(1)!.trim();
      // Eliminar palabras de UI que puedan haberse colado
      final uiJunk = ['ESTÁS EN', 'ESTAS EN', 'VOLVER', 'CERRAR'];
      for (var junk in uiJunk) { city = city.replaceAll(junk, '').trim(); }
      return city.length > 2 ? city : null;
    }
    
    // Fallback: Si tenemos ZIP, la ciudad suele estar justo antes en la misma línea
    if (zip != null) {
      final lines = text.split('\n');
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].contains(zip)) {
          String lineBeforeZip = lines[i].split(zip)[0].trim();
          // Eliminar el estado si está presente (ej: "HOMESTEAD FL" -> "HOMESTEAD")
          lineBeforeZip = lineBeforeZip.replaceAll(RegExp(r'\b(FL|GA|NY|TX|CA|NC|NV|SC|WA|IL|MD)\b'), '').trim();
          
          if (lineBeforeZip.length > 3 && !RegExp(r'\d').hasMatch(lineBeforeZip)) {
            return lineBeforeZip;
          }
        }
      }
    }
    return null;
  }

  String? _extractStreetNumber(String text, String? zip) {
    final lines = text.split('\n');
    
    // 🛡️ FILTRO MAESTRO LAD V12: Extracción Quirúrgica de Números
    // 1. Priorizamos números que estén en la misma línea que palabras clave de dirección
    final streetKeywords = RegExp(r'\b(ST|AVE|HWY|RD|BLVD|LN|DR|WAY|DIXIE|MAIN|ROAD|PKWY|NE|NW|SE|SW|STREET|AVENUE|BOULEVARD)\b');
    for (var line in lines) {
      final cleanLine = line.trim().toUpperCase();
      if (streetKeywords.hasMatch(cleanLine)) {
         final match = RegExp(r'\b(\d{1,6})\b').firstMatch(cleanLine);
         if (match != null && match.group(1) != zip) {
           return match.group(1);
         }
      }
    }

    // 2. Buscamos el Store ID (Formato # seguido de números)
    final storeIdRegex = RegExp(r'#\s*(\d{3,6})\b');
    final storeMatch = storeIdRegex.firstMatch(text);
    if (storeMatch != null) return storeMatch.group(1);

    // 3. Fallback: Cualquier número puro de 3 a 6 dígitos (que no sea el ZIP y no esté al principio del ticket)
    final allNumbers = RegExp(r'\b\d{3,6}\b').allMatches(text).toList();
    if (allNumbers.length > 1) {
       // Si hay varios, el de la dirección suele ser más largo o estar más abajo que el Order Number
       for (var m in allNumbers.reversed) {
         if (m.group(0) != zip) return m.group(0);
       }
    }
    
    return null;
  }

  String? _extractOrderNumber(List<String> lines) {
    // 🍔 REGLA MCDONALD'S LAD: Standalone 4 digits near the top
    for (int i = 0; i < lines.length && i < 8; i++) {
      final line = lines[i].trim();
      if (RegExp(r'^\d{4}$').hasMatch(line)) {
        return line;
      }
      if (line.contains('ORDER #') || line.contains('PEDIDO #')) {
        return RegExp(r'\d+').firstMatch(line)?.group(0);
      }
    }
    return null;
  }

  String? _detectStoreImproved(List<String> lines) {
    final giants = ['WALMART', 'PUBLIX', 'TARGET', 'COSTCO', 'CVS', '7-ELEVEN', 'STARBUCKS', 'MCDONALD', 'LITTLE CAESAR', 'BURGER KING', 'BK #', 'DOMINO', 'CHILI', 'WENDY'];
    
    // 🚫 LISTA NEGRA: Palabras de la interfaz de usuario de las apps que debemos ignorar
    final uiBlacklist = [
      'RASTREADOR', 'PEDIDO', 'DETALLES', 'CERRAR', 'VOLVER', 'AYUDA', 'TRACKER', 'ORDER', 
      'CHECKOUT', 'HISTORY', 'ORDEN', 'PREPARADA', 'LISTA', 'ENTREGA', 'ESTADO', 'MISION'
    ];

    // 🚀 PASO 1: PRIORIDAD ABSOLUTA A MARCAS GIGANTES (En todo el texto)
    for (var line in lines) {
      final cleanLine = line.toUpperCase();
      for (var g in giants) {
        if (cleanLine.contains(g)) {
          if (g == 'BK #') return 'BURGER KING';
          if (g == 'MCDONALD') return 'MCDONALD\'S';
          return cleanLine.contains('LITTLE') ? 'LITTLE CAESARS' : g;
        }
      }
    }

    // 🚀 PASO 2: SI NO HAY GIGANTES, BUSCAR NOMBRES LIMPIOS
    for (var line in lines) {
      final cleanLine = line.toUpperCase();
      if (uiBlacklist.any((b) => cleanLine.contains(b))) continue;

      if (cleanLine.length > 3 && cleanLine.length < 30 && !RegExp(r'\d').hasMatch(cleanLine)) {
        return cleanLine;
      }
    }
    return 'ESTABLECIMIENTO'; // Fallback genérico para triangulación
  }

  String? _reconstructAddress(List<String> lines, String country, String? zip, String? streetNum) {
    // 🛡️ ESTRATEGIA CORPORATIVA LAD (V12): Reconstrucción Blindada
    
    final List<String> uiBlacklist = [
      'RASTREADOR', 'ORDEN RECIBIDA', 'DETALLES', 'ESTADO', 'TRACKER', 'CHECKOUT', 
      'HISTORY', 'CERRAR', 'VOLVER', 'ESTÁS EN', 'ESTAS EN', 'TU ORDEN', 'MAPA', 'TU PEDIDO'
    ];

    final streetKeywords = RegExp(r'\b(ST|AVE|HWY|RD|BLVD|LN|DR|WAY|DIXIE|MAIN|ROAD|PKWY|NE|NW|SE|SW|STREET|AVENUE)\b');

    // 🚀 MEJORA PARA MCDONALD'S APP: Si la línea contiene el número de calle y palabras clave de dirección
    for (var line in lines) {
      if (streetKeywords.hasMatch(line) && RegExp(r'\b\d{1,6}\b').hasMatch(line)) {
        String cleanLine = line;
        for (var junk in uiBlacklist) {
          cleanLine = cleanLine.replaceAll(junk, '').trim();
        }
        
        // Si después de limpiar nos queda algo coherente con números y letras
        if (cleanLine.length > 5 && RegExp(r'\d').hasMatch(cleanLine)) {
          return _cleanExtraSpaces(cleanLine);
        }
      }
    }

    // 1. Si tenemos ZIP, reconstruimos el entorno (Estrategia Proactiva)
    if (zip != null) {
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].contains(zip)) {
          String p1 = (i > 0) ? lines[i-1] : "";
          
          // Limpiar basura de la línea de dirección
          for (var junk in uiBlacklist) {
            p1 = p1.replaceAll(junk, '').trim();
          }
          
          if (p1.length < 15 && !RegExp(r'\d').hasMatch(p1) && i > 1) {
             String p2 = lines[i-2];
             for (var junk in uiBlacklist) { p2 = p2.replaceAll(junk, '').trim(); }
             p1 = "$p2 $p1";
          }
          
          String lineWithZip = lines[i];
          for (var junk in uiBlacklist) { lineWithZip = lineWithZip.replaceAll(junk, '').trim(); }

          String full = "$p1 $lineWithZip";
          if (RegExp(r'\d').hasMatch(full)) {
            return _cleanExtraSpaces(full.replaceAll(RegExp(r'#\s*\d+'), ''));
          }
        }
      }
    }

    // 2. Búsqueda por Patrones de Calle (Ej: 123 NE 8TH ST)
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

  String _cleanExtraSpaces(String text) {
    String clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // 🛡️ ANTI-DUPLICADOS RADICAL LAD: Buscamos cualquier ZIP de 5 dígitos que aparezca más de una vez
    // y dejamos solo la primera aparición.
    final allZips = RegExp(r'\b\d{5}\b').allMatches(clean).map((m) => m.group(0)).toSet();
    for (var zip in allZips) {
      if (zip == null) continue;
      // Si el ZIP aparece más de una vez (ej: "33177 ... 33177")
      if (RegExp('\\b$zip\\b').allMatches(clean).length > 1) {
        // Reemplazamos todas las apariciones por un marcador temporal, luego restauramos solo la primera
        int count = 0;
        clean = clean.split(' ').map((word) {
          if (word.replaceAll(',', '') == zip) {
            count++;
            return count == 1 ? word : ''; // Borramos las siguientes
          }
          return word;
        }).join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
      }
    }
    return clean;
  }

  void dispose() {
    _textRecognizer.close();
    _entityExtractor.close();
  }
}
