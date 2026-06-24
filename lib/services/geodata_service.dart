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

  /// RESTAURADO: Permite que el sistema aprenda nuevas direcciones validadas
  Future<void> registerNewValidatedStore({
    required String zip,
    required String streetNumber,
    required String storeName,
    required String fullAddress,
    required double lat,
    required double lng,
    required String driverId,
    String? city, // 🏙️ NUEVO: Captura de Ciudad para Triangulación
    String countryCode = "US",
    String? stateCode,
  }) async {
    try {
      // 🧹 Limpieza de ZIP: Nos quedamos con los primeros 5 dígitos para el ADN
      final cleanZip = zip.replaceAll(RegExp(r'[^0-9]'), '').trim();
      final finalZip = cleanZip.length >= 5 ? cleanZip.substring(0, 5) : cleanZip;
      
      if (finalZip.isEmpty) return;

      final cleanNum = streetNumber.trim().toUpperCase();
      if (cleanNum.isEmpty) return;

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
        'source': 'auto_learned',
        'validated_by': driverId,
        'validation_date': FieldValue.serverTimestamp(),
        'address': {
          'number': cleanNum,
          'street': fullAddress.toUpperCase().replaceFirst(cleanNum, '').trim(),
          'city': (city ?? '').toUpperCase(),
          'state': state,
          'zip': finalZip,
          'country': countryCode,
        },
        'gps': {'lat': lat, 'lon': lng},
        'search_key': docId,
      };

      await _db.collection(collectionName).doc(docId).set(storeData, SetOptions(merge: true));
      
      // Fallback para Florida (Compatibilidad con sistema viejo)
      if (state == "FL") {
        await _db.collection('geodata_fl').doc(docId).set(storeData, SetOptions(merge: true));
      }

      _enrichData(storeData);
      _memoryCache[docId] = storeData;
      debugPrint("LAD: Dirección incorporada al ADN: $docId");
    } catch (e) {
      debugPrint("LAD ERROR en Incorporación ADN: $e");
    }
  }

  /// 🛰️ ACTUALIZACIÓN DE SEGURIDAD: Permite actualizar un local existente con nuevos datos (ej. Website)
  Future<void> updateStoreDiscoveryData({
    required String storeId,
    required String stateCode,
    String? website,
    String? phone,
    String? instagram,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (website != null) updates['website'] = website;
      if (phone != null) updates['phone'] = phone;
      if (instagram != null) updates['instagram'] = instagram;
      updates['last_verified'] = FieldValue.serverTimestamp();

      String coll = "geodata_us_${stateCode.toLowerCase()}";
      await _db.collection(coll).doc(storeId).set(updates, SetOptions(merge: true));
      
      debugPrint("LAD ADN: Local $storeId actualizado con inteligencia de campo.");
    } catch (e) {
      debugPrint("LAD ADN ERROR: No se pudo actualizar local -> $e");
    }
  }

  /// 🧠 MÓDULO DE INTELIGENCIA SEMÁNTICA (SUPER-APP LAD)
  bool _checkSemanticMatch(String? categoryId, String storeCat, List<String> altCats) {
    if (categoryId == null) return true;

    final Map<String, List<String>> semanticMap = {
      'BURGERS': ['FAST_FOOD', 'BURGER', 'SANDWICH', 'AMERICAN', 'MCDONALD', 'WENDY', 'BURGER_KING'],
      'PIZZA': ['PIZZA', 'ITALIAN', 'PASTA', 'LITTLE_CAESARS', 'DOMINO', 'PAPA_JOHN'],
      'MEXICAN': ['MEXICAN', 'TACO', 'BURRITO', 'TEX-MEX', 'TACO_BELL', 'CHIPOTLE'],
      'ASIAN': ['ASIAN', 'SUSHI', 'CHINESE', 'JAPANESE', 'THAI', 'VIETNAMESE'],
      'CHICKEN': ['CHICKEN', 'WING', 'POULTRY', 'KFC', 'POPEYES', 'CHICK-FIL-A'],
      'HEALTHY': ['HEALTHY', 'VEGETARIAN', 'VEGAN', 'SALAD', 'ORGANIC', 'JUICE'],
      'BREAKFAST': ['CAFE', 'COFFEE', 'BREAKFAST', 'BAKERY', 'DONUT', 'STARBUCKS', 'DUNKIN'],
      'DESSERTS': ['DESSERT', 'ICE_CREAM', 'PASTRY', 'CONFECTIONERY', 'SWEET', 'CHOCOLATE'],
    };

    final tags = semanticMap[categoryId.toUpperCase()] ?? [categoryId.toUpperCase()];
    
    // Verificamos si alguna etiqueta del mapa coincide con la categoría del local o sus alternativas
    return tags.any((tag) => 
      storeCat.contains(tag) || 
      altCats.any((alt) => alt.contains(tag))
    );
  }

  /// 🛰️ RADAR DE TRIANGULACIÓN (NIVEL CORPORATIVO)
  /// Encuentra locales usando: Marca + Ciudad + Número de Calle
  Future<Map<String, dynamic>?> findStoreByTriangulation({
    required String brand,
    String? city,
    required String streetNumber,
    required String stateCode,
    double? userLat,
    double? userLon,
  }) async {
    String collectionName = "geodata_us_${stateCode.toLowerCase()}";
    
    try {
      debugPrint("LAD TRIANGULACIÓN: Buscando $brand con No. $streetNumber. Ref: $city / GPS: $userLat");

      // 🚀 ESTRATEGIA SOBERANA: Si no hay Ciudad, usamos el GPS como Ancla de búsqueda
      if ((city == null || city.isEmpty) && userLat != null && userLon != null) {
        debugPrint("LAD TRIANGULACIÓN: Usando GPS como ancla de área (Sin Ciudad en ticket)");
        final nearbyStores = await searchStoresByRadar(userLat: userLat, userLon: userLon, stateCode: stateCode);
        
        for (var store in nearbyStores) {
          final storeName = (store['name'] as String? ?? '').toUpperCase();
          final storeNum = (store['address']['number'] as String? ?? '');
          final storeId = (store['id'] as String? ?? '').toUpperCase();

          // 🛡️ REGLA SOBERANA V12: Match por Número + Marca (Si el nombre de la tienda contiene la marca)
          bool numberMatch = (storeNum == streetNumber || storeId.contains(streetNumber) || storeName.contains(streetNumber));
          bool brandMatch = storeName.contains(brand.toUpperCase()) || brand.toUpperCase().contains(storeName);

          if (numberMatch && brandMatch) {
            return store;
          }
        }
      }
      
      // 🚀 OPCIÓN 1: Búsqueda Quirúrgica por Número y Ciudad (Si hay ciudad)
      if (city != null && city.isNotEmpty) {
        final queryByNum = await _db.collection(collectionName)
            .where('address.number', isEqualTo: streetNumber)
            .where('address.city', isEqualTo: city.toUpperCase())
            .limit(5).get();

        if (queryByNum.docs.isNotEmpty) {
          final data = queryByNum.docs.first.data();
          _enrichData(data);
          data['id'] = queryByNum.docs.first.id;
          return data;
        }
      }

      return null;
    } catch (e) {
      debugPrint("LAD TRIANGULACIÓN ERROR: $e");
      return null;
    }
  }

  /// 🛰️ RADAR SMARTSHOPPER (ESTÁNDAR ÉLITE): Búsqueda por "Cuadrado de Coordenadas"
  /// Esta técnica es la ganadora: ignora fronteras de ZipCodes y funciona en todo USA.
  Future<List<Map<String, dynamic>>> searchStoresByRadar({
    required double userLat,
    required double userLon,
    required String stateCode,
    String? categoryId,
  }) async {
    // Definimos el margen del cuadrado (aprox 7.5 millas para asegurar las 7 reales)
    const double delta = 0.110; 

    final double minLat = userLat - delta;
    final double maxLat = userLat + delta;
    final double minLon = userLon - delta;
    final double maxLon = userLon + delta;

    String collectionName = "geodata_us_${stateCode.toLowerCase()}";
    
    try {
      debugPrint("LAD RADAR: Escaneando zona en $collectionName...");
      
      // 🚀 RADAR LIGHTWEIGHT: Bajamos el límite de 500 a 50 para evitar el 'Memory Overflow' en Samsung
      final query = await _db.collection(collectionName)
          .where('gps.lat', isGreaterThanOrEqualTo: minLat)
          .where('gps.lat', isLessThanOrEqualTo: maxLat)
          .limit(50)
          .get();

      List<Map<String, dynamic>> results = [];

      for (var doc in query.docs) {
        final data = doc.data();
        final gps = data['gps'] as Map<String, dynamic>?;
        final storeCat = (data['category'] as String?)?.toUpperCase() ?? '';
        final altCats = (data['alternate_categories'] as List?)?.map((e) => e.toString().toUpperCase()).toList() ?? [];
        
        if (gps != null) {
          double storeLon = (gps['lon'] as num).toDouble();
          
          // 🛡️ FILTRO DE PRECISIÓN EN TIEMPO REAL
          bool matchLon = storeLon >= minLon && storeLon <= maxLon;
          bool matchCat = _checkSemanticMatch(categoryId, storeCat, altCats);

          if (matchLon && matchCat) {
            _enrichData(data);
            data['id'] = doc.id;
            results.add(data);
          }
        }
      }

      // 🥇 ORDENAR: VIPs (con website) primero para fomentar la compra online
      results.sort((a, b) {
        if (a['website'] != null && b['website'] == null) return -1;
        if (a['website'] == null && b['website'] != null) return 1;
        return 0;
      });

      return results;
    } catch (e) {
      debugPrint("LAD RADAR ERROR: $e");
      return [];
    }
  }

  /// [DEPRECATED] Mantengo para evitar errores de compilación durante la transición.
  Future<List<Map<String, dynamic>>> searchByZipCluster({
    required List<String> zipCodes,
    required String stateCode,
    String? categoryId,
  }) async {
    return searchStoresByRadar(
      userLat: 25.5110645, // Homestead fallback
      userLon: -80.4220201, 
      stateCode: stateCode,
      categoryId: categoryId
    );
  }

  /// [DEPRECATED] Mantengo el anterior por si Courier lo usa, pero SmartShopper usará el de ZipCodes.
  Future<List<Map<String, dynamic>>> searchStoresNearby({
    required double userLat,
    required double userLon,
    required String stateCode,
    String? categoryId,
  }) async {
    // Definimos el margen del cuadrado (aprox 7.5 millas para ser generosos)
    const double delta = 0.110; 

    final double minLat = userLat - delta;
    final double maxLat = userLat + delta;
    final double minLon = userLon - delta;
    final double maxLon = userLon + delta;

    String collectionName = "geodata_us_${stateCode.toLowerCase()}";
    
    try {
      debugPrint("LAD RADAR: Buscando en $collectionName | Cat: $categoryId");
      
      Query query = _db.collection(collectionName)
          .where('gps.lat', isGreaterThanOrEqualTo: minLat)
          .where('gps.lat', isLessThanOrEqualTo: maxLat);

      if (categoryId != null) {
        query = query.where('category', isEqualTo: categoryId.toUpperCase());
      }

      final snapshot = await query.limit(100).get();
      
      List<Map<String, dynamic>> results = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final gps = data['gps'] as Map<String, dynamic>?;
        
        if (gps != null) {
          double storeLon = (gps['lon'] as num).toDouble();
          
          // Filtro de Longitud para cerrar el cuadrado
          if (storeLon >= minLon && storeLon <= maxLon) {
            _enrichData(data);
            data['id'] = doc.id;
            results.add(data);
          }
        }
      }

      // Ordenar por cercanía básica (Opcional)
      results.sort((a, b) {
        double distA = (userLat - a['gps']['lat']).abs() + (userLon - a['gps']['lon']).abs();
        double distB = (userLat - b['gps']['lat']).abs() + (userLon - b['gps']['lon']).abs();
        return distA.compareTo(distB);
      });

      return results;
    } catch (e) {
      debugPrint("LAD RADAR ERROR: $e");
      return [];
    }
  }

  void _enrichData(Map<String, dynamic> data) {
    if (data['address'] != null) {
      final addr = data['address'];
      final String number = addr['number'] ?? '';
      final String street = addr['street'] ?? '';
      final String city = (addr['city'] != null && addr['city'].toString().isNotEmpty) ? addr['city'] : '';
      final String state = addr['state'] ?? '';
      final String zip = addr['zip'] ?? '';
      
      String full = "$number $street".trim();
      if (city.isNotEmpty) full += ", $city";
      if (state.isNotEmpty) full += ", $state";
      if (zip.isNotEmpty) full += " $zip";
      
      data['address']['full'] = full.toUpperCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    }
  }
}
