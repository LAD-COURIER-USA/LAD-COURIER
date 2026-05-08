import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class GeodataService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Map<String, Map<String, dynamic>> _memoryCache = {};

  String _inferStateFromZip(String zip) {
    if (zip.length < 3) return "FL";
    final prefix = int.tryParse(zip.substring(0, 3)) ?? 0;

    if (prefix >= 350 && prefix <= 369) return "AL";
    if (prefix >= 995 && prefix <= 999) return "AK";
    if (prefix >= 850 && prefix <= 865) return "AZ";
    if (prefix >= 716 && prefix <= 729) return "AR";
    if (prefix >= 900 && prefix <= 961) return "CA";
    if (prefix >= 800 && prefix <= 816) return "CO";
    if (prefix >= 060 && prefix <= 069) return "CT";
    if (prefix >= 197 && prefix <= 199) return "DE";
    if (prefix >= 320 && prefix <= 349) return "FL";
    if (prefix >= 300 && prefix <= 319) return "GA";
    if (prefix >= 967 && prefix <= 968) return "HI";
    if (prefix >= 832 && prefix <= 838) return "ID";
    if (prefix >= 600 && prefix <= 629) return "IL";
    if (prefix >= 460 && prefix <= 479) return "IN";
    if (prefix >= 500 && prefix <= 528) return "IA";
    if (prefix >= 660 && prefix <= 679) return "KS";
    if (prefix >= 400 && prefix <= 427) return "KY";
    if (prefix >= 700 && prefix <= 714) return "LA";
    if (prefix >= 039 && prefix <= 049) return "ME";
    if (prefix >= 206 && prefix <= 219) return "MD";
    if (prefix >= 010 && prefix <= 027) return "MA";
    if (prefix >= 480 && prefix <= 499) return "MI";
    if (prefix >= 550 && prefix <= 567) return "MN";
    if (prefix >= 386 && prefix <= 397) return "MS";
    if (prefix >= 630 && prefix <= 658) return "MO";
    if (prefix >= 590 && prefix <= 599) return "MT";
    if (prefix >= 680 && prefix <= 693) return "NE";
    if (prefix >= 889 && prefix <= 898) return "NV";
    if (prefix >= 030 && prefix <= 038) return "NH";
    if (prefix >= 070 && prefix <= 089) return "NJ";
    if (prefix >= 870 && prefix <= 884) return "NM";
    if (prefix >= 100 && prefix <= 149) return "NY";
    if (prefix >= 270 && prefix <= 289) return "NC";
    if (prefix >= 580 && prefix <= 588) return "ND";
    if (prefix >= 430 && prefix <= 458) return "OH";
    if (prefix >= 730 && prefix <= 749) return "OK";
    if (prefix >= 970 && prefix <= 979) return "OR";
    if (prefix >= 150 && prefix <= 196) return "PA";
    if (prefix >= 028 && prefix <= 029) return "RI";
    if (prefix >= 290 && prefix <= 299) return "SC";
    if (prefix >= 570 && prefix <= 577) return "SD";
    if (prefix >= 370 && prefix <= 385) return "TN";
    if (prefix >= 750 && prefix <= 799) return "TX";
    if (prefix >= 840 && prefix <= 847) return "UT";
    if (prefix >= 050 && prefix <= 059) return "VT";
    if (prefix >= 220 && prefix <= 246) return "VA";
    if (prefix >= 980 && prefix <= 994) return "WA";
    if (prefix >= 247 && prefix <= 268) return "WV";
    if (prefix >= 530 && prefix <= 549) return "WI";
    if (prefix >= 820 && prefix <= 831) return "WY";
    return "FL";
  }

  Future<Map<String, dynamic>?> findStoreByDna({
    required String zip,
    required String streetNumber,
    String countryCode = "US",
    String? stateCode,
  }) async {
    if (zip.isEmpty || streetNumber.isEmpty) return null;

    final cleanZip = zip.replaceAll(RegExp(r'[^0-9]'), '').trim();
    final finalZip = cleanZip.length > 5 ? cleanZip.substring(0, 5) : cleanZip;
    final cleanNum = streetNumber.trim().toUpperCase();

    String state = (stateCode == null || stateCode.isEmpty || stateCode == "XX")
        ? _inferStateFromZip(finalZip)
        : stateCode.toUpperCase();

    String coll = "geodata_us_${state.toLowerCase()}";
    final docId = "US_${state}_${finalZip}_$cleanNum".toUpperCase();

    if (_memoryCache.containsKey(docId)) return _memoryCache[docId];

    try {
      debugPrint("LAD: Consultando ADN [$docId] en [$coll]");
      final query = await _db.collection(coll).where('search_key', isEqualTo: docId).limit(1).get();

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        _enrichData(data);
        _memoryCache[docId] = data;
        debugPrint("LAD: BINGO! Encontrado en $coll");
        return data;
      }

      if (state == "FL") {
        final fQuery = await _db.collection('geodata_fl').where('search_key', isEqualTo: docId).limit(1).get();
        if (fQuery.docs.isNotEmpty) {
          final data = fQuery.docs.first.data();
          _enrichData(data);
          _memoryCache[docId] = data;
          return data;
        }
      }
    } catch (e) {
      debugPrint("LAD ERROR en $coll: $e");
    }
    return null;
  }

  /// RESTAURADO: Permite que el Driver enseñe nuevas direcciones al sistema
  Future<void> registerNewValidatedStore({
    required String zip,
    required String streetNumber,
    required String storeName,
    required String fullAddress,
    required double lat,
    required double lng,
    required String driverId,
    String countryCode = "US",
    String? stateCode,
  }) async {
    try {
      final cleanZip = zip.replaceAll(RegExp(r'[^0-9]'), '').trim();
      final finalZip = cleanZip.length > 5 ? cleanZip.substring(0, 5) : cleanZip;
      final cleanNum = streetNumber.trim().toUpperCase();

      String state = (stateCode == null || stateCode.isEmpty || stateCode == "XX")
          ? _inferStateFromZip(finalZip)
          : stateCode.toUpperCase();

      String collectionName = "geodata_us_${state.toLowerCase()}";
      final docId = "US_${state}_${finalZip}_$cleanNum".toUpperCase();

      final storeData = {
        'id': docId,
        'name': storeName.toUpperCase(),
        'active': true,
        'is_verified': true,
        'source': 'driver_validated',
        'validated_by': driverId,
        'validation_date': FieldValue.serverTimestamp(),
        'address': {
          'number': cleanNum,
          'street': fullAddress.toUpperCase().replaceFirst(cleanNum, '').trim(),
          'city': '',
          'state': state,
          'zip': finalZip,
          'country': 'US',
        },
        'gps': {'lat': lat, 'lon': lng},
        'search_key': docId,
      };

      await _db.collection(collectionName).doc(docId).set(storeData, SetOptions(merge: true));
      _enrichData(storeData);
      _memoryCache[docId] = storeData;
      debugPrint("LAD: Dirección aprendida con éxito: $docId");
    } catch (e) {
      debugPrint("LAD ERROR en Auto-Aprendizaje: $e");
    }
  }

  void _enrichData(Map<String, dynamic> data) {
    if (data['address'] != null) {
      final addr = data['address'];
      data['address']['full'] = "${addr['number'] ?? ''} ${addr['street'] ?? ''}, ${addr['city'] ?? ''}, ${addr['state'] ?? ''} ${addr['zip'] ?? ''}".toUpperCase();
    }
  }
}