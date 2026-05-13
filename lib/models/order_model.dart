import 'package:cloud_firestore/cloud_firestore.dart';

class OrderStatus {
  static const String negotiating = 'negotiating';
  static const String priceProposed = 'price_proposed';
  static const String active = 'active';
  static const String enRouteToPickup = 'en_route_to_pickup';
  static const String pickedUp = 'picked_up';
  static const String enRouteToDelivery = 'en_route_to_delivery';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
  static const String rejected = 'rejected';
}

class OrderModel {
  final String id;
  final String clientId;
  final String clientName;
  final String? clientEmail; // 📧 NUEVO: Para registros en Stripe
  final String? clientPhotoUrl;
  final String assignedMessengerId;
  final String? messengerName;
  final String? messengerPhotoUrl;
  final String serviceType;
  final GeoPoint? pickupLatLng;
  final GeoPoint? dropoffLatLng;
  final GeoPoint? completionLatLng;
  final Timestamp? completionTimestamp;
  final int? rating;
  final String pickupAddress;
  final String dropoffAddress;
  final String? packageDetails;
  final String status;
  final String? statusMessage;
  final String? eta;
  final double? price;
  final List<Map<String, dynamic>> negotiationHistory;
  final String? lastPriceOfferedBy;
  final Timestamp createdAt;
  final String? deliveryProofUrl;
  final String? productPhotoUrl;
  final String countryCode; // 🌍 SOPORTE INTERNACIONAL

  // 🛡️ COPIA DE SEGURIDAD FINANCIERA (BLINDAJE LAD)
  final String? stripeCustomerId;
  final String? paymentMethodId;

  List<Map<String, dynamic>> get priceOffers => negotiationHistory;

  OrderModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    this.clientEmail,
    this.clientPhotoUrl,
    required this.assignedMessengerId,
    this.messengerName,
    this.messengerPhotoUrl,
    required this.serviceType,
    required this.pickupAddress,
    required this.dropoffAddress,
    this.packageDetails,
    required this.status,
    this.statusMessage,
    this.eta,
    this.price,
    required this.negotiationHistory,
    this.lastPriceOfferedBy,
    required this.createdAt,
    this.pickupLatLng,
    this.dropoffLatLng,
    this.completionLatLng,
    this.completionTimestamp,
    this.rating,
    this.deliveryProofUrl,
    this.productPhotoUrl,
    this.countryCode = "US",
    this.stripeCustomerId,
    this.paymentMethodId,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      clientEmail: data['clientEmail'],
      clientPhotoUrl: data['clientPhotoUrl'],
      assignedMessengerId: data['assignedMessengerId'] ?? '',
      messengerName: data['messengerName'],
      messengerPhotoUrl: data['messengerPhotoUrl'],
      serviceType: data['serviceType'] ?? 'No especificado',
      pickupAddress: data['pickupAddress'] ?? '',
      dropoffAddress: data['dropoffAddress'] ?? '',
      packageDetails: data['packageDetails'],
      status: data['status'] ?? OrderStatus.negotiating,
      statusMessage: data['statusMessage'],
      eta: data['eta'],
      price: (data['price'] as num?)?.toDouble(),
      negotiationHistory: List<Map<String, dynamic>>.from(data['negotiationHistory'] ?? []),
      lastPriceOfferedBy: data['lastPriceOfferedBy'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      pickupLatLng: data['pickupLatLng'],
      dropoffLatLng: data['dropoffLatLng'],
      completionLatLng: data['completionLatLng'],
      completionTimestamp: data['completionTimestamp'],
      rating: data['rating'],
      deliveryProofUrl: data['deliveryProofUrl'],
      productPhotoUrl: data['productPhotoUrl'],
      countryCode: data['countryCode'] ?? "US",
      stripeCustomerId: data['stripeCustomerId'],
      paymentMethodId: data['paymentMethodId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'clientPhotoUrl': clientPhotoUrl,
      'assignedMessengerId': assignedMessengerId,
      'messengerName': messengerName,
      'messengerPhotoUrl': messengerPhotoUrl,
      'serviceType': serviceType,
      'pickupAddress': pickupAddress,
      'dropoffAddress': dropoffAddress,
      'packageDetails': packageDetails,
      'status': status,
      'statusMessage': statusMessage,
      'eta': eta,
      'price': price,
      'negotiationHistory': negotiationHistory,
      'lastPriceOfferedBy': lastPriceOfferedBy,
      'createdAt': createdAt,
      'pickupLatLng': pickupLatLng,
      'dropoffLatLng': dropoffLatLng,
      'completionLatLng': completionLatLng,
      'completionTimestamp': completionTimestamp,
      'rating': rating,
      'deliveryProofUrl': deliveryProofUrl,
      'productPhotoUrl': productPhotoUrl,
      'countryCode': countryCode,
      'stripeCustomerId': stripeCustomerId,
      'paymentMethodId': paymentMethodId,
    };
  }
}
