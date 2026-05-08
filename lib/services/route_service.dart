import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart'; // Añadido para cálculos internos
import '../models/order_model.dart';

class RouteService {
  final String apiKey = 'AIzaSyCXcHoOg_VZ409FGy2fpmh0bpFisKHnAG0';

  /// [NUEVO MÉTODO] Obtiene la ruta y la distancia total en metros para el cálculo de impacto
  Future<Map<String, dynamic>> getOptimizedRoute({
    required Position driverPosition,
    required List<OrderModel> orders,
  }) async {
    if (orders.isEmpty) {
      return {'distanceMeters': 0.0, 'status': 'empty'};
    }

    String origin = "${driverPosition.latitude},${driverPosition.longitude}";
    OrderModel lastOrder = orders.last;
    String destination = "${lastOrder.dropoffLatLng!.latitude},${lastOrder.dropoffLatLng!.longitude}";

    List<String> waypoints = [];
    for (var o in orders) {
      if (o.pickupLatLng != null) waypoints.add("${o.pickupLatLng!.latitude},${o.pickupLatLng!.longitude}");
      if (o != lastOrder && o.dropoffLatLng != null) waypoints.add("${o.dropoffLatLng!.latitude},${o.dropoffLatLng!.longitude}");
    }

    String url = "https://maps.googleapis.com/maps/api/directions/json?"
        "origin=$origin&"
        "destination=$destination&"
        "waypoints=optimize:true|${waypoints.join('|')}&"
        "key=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'OK') {
          double totalDistance = 0.0;
          final legs = data['routes'][0]['legs'] as List;
          for (var leg in legs) {
            totalDistance += (leg['distance']['value'] as num).toDouble();
          }
          return {
            'distanceMeters': totalDistance,
            'status': 'success'
          };
        }
      }
      return {'distanceMeters': 0.0, 'status': 'error'};
    } catch (e) {
      return {'distanceMeters': 0.0, 'status': 'error', 'message': e.toString()};
    }
  }

  /// Obtiene la ruta visual para el mapa (Ya existía)
  Future<Map<String, dynamic>> getRoute({
    required LatLng driverLocation,
    required List<OrderModel> activeOrders,
  }) async {
    if (activeOrders.isEmpty) {
      return {'polyline': <LatLng>[], 'waypoint_order': [], 'status': 'success'};
    }

    String origin = "${driverLocation.latitude},${driverLocation.longitude}";
    final lastOrder = activeOrders.last;
    if (lastOrder.dropoffLatLng == null) return {'status': 'error'};

    String destination = "${lastOrder.dropoffLatLng!.latitude},${lastOrder.dropoffLatLng!.longitude}";

    List<String> waypoints = [];
    for (var order in activeOrders) {
      if (order.pickupLatLng != null) waypoints.add("${order.pickupLatLng!.latitude},${order.pickupLatLng!.longitude}");
      if (order != lastOrder && order.dropoffLatLng != null) waypoints.add("${order.dropoffLatLng!.latitude},${order.dropoffLatLng!.longitude}");
    }

    String url = "https://maps.googleapis.com/maps/api/directions/json?"
        "origin=$origin&"
        "destination=$destination&"
        "waypoints=optimize:true|${waypoints.join('|')}&"
        "key=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'OK') {
          String encodedPoints = data['routes'][0]['overview_polyline']['points'];
          List<LatLng> polylinePoints = _decodePolyline(encodedPoints);
          List<dynamic> waypointOrder = data['routes'][0]['waypoint_order'] ?? [];

          return {
            'polyline': polylinePoints,
            'waypoint_order': waypointOrder,
            'status': 'success'
          };
        }
      }
      return {'status': 'error'};
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;
      shift = 0; result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }
}