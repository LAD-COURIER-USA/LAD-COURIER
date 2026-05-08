import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lad_courier/models/order_model.dart';

class OrderService {
  final CollectionReference<OrderModel> _ordersRef =
  FirebaseFirestore.instance.collection('orders').withConverter<OrderModel>(
    fromFirestore: (snapshot, _) => OrderModel.fromFirestore(snapshot),
    toFirestore: (order, _) => order.toJson(),
  );

  Future<String> createOrder({
    required String clientId,
    required String clientName,
    String? clientPhotoUrl,
    required String assignedMessengerId,
    String? messengerName,
    String? messengerPhotoUrl,
    required String serviceType,
    required String pickupAddress,
    required GeoPoint pickupLatLng,
    required String dropoffAddress,
    required GeoPoint dropoffLatLng,
    String? packageDetails,
    String? productPhotoUrl,
    String countryCode = "US",
  }) async {
    try {
      final newOrder = OrderModel(
        id: '',
        clientId: clientId,
        clientName: clientName,
        clientPhotoUrl: clientPhotoUrl,
        assignedMessengerId: assignedMessengerId,
        messengerName: messengerName,
        messengerPhotoUrl: messengerPhotoUrl,
        serviceType: serviceType,
        pickupAddress: pickupAddress,
        pickupLatLng: pickupLatLng,
        dropoffAddress: dropoffAddress,
        dropoffLatLng: dropoffLatLng,
        packageDetails: packageDetails,
        productPhotoUrl: productPhotoUrl,
        status: OrderStatus.negotiating,
        negotiationHistory: [],
        createdAt: Timestamp.now(),
        lastPriceOfferedBy: 'client',
        countryCode: countryCode,
      );
      final docRef = await _ordersRef.add(newOrder);
      return docRef.id;
    } catch (e) { rethrow; }
  }

  Stream<OrderModel?> getOrderStream(String orderId) {
    return _ordersRef.doc(orderId).snapshots().map((snapshot) => snapshot.data());
  }

  Stream<List<OrderModel>> getNegotiatingOrdersStream(String messengerId) {
    return _ordersRef
        .where('assignedMessengerId', isEqualTo: messengerId)
        .where('status', whereIn: [OrderStatus.negotiating, OrderStatus.priceProposed])
        .snapshots()
        .map((s) {
      final allOrders = s.docs.map((d) => d.data()).toList();
      return allOrders.where((order) => order.lastPriceOfferedBy == 'client').toList();
    });
  }

  Future<void> proposePrice({required String orderId, required double price}) async {
    final entry = {'offeredBy': 'messenger', 'price': price, 'timestamp': Timestamp.now()};
    await _ordersRef.doc(orderId).update({
      'status': OrderStatus.priceProposed,
      'lastPriceOfferedBy': 'messenger',
      'negotiationHistory': FieldValue.arrayUnion([entry]),
      'price': price,
    });
  }

  Future<void> counterOffer({required String orderId, required double price}) async {
    final entry = {'offeredBy': 'client', 'price': price, 'timestamp': Timestamp.now()};
    await _ordersRef.doc(orderId).update({
      'status': OrderStatus.negotiating,
      'lastPriceOfferedBy': 'client',
      'negotiationHistory': FieldValue.arrayUnion([entry]),
      'price': price,
    });
  }

  Future<void> rejectFinalOffer({required String orderId}) async {
    await _ordersRef.doc(orderId).update({
      'status': OrderStatus.cancelled,
      'statusMessage': 'OFERTA RECHAZADA',
    });
  }

  Future<void> messengerRejectOrder(String orderId) async {
    await _ordersRef.doc(orderId).update({
      'status': OrderStatus.rejected,
      'statusMessage': 'MISIÓN RECHAZADA',
    });
  }

  Future<void> updateOrderStatus(String orderId, String status, {String? message, String? eta}) async {
    await _ordersRef.doc(orderId).update({
      'status': status,
      if (message != null) 'statusMessage': message,
      if (eta != null) 'eta': eta,
    });
  }

  Future<void> acceptPrice({required String orderId, required double price}) async {
    await _ordersRef.doc(orderId).update({
      'status': OrderStatus.active,
      'price': price,
      'statusMessage': 'ORDEN ACTIVA'
    });
  }

  Future<void> expireOrder(String orderId, String reason) async {
    await _ordersRef.doc(orderId).update({
      'status': OrderStatus.cancelled,
      'statusMessage': reason,
    });
  }

  Stream<List<OrderModel>> getActiveOrdersStream(String messengerId) {
    return _ordersRef.where('assignedMessengerId', isEqualTo: messengerId)
        .where('status', whereIn: [OrderStatus.active, OrderStatus.enRouteToPickup, OrderStatus.pickedUp, OrderStatus.enRouteToDelivery])
        .snapshots().map((s) => s.docs.map((d) => d.data()).toList());
  }

  Future<List<OrderModel>> getActiveOrdersOnce(String messengerId) async {
    final snapshot = await _ordersRef.where('assignedMessengerId', isEqualTo: messengerId)
        .where('status', whereIn: [OrderStatus.active, OrderStatus.enRouteToPickup, OrderStatus.pickedUp, OrderStatus.enRouteToDelivery])
        .get();
    return snapshot.docs.map((d) => d.data()).toList();
  }

  Future<Map<String, dynamic>> getMessengerStats(String messengerId, DateTime start, DateTime end) async {
    final snapshot = await _ordersRef
        .where('assignedMessengerId', isEqualTo: messengerId)
        .where('status', isEqualTo: OrderStatus.completed)
        .where('completionTimestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('completionTimestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    double totalEarnings = 0;
    double totalMiles = 0;
    List<OrderModel> orders = [];

    for (var doc in snapshot.docs) {
      final order = doc.data();
      totalEarnings += order.price ?? 0;
      if (order.pickupLatLng != null && order.dropoffLatLng != null) {
        double distance = Geolocator.distanceBetween(
          order.pickupLatLng!.latitude, order.pickupLatLng!.longitude,
          order.dropoffLatLng!.latitude, order.dropoffLatLng!.longitude,
        );
        totalMiles += distance / 1609.34;
      }
      orders.add(order);
    }

    return {
      'earnings': totalEarnings,
      'trips': snapshot.docs.length,
      'miles': totalMiles,
      'orders': orders,
    };
  }

  Stream<List<OrderModel>> getOrdersForClientResponseStream(String clientId) {
    return _ordersRef.where('clientId', isEqualTo: clientId)
        .where('status', whereIn: [OrderStatus.negotiating, OrderStatus.priceProposed])
        .snapshots().map((s) => s.docs.map((d) => d.data())
        .where((order) => order.lastPriceOfferedBy == 'messenger').toList());
  }

  Stream<List<OrderModel>> getActiveOrdersForClientStream(String clientId) {
    return _ordersRef.where('clientId', isEqualTo: clientId)
        .where('status', whereIn: [
          OrderStatus.active,
          OrderStatus.enRouteToPickup,
          OrderStatus.pickedUp,
          OrderStatus.enRouteToDelivery
        ])
        .snapshots().map((s) => s.docs.map((d) => d.data()).toList());
  }

  Stream<List<OrderModel>> getRecentCompletedOrdersStream(String clientId) {
    return _ordersRef
        .where('clientId', isEqualTo: clientId)
        .where('status', isEqualTo: OrderStatus.completed)
        .snapshots()
        .map((s) {
          final thirtySixHoursAgo = DateTime.now().subtract(const Duration(hours: 36));
          return s.docs
              .map((d) => d.data())
              .where((o) => o.completionTimestamp != null && o.completionTimestamp!.toDate().isAfter(thirtySixHoursAgo))
              .toList()
              ..sort((a, b) => b.completionTimestamp!.compareTo(a.completionTimestamp!));
        });
  }

  // ✨ NUEVO: Historial de 36h para el Messenger
  Stream<List<OrderModel>> getRecentCompletedOrdersForMessengerStream(String messengerId) {
    return _ordersRef
        .where('assignedMessengerId', isEqualTo: messengerId)
        .where('status', isEqualTo: OrderStatus.completed)
        .snapshots()
        .map((s) {
          final thirtySixHoursAgo = DateTime.now().subtract(const Duration(hours: 36));
          return s.docs
              .map((d) => d.data())
              .where((o) => o.completionTimestamp != null && o.completionTimestamp!.toDate().isAfter(thirtySixHoursAgo))
              .toList()
              ..sort((a, b) => b.completionTimestamp!.compareTo(a.completionTimestamp!));
        });
  }
}
