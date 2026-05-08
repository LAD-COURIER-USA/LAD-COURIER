import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:lad_courier/api_keys.dart';

class GeocodingResponse {
  final GeoPoint latLng;
  final String? streetNumber;
  final String? zipCode;
  final String? state;
  final String? city;
  final String fullAddress;

  GeocodingResponse({
    required this.latLng,
    required this.fullAddress,
    this.streetNumber,
    this.zipCode,
    this.state,
    this.city,
  });
}

class GeocodingService {
  Future<GeocodingResponse?> getFullDetails(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedAddress&key=$googleMapsApiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final result = data['results'][0];
          final location = result['geometry']['location'];
          final components = result['address_components'] as List;

          String? streetNumber;
          String? zipCode;
          String? state;
          String? city;

          for (var comp in components) {
            final types = comp['types'] as List;
            if (types.contains('street_number')) streetNumber = comp['long_name'];
            if (types.contains('postal_code')) zipCode = comp['long_name'];
            if (types.contains('administrative_area_level_1')) state = comp['short_name'];
            if (types.contains('locality')) city = comp['long_name'];
          }

          return GeocodingResponse(
            latLng: GeoPoint(location['lat'], location['lng']),
            fullAddress: result['formatted_address'],
            streetNumber: streetNumber,
            zipCode: zipCode,
            state: state,
            city: city,
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error en GeocodingService: $e');
      return null;
    }
  }

  /// Mantiene compatibilidad con el código existente
  Future<GeoPoint?> getLatLng(String address) async {
    final res = await getFullDetails(address);
    return res?.latLng;
  }
}
