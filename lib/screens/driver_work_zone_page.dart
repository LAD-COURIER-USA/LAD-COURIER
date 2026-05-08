// Final fix for localization, initialization errors and dual zone radar
import 'dart:async';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lad_courier/models/order_model.dart';
import 'package:lad_courier/models/user_model.dart';
import 'package:lad_courier/services/order_service.dart';
import 'package:lad_courier/screens/messenger/order_negotiation_page.dart';
import 'package:lad_courier/screens/messenger/active_order_details_page.dart';
import 'package:lad_courier/services/location_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lad_courier/l10n/app_localizations.dart';
import 'package:lad_courier/services/invitation_service.dart';

class DriverWorkZonePage extends StatefulWidget {
  const DriverWorkZonePage({super.key});
  @override
  State<DriverWorkZonePage> createState() => _DriverWorkZonePageState();
}

class _DriverWorkZonePageState extends State<DriverWorkZonePage> {
  final OrderService _orderService = OrderService();
  final LocationService _locationService = LocationService();
  final InvitationService _invitationService = InvitationService();
  final DraggableScrollableController _panelController = DraggableScrollableController();
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  GoogleMapController? _mapController;

  Position? _driverPosition;
  bool _isLoadingLocation = true;
  double _userMaxRadius = 5.0; 
  double _userMaxDropoffRadius = 5.0; 
  LatLng? _fixedWorkZoneCenter;

  Stream<List<OrderModel>> _filteredNegotiatingOrdersStream = Stream.value([]);
  StreamSubscription? _activeOrdersSubscription;
  StreamSubscription? _userSubscription;
  StreamSubscription? _locationSubscription;

  List<OrderModel> _activeOrders = [];
  final Set<Polyline> _polylines = {};
  final Set<Circle> _circles = {};
  final Set<Marker> _markers = {};
  String? _mapStyle;

  final Set<String> _completedPointIds = {};

  Map<String, int> _lastKnownOrdersState = {};
  Set<String> _activePointIdsSnapshot = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        _initializeNotifications();
        _fetchLocationAndSetupStreams();
        _loadMapStyle();
      }
    });
  }

  Future<void> _initializeNotifications() async {
    try {
      // ESTANDARIZACIÓN LAD: Usamos ic_launcher_main (icono de franquicia) para todo el sistema
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('ic_launcher_main');
      const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
      await _localNotifications.initialize(initializationSettings);

      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint("SISTEMA LAD: Error no crítico en notificaciones: $e");
    }
  }

  Future<void> _loadMapStyle() async {
    final hour = DateTime.now().hour;
    String stylePath = (hour >= 6 && hour < 19)
        ? 'assets/map_styles/day_style.json'
        : 'assets/map_styles/night_style.json';
    try {
      final style = await rootBundle.loadString(stylePath);
      if (mounted) setState(() => _mapStyle = style);
    } catch (e) { debugPrint(e.toString()); }
  }

  Future<BitmapDescriptor> _createNumberedMarkerIconWithColor(int number, Color color) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = color;
    const double radius = 25.0;
    canvas.drawCircle(const Offset(radius, radius), radius, paint);
    TextPainter painter = TextPainter(textDirection: TextDirection.ltr);
    painter.text = TextSpan(
        text: number.toString(),
        style: const TextStyle(fontSize: 22.0, color: Colors.white, fontWeight: FontWeight.bold)
    );
    painter.layout();
    painter.paint(canvas, Offset(radius - painter.width / 2, radius - painter.height / 2));
    final ui.Image image = await pictureRecorder.endRecording().toImage(60, 60);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(data!.buffer.asUint8List());
  }

  Future<void> _fetchLocationAndSetupStreams() async {
    try {
      final position = await _locationService.getCurrentLocation(context);
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null && mounted) {
        setState(() {
          _driverPosition = position;
          _fixedWorkZoneCenter = LatLng(position.latitude, position.longitude);
        });

        _locationSubscription = Geolocator.getPositionStream(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10)
        ).listen((newPos) {
          if (mounted) {
            setState(() => _driverPosition = newPos);
            if (_activeOrders.isNotEmpty) _calculateOperationalSequence(_activeOrders);
          }
        });

        _userSubscription = FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots().listen((snapshot) {
          if (!snapshot.exists || !mounted) return;
          final userData = UserModel.fromFirestore(snapshot);
          setState(() {
            _userMaxRadius = userData.maxRadiusMiles;
            _userMaxDropoffRadius = userData.maxDropoffRadiusMiles;

            if (userData.workZoneCenter != null) {
              _fixedWorkZoneCenter = LatLng(userData.workZoneCenter!.latitude, userData.workZoneCenter!.longitude);
            }

            _circles.clear();
            _circles.add(Circle(
                circleId: const CircleId('pickup_zone'),
                center: _fixedWorkZoneCenter!,
                radius: _userMaxRadius * 1609.34,
                fillColor: Colors.deepPurple.withAlpha(25),
                strokeColor: Colors.deepPurple,
                strokeWidth: 3
            ));

            if (_userMaxDropoffRadius > _userMaxRadius) {
              _circles.add(Circle(
                  circleId: const CircleId('delivery_zone'),
                  center: _fixedWorkZoneCenter!,
                  radius: _userMaxDropoffRadius * 1609.34,
                  fillColor: Colors.blue.withAlpha(10),
                  strokeColor: Colors.blueAccent.withAlpha(80),
                  strokeWidth: 2,
              ));
            }

            _isLoadingLocation = false;
            _updateNegotiatingOrdersStream(currentUser.uid);
          });
        });

        _activeOrdersSubscription = _orderService.getActiveOrdersStream(currentUser.uid).listen((orders) async {
          if (!mounted) return;
          if (orders.isEmpty) {
            setState(() {
              _activeOrders = [];
              _completedPointIds.clear();
              _activePointIdsSnapshot.clear();
              _polylines.clear();
              _markers.clear();
            });
            return;
          }
          Set<String> currentPointIds = {};
          for (var o in orders) {
            if (o.status == OrderStatus.active || o.status == OrderStatus.enRouteToPickup) currentPointIds.add("p_${o.id}");
            if (o.status == OrderStatus.pickedUp || o.status == OrderStatus.enRouteToDelivery) currentPointIds.add("d_${o.id}");
          }
          for (String oldId in _activePointIdsSnapshot) {
            if (!currentPointIds.contains(oldId)) _completedPointIds.add(oldId);
          }
          _activePointIdsSnapshot = currentPointIds;
          _activeOrders = orders;
          _calculateOperationalSequence(orders);
        });
      }
    } catch (e) {
      debugPrint("SISTEMA LAD: Error en flujo de ubicación: $e");
      if (mounted) setState(() { _isLoadingLocation = false; });
    }
  }

  void _calculateOperationalSequence(List<OrderModel> orders) {
    List<Map<String, dynamic>> points = [];
    if (_driverPosition == null) return;
    for (var o in orders) {
      if ((o.status == OrderStatus.active || o.status == OrderStatus.enRouteToPickup) && o.pickupLatLng != null) {
        points.add({'id': "p_${o.id}", 'latlng': o.pickupLatLng, 'type': 'p', 'order': o});
      }
      if ((o.status == OrderStatus.pickedUp || o.status == OrderStatus.enRouteToDelivery) && o.dropoffLatLng != null) {
        points.add({'id': "d_${o.id}", 'latlng': o.dropoffLatLng, 'type': 'd', 'order': o});
      }
    }
    points.sort((a, b) {
      double distA = Geolocator.distanceBetween(_driverPosition!.latitude, _driverPosition!.longitude, a['latlng'].latitude, a['latlng'].longitude);
      double distB = Geolocator.distanceBetween(_driverPosition!.latitude, _driverPosition!.longitude, b['latlng'].latitude, b['latlng'].longitude);
      return distA.compareTo(distB);
    });
    _drawOperationalRoute(points);
    _buildNumberedMarkers(points);
  }

  void _drawOperationalRoute(List<Map<String, dynamic>> points) {
    List<LatLng> path = [LatLng(_driverPosition!.latitude, _driverPosition!.longitude)];
    for (var p in points) { path.add(LatLng(p['latlng'].latitude, p['latlng'].longitude)); }
    setState(() {
      _polylines.clear();
      _polylines.add(Polyline(
          polylineId: const PolylineId('op_route'),
          points: path,
          color: Colors.deepPurple,
          width: 5,
          jointType: JointType.round,
          patterns: [PatternItem.dash(15), PatternItem.gap(10)]
      ));
    });
  }

  Future<void> _buildNumberedMarkers(List<Map<String, dynamic>> points) async {
    final Set<Marker> newMarkers = {};
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final order = p['order'] as OrderModel;
      int sequenceNumber = _completedPointIds.length + (i + 1);
      newMarkers.add(Marker(
        markerId: MarkerId(p['id']),
        position: LatLng(p['latlng'].latitude, p['latlng'].longitude),
        icon: await _createNumberedMarkerIconWithColor(sequenceNumber, p['type'] == 'p' ? Colors.green : Colors.red),
        onTap: () => _openDetails(order, sequenceNumber),
      ));
    }
    setState(() {
      _markers.clear();
      _markers.addAll(newMarkers);
    });
  }

  void _openDetails(OrderModel o, int sequenceNumber) {
    if (_driverPosition == null) return;
    final l10n = AppLocalizations.of(context)!;
    bool isDropoff = o.status == OrderStatus.pickedUp || o.status == OrderStatus.enRouteToDelivery;
    String missionType = isDropoff ? l10n.deliver_label : l10n.pickup_label;
    LatLng target = isDropoff
        ? LatLng(o.dropoffLatLng!.latitude, o.dropoffLatLng!.longitude)
        : LatLng(o.pickupLatLng!.latitude, o.pickupLatLng!.longitude);
    double distanceToPoint = Geolocator.distanceBetween(_driverPosition!.latitude, _driverPosition!.longitude, target.latitude, target.longitude);
    Navigator.push(context, MaterialPageRoute(builder: (context) => ActiveOrderDetailsPage(
      order: o,
      allOrders: _activeOrders,
      missionIndex: sequenceNumber,
      missionType: missionType,
      isInRange: distanceToPoint <= 250,
    )));
  }

  void _updateNegotiatingOrdersStream(String uid) {
    _filteredNegotiatingOrdersStream = _orderService.getNegotiatingOrdersStream(uid).map((orders) {
      if (_fixedWorkZoneCenter == null) return [];
      
      // 🛡️ FILTRO DE SEGURIDAD LAD: Solo mostrar órdenes de los últimos 30 minutos
      final now = DateTime.now();
      var filtered = orders.where((o) {
        bool inRange = o.pickupLatLng != null && Geolocator.distanceBetween(_fixedWorkZoneCenter!.latitude, _fixedWorkZoneCenter!.longitude, o.pickupLatLng!.latitude, o.pickupLatLng!.longitude) <= (_userMaxRadius * 1609.34);
        
        bool isFresh = now.difference(o.createdAt.toDate()).inMinutes <= 30;
        
        return inRange && isFresh;
      }).toList();
      
      if (filtered.isEmpty && _panelController.isAttached && _panelController.size > 0.15) {
        _panelController.animateTo(0.15, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
      }
      return filtered;
    });
    setState(() {});
  }

  void _triggerNewOrderAlert(String title, String body) async {
    try {
      HapticFeedback.vibrate();
      HapticFeedback.heavyImpact();
      const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'high_importance_channel', 'Alertas de Pedidos Urgentes',
        importance: Importance.max, priority: Priority.high, playSound: true, enableVibration: true,
        icon: 'ic_launcher_main',
      );
      const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
      await _localNotifications.show(999, title, body, platformChannelSpecifics);
    } catch (e) {
      debugPrint("Error al disparar alerta visual: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingLocation || _fixedWorkZoneCenter == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.black))
      );
    }

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.driver_work_zone_title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      ),
      body: Stack(
        children: [
          GoogleMap(
            style: _mapStyle,
            initialCameraPosition: CameraPosition(target: _fixedWorkZoneCenter!, zoom: 11.0),
            myLocationEnabled: true, circles: _circles, polylines: _polylines, markers: _markers,
            padding: const EdgeInsets.only(bottom: 150),
            onMapCreated: (controller) => _mapController = controller,
          ),
          
          Positioned(
            right: 15,
            top: 15,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: "center_map",
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location, color: Colors.black),
                  onPressed: () {
                    if (_driverPosition != null) {
                      _mapController?.animateCamera(CameraUpdate.newLatLng(LatLng(_driverPosition!.latitude, _driverPosition!.longitude)));
                    }
                  },
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: "invite_express",
                  backgroundColor: Colors.black,
                  child: const Icon(Icons.share, color: Colors.amber, size: 20),
                  onPressed: () => _invitationService.shareInvitationLink(context),
                ),
              ],
            ),
          ),
          
          _buildDraggablePanel(l10n),
        ],
      ),
    );
  }

  Widget _buildDraggablePanel(AppLocalizations l10n) {
    return DraggableScrollableSheet(
      controller: _panelController,
      initialChildSize: 0.28, minChildSize: 0.15, maxChildSize: 0.85,
      builder: (context, scroll) => Container(
        decoration: const BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, -5))]
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 15),
            Text(l10n.driver_work_zone_pending_requests, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13)),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<List<OrderModel>>(
                  stream: _filteredNegotiatingOrdersStream,
                  builder: (context, snap) {
                    final orders = snap.data ?? [];

                    if (orders.isNotEmpty && _lastKnownOrdersState.isNotEmpty) {
                      for (var o in orders) {
                        bool isNew = !_lastKnownOrdersState.containsKey(o.id);
                        bool isUpdated = !isNew && o.negotiationHistory.length > _lastKnownOrdersState[o.id]!;

                        if (isNew) {
                          _triggerNewOrderAlert(l10n.notification_new_order_title, l10n.notification_new_order_body);
                        } else if (isUpdated) {
                          _triggerNewOrderAlert("🚀 CONTRAOFERTA RECIBIDA", "El cliente ha respondido a tu propuesta.");
                        }
                      }
                    }

                    _lastKnownOrdersState = {for (var o in orders) o.id: o.negotiationHistory.length};

                    if (orders.isEmpty) return Center(child: Text(l10n.driver_work_zone_waiting, style: const TextStyle(color: Colors.grey)));
                    return ListView.builder(
                        controller: scroll, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: orders.length,
                        itemBuilder: (context, i) {
                          final o = orders[i];
                          return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance.collection('users').doc(o.clientId).get(),
                              builder: (context, userSnap) {
                                String name = l10n.client_label;
                                String? photo;
                                if (userSnap.hasData && userSnap.data!.exists) {
                                  final data = userSnap.data!.data() as Map<String, dynamic>;
                                  name = data['displayName'] ?? name;
                                  photo = data['photoURL'];
                                }
                                return _buildRequestCard(o, name, photo, l10n);
                              }
                          );
                        }
                    );
                  }
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(OrderModel order, String name, String? photo, AppLocalizations l10n) {
    bool isCounterOffer = order.negotiationHistory.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCounterOffer ? Colors.orange[800] : Colors.deepPurple[900],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white24,
            backgroundImage: (photo != null) ? NetworkImage(photo) : null,
            child: (photo == null) ? const Icon(Icons.person, color: Colors.white) : null,
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.white))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10)
              ),
              child: Text(
                isCounterOffer ? "CONTRAOFERTA" : "NUEVA ORDEN",
                style: TextStyle(
                  color: isCounterOffer ? Colors.orange[900] : Colors.deepPurple[900],
                  fontSize: 9,
                  fontWeight: FontWeight.w900
                )
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            order.pickupAddress,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white70)
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => OrderNegotiationPage(order: order, activeOrders: _activeOrders, driverPosition: _driverPosition!))),
      ),
    );
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _activeOrdersSubscription?.cancel();
    _locationSubscription?.cancel();
    _panelController.dispose();
    super.dispose();
  }
}
