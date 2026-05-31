import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class DiscoveryResult {
  final String name;
  final String? website;
  final String address;
  final String? phone;
  final double lat;
  final double lon;
  final String category;
  final String? distance;

  DiscoveryResult({
    required this.name,
    this.website,
    required this.address,
    this.phone,
    required this.lat,
    required this.lon,
    required this.category,
    this.distance,
  });
}

class ExternalDiscoveryService {
  // 🔑 API KEY DE HERE (Roberto: Reemplázala cuando tengas la tuya oficial)
  final String _apiKey = "Hq9_8_X8B_9_8_X8B_9_8_X8B_9_8_X8B"; 

  // 🏢 MAPEO DE CATEGORÍAS HERE (INVESTIGACIÓN ROBERTO)
  static const Map<String, String> categoryMap = {
    'BURGERS': '100-1000-0009',   // Fast Food
    'PIZZA': '100-1000-0000',     // Restaurant + query pizza
    'MEXICAN': '100-1000-0005',   // Taqueria
    'ASIAN': '100-1000-0000',     // Restaurant + query asian
    'CHICKEN': '100-1000-0009',   // Fast Food
    'HEALTHY': '100-1000-0001',   // Casual Dining
    'BREAKFAST': '100-1100-0010', // Coffee Shop
    'DESSERTS': '100-1100-0010',  // Bakery / Desserts
  };

  Future<List<DiscoveryResult>> searchNearby(double lat, double lon, String ladCategory) async {
    final catId = categoryMap[ladCategory.toUpperCase()] ?? '100-1000-0000';
    String query = "";
    if (ladCategory == 'PIZZA') query = "&q=pizza";
    if (ladCategory == 'ASIAN') query = "&q=sushi";

    // 🛰️ ENDPOINT /DISCOVER DE HERE API
    final url = Uri.parse(
      "https://discover.search.hereapi.com/v1/discover"
      "?at=$lat,$lon"
      "&categories=$catId"
      "&limit=20"
      "$query"
      "&apiKey=$_apiKey"
    );

    try {
      debugPrint("SISTEMA LAD (HERE): Escaneando zona para $ladCategory...");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List items = data['items'] ?? [];
        
        return items.map((item) {
          return DiscoveryResult(
            name: item['title'] ?? 'Local',
            website: item['contacts']?[0]?['www']?[0]?['value'],
            address: item['address']?['label'] ?? 'Sin dirección',
            phone: item['contacts']?[0]?['phone']?[0]?['value'],
            lat: item['position']?['lat'],
            lon: item['position']?['lng'],
            category: ladCategory,
            distance: "${(item['distance'] / 1609.34).toStringAsFixed(1)} mi",
          );
        }).toList();
      }
    } catch (e) {
      debugPrint("SISTEMA LAD (HERE) ERROR: $e");
    }
    return [];
  }
}
