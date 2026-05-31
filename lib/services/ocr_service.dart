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
  final String? streetName;
  final String? countryCode;
  final String? stateCode;
  final bool usedFLAI;

  OCRResult({
    this.storeName,
    this.fullAddress,
    this.streetNumber,
    this.zipCode,
    this.streetName,
    this.countryCode = "US",
    this.stateCode,
    this.usedFLAI = false,
  });
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

      // FLAI falló o es dispositivo viejo, reconstruimos la dirección
      fullAddr ??= _reconstructAddress(lines, country, zip, streetNum);

      return OCRResult(
        storeName: storeName,
        fullAddress: fullAddr,
        streetNumber: streetNum,
        zipCode: zip,
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

  String? _extractStreetNumber(String text, String? zip) {
    final lines = text.split('\n');
    
    // 🛡️ FILTRO MAESTRO LAD: Ignorar números de corporación/tienda (como #3128)
    // Buscamos un número que esté seguido de palabras de calle (Dixie, Hwy, Ave, etc.)
    final streetKeywords = RegExp(r'\b(ST|AVE|HWY|RD|BLVD|LN|DR|WAY|DIXIE|MAIN|ROAD)\b');
    
    for (var line in lines) {
      final cleanLine = line.trim().toUpperCase();
      
      // 🚫 REGLA DE ORO: Si la línea tiene un símbolo '#' justo antes del número, es el local ID, NO la calle.
      if (cleanLine.contains(RegExp(r'#\s*\d{3,6}'))) continue;

      // Buscamos formato: [Número] [Cualquier cosa] [Palabra clave de calle]
      final match = RegExp(r'^\s*(\d{1,6})\b.*' + streetKeywords.pattern).firstMatch(cleanLine);
      if (match != null) {
        String n = match.group(1)!;
        if (n != zip) return n;
      }
    }

    // Fallback: Si no hay match con calle, buscamos números de al menos 3 dígitos
    // (Esto ignora los "Orden #1" o "Check #1" que tienen 1 o 2 dígitos)
    for (var line in lines) {
      final match = RegExp(r'^\s*(\d{3,6})\b').firstMatch(line.trim());
      if (match != null) {
        String n = match.group(1)!;
        if (n != zip) return n;
      }
    }
    
    return null;
  }

  String? _detectStoreImproved(List<String> lines) {
    final giants = ['WALMART', 'PUBLIX', 'TARGET', 'COSTCO', 'CVS', '7-ELEVEN', 'STARBUCKS', 'MCDONALD'];
    
    // 🚫 LISTA NEGRA: Palabras de la interfaz de usuario de las apps que debemos ignorar
    final uiBlacklist = ['RASTREADOR', 'PEDIDO', 'DETALLES', 'CERRAR', 'VOLVER', 'AYUDA', 'TRACKER', 'ORDER', 'CHECKOUT'];

    for (var line in lines) {
      final cleanLine = line.toUpperCase();
      
      // 1. Buscar Marcas Gigantes
      for (var g in giants) {
        if (cleanLine.contains(g)) return g;
      }
      
      // 2. Si es una palabra de la Blacklist, la ignoramos
      if (uiBlacklist.any((b) => cleanLine.contains(b))) continue;

      // 3. Si la línea es el nombre del establecimiento (sin números, longitud media)
      if (cleanLine.length > 3 && cleanLine.length < 25 && !RegExp(r'\d').hasMatch(cleanLine)) {
        return cleanLine;
      }
    }
    return 'ESTABLECIMIENTO'; // Fallback genérico para triangulación
  }

  String? _reconstructAddress(List<String> lines, String country, String? zip, String? streetNum) {
    // 🛡️ ESTRATEGIA CORPORATIVA LAD (V2): 
    // Buscamos el ZIP y reconstruimos hacia arriba ignorando números de tienda (#)
    if (zip != null) {
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].contains(zip)) {
          String full = "";
          // Si encontramos el ZIP, la calle suele estar 1 o 2 líneas arriba
          if (i > 0) {
            String potentialStreet = lines[i-1];
            // Si la línea de arriba solo tiene la ciudad (ej: Homestead), buscamos una más arriba
            if (potentialStreet.length < 15 && !RegExp(r'\d').hasMatch(potentialStreet)) {
               if (i > 1) potentialStreet = "${lines[i-2]} $potentialStreet";
            }
            
            // 🚫 Limpiamos números de tienda (como #3128)
            full = "$potentialStreet ${lines[i]}".replaceAll(RegExp(r'#\s*\d+'), '').trim();
            return _cleanExtraSpaces(full);
          }
          return lines[i];
        }
      }
    }

    // 🛡️ OPCIÓN B: Si NO hay ZIP, buscamos la línea que empieza por el número de calle real
    if (streetNum != null) {
      for (var line in lines) {
        if (line.startsWith(streetNum) && line.length > streetNum.length + 5) {
          return line.replaceAll(RegExp(r'#\s*\d+'), '').trim();
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
