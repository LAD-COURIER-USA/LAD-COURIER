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

      // Si la FLAI falló o es dispositivo viejo, construimos la dirección con el ADN detectado
      fullAddr ??= _reconstructAddress(lines, country, zip);

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
      case 'US': return RegExp(r'\b\d{5}\b').firstMatch(text)?.group(0);
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
    final matches = RegExp(r'\b\d{1,5}\b').allMatches(text);
    for (var m in matches) {
      String n = m.group(0)!;
      if (n != zip && n.isNotEmpty) return n;
    }
    return null;
  }

  String? _detectStoreImproved(List<String> lines) {
    final giants = ['WALMART', 'PUBLIX', 'TARGET', 'COSTCO', 'CVS', '7-ELEVEN', 'STARBUCKS', 'MCDONALD'];
    for (var line in lines) {
      for (var g in giants) {
        if (line.contains(g)) return g;
      }
      // Si la línea es corta y no tiene números, probablemente es el nombre del local
      if (line.length > 3 && line.length < 25 && !RegExp(r'\d').hasMatch(line)) {
        return line;
      }
    }
    return null;
  }

  String? _reconstructAddress(List<String> lines, String country, String? zip) {
    // Busca la línea que contiene el ZIP o CEP
    if (zip == null) return null;
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains(zip)) {
        // La dirección suele estar 1 o 2 líneas arriba del ZIP en un recibo
        String addr = "";
        if (i > 0) {
          addr = "${lines[i-1]} ${lines[i]}";
        } else {
          addr = lines[i];
        }
        return addr.trim();
      }
    }
    return null;
  }

  void dispose() {
    _textRecognizer.close();
    _entityExtractor.close();
  }
}
