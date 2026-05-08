import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lad_courier/models/order_model.dart';
import 'package:lad_courier/models/user_model.dart';
import 'package:lad_courier/services/order_service.dart';
import 'package:lad_courier/services/user_service.dart';
import 'package:lad_courier/services/route_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lad_courier/l10n/app_localizations.dart';

class OrderNegotiationPage extends StatefulWidget {
  final OrderModel order;
  final List<OrderModel> activeOrders;
  final Position driverPosition;

  const OrderNegotiationPage({
    super.key,
    required this.order,
    required this.activeOrders,
    required this.driverPosition
  });

  @override
  State<OrderNegotiationPage> createState() => _OrderNegotiationPageState();
}

class _OrderNegotiationPageState extends State<OrderNegotiationPage> {
  final OrderService _orderService = OrderService();
  final UserService _userService = UserService();
  final RouteService _routeService = RouteService();
  final TextEditingController _priceController = TextEditingController();

  bool _isLoading = false;
  UserModel? _clientProfile;

  // Variables para la guía de ruta
  double? _impactMiles;
  bool _isCalculatingImpact = true;

  // ✨ ACTUALIZADO: Variables para cálculo de Ganancia Neta Transparente
  double _netGain = 0.0;
  double _stripeFee = 0.0;
  final double _appCommission = 0.50; // Comisión LAD Courier por uso de la App

  @override
  void initState() {
    super.initState();
    _loadClientData();
    _calculateRouteImpact();
    // Escuchar cambios en el precio para actualizar el Neto
    _priceController.addListener(_updateNetCalculations);
  }

  void _updateNetCalculations() {
    final double gross = double.tryParse(_priceController.text) ?? 0.0;
    if (gross > 0) {
      // Cálculo estándar de Stripe: 2.9% + $0.30
      final double fee = (gross * 0.029) + 0.30;
      setState(() {
        _stripeFee = fee;
        _netGain = gross - fee - _appCommission;
      });
    } else {
      setState(() {
        _stripeFee = 0.0;
        _netGain = 0.0;
      });
    }
  }

  void _loadClientData() async {
    final profile = await _userService.getUser(widget.order.clientId);
    if (mounted) setState(() => _clientProfile = profile);
  }

  Future<void> _calculateRouteImpact() async {
    setState(() => _isCalculatingImpact = true);
    try {
      if (widget.activeOrders.isEmpty) {
        double toPickup = Geolocator.distanceBetween(
          widget.driverPosition.latitude, widget.driverPosition.longitude,
          widget.order.pickupLatLng!.latitude, widget.order.pickupLatLng!.longitude,
        );
        double toDelivery = Geolocator.distanceBetween(
          widget.order.pickupLatLng!.latitude, widget.order.pickupLatLng!.longitude,
          widget.order.dropoffLatLng!.latitude, widget.order.dropoffLatLng!.longitude,
        );
        _impactMiles = (toPickup + toDelivery) / 1609.34;
      } else {
        final currentRoute = await _routeService.getOptimizedRoute(
            driverPosition: widget.driverPosition,
            orders: widget.activeOrders
        );

        List<OrderModel> newSet = List.from(widget.activeOrders)..add(widget.order);
        final newRoute = await _routeService.getOptimizedRoute(
            driverPosition: widget.driverPosition,
            orders: newSet
        );

        double currentMeters = (currentRoute['distanceMeters'] as num).toDouble();
        double newMeters = (newRoute['distanceMeters'] as num).toDouble();

        _impactMiles = (newMeters - currentMeters) / 1609.34;
      }
    } catch (e) {
      debugPrint("Error impacto: $e");
    } finally {
      if (mounted) setState(() => _isCalculatingImpact = false);
    }
  }

  void _showFullImage(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(child: Center(child: Image.network(url))),
            Positioned(top: 40, right: 20, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context))),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _priceController.removeListener(_updateNetCalculations);
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<OrderModel?>(
        stream: _orderService.getOrderStream(widget.order.id),
        builder: (context, snapshot) {
          final order = snapshot.data ?? widget.order;
          final bool isNewOrder = order.negotiationHistory.isEmpty;
          final bool isCounterFromClient = order.lastPriceOfferedBy == 'client';
          final double? lastPrice = order.negotiationHistory.isNotEmpty
              ? (order.negotiationHistory.last['price'] as num).toDouble()
              : null;
          int messengerOffersCount = order.negotiationHistory
              .where((e) => e['offeredBy'] == 'messenger').length;
          bool isNextFinal = messengerOffersCount == 1;

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: Text(l10n.neg_title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 1,
              centerTitle: true,
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildClientInfoCard(order),
                          const SizedBox(height: 20),
                          _buildImpactCard(l10n),
                          const SizedBox(height: 20),
                          _buildPackageDetailsCard(order, l10n),
                          const SizedBox(height: 20),
                          _buildPriceSection(isNewOrder, isCounterFromClient, lastPrice, l10n),
                        ],
                      ),
                    ),
                  ),
                  _buildActionButtons(order, isNewOrder, isCounterFromClient, lastPrice, isNextFinal, l10n),
                ],
              ),
            ),
          );
        }
    );
  }

  Widget _buildPackageDetailsCard(OrderModel order, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange[200]!, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: Colors.orange[900], size: 20),
              const SizedBox(width: 8),
              Text("REQUERIMIENTOS",
                  style: TextStyle(fontWeight: FontWeight.w900, color: Colors.orange[900], fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          if (order.productPhotoUrl != null)
             Padding(
               padding: const EdgeInsets.only(bottom: 15),
               child: GestureDetector(
                 onTap: () => _showFullImage(order.productPhotoUrl!),
                 child: Stack(
                   children: [
                     ClipRRect(
                       borderRadius: BorderRadius.circular(15),
                       child: Image.network(
                         order.productPhotoUrl!,
                         height: 180,
                         width: double.infinity,
                         fit: BoxFit.cover,
                         loadingBuilder: (context, child, loadingProgress) {
                           if (loadingProgress == null) return child;
                           return const Center(child: CircularProgressIndicator());
                         },
                       ),
                     ),
                     Positioned(
                       right: 10,
                       bottom: 10,
                       child: Container(
                         padding: const EdgeInsets.all(8),
                         decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
                         child: const Icon(Icons.fullscreen, color: Colors.white, size: 20),
                       ),
                     ),
                   ],
                 ),
               ),
             ),
          Text(
            order.packageDetails ?? l10n.order_details_no_instructions,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildClientInfoCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)]
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: Colors.white10,
                backgroundImage: (_clientProfile?.photoURL != null) ? NetworkImage(_clientProfile!.photoURL!) : null,
                child: (_clientProfile?.photoURL == null) ? const Icon(Icons.person, size: 40, color: Colors.white) : null,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // BLINDAJE DE OVERFLOW PARA NOMBRE DEL CLIENTE
                    Text(_clientProfile?.displayName ?? order.clientName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),

                    const SizedBox(height: 5),
                    if (_clientProfile?.phoneNumber != null)
                      GestureDetector(
                        onTap: () => launchUrl(Uri.parse('tel:${_clientProfile!.phoneNumber}')),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: Colors.greenAccent, borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.phone, size: 14, color: Colors.black),
                              const SizedBox(width: 5),
                              Text(_clientProfile!.phoneNumber!, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 30, color: Colors.white24),
          _buildLocationRow(Icons.location_on, "RECOGIDA", order.pickupAddress, Colors.greenAccent),
          const SizedBox(height: 12),
          _buildLocationRow(Icons.flag, "ENTREGA", order.dropoffAddress, Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, String label, String address, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey[500])),
            Text(address, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ))
      ],
    );
  }

  Widget _buildImpactCard(AppLocalizations l10n) {
    if (_isCalculatingImpact) {
      return const Center(child: LinearProgressIndicator(color: Colors.blue));
    }

    String msg = widget.activeOrders.isEmpty
        ? l10n.neg_impact_single(_impactMiles!.toStringAsFixed(1))
        : l10n.neg_impact_multi(_impactMiles!.toStringAsFixed(1));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.blue, width: 2)
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_graph, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(child: Text(msg, style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blue[900], fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildPriceSection(bool isNewOrder, bool isCounter, double? lastPrice, AppLocalizations l10n) {
    String label = isNewOrder ? l10n.neg_client_initial : (isCounter ? l10n.neg_client_counter : l10n.neg_driver_last);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)], border: Border.all(color: Colors.grey[200]!)),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 10),
          if (!isNewOrder) Text('\$${lastPrice?.toStringAsFixed(2) ?? "0.00"}', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.black)),
          const SizedBox(height: 25),
          TextField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.deepPurple),
            decoration: InputDecoration(
              hintText: "0.00",
              labelText: l10n.neg_input_label,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
              prefixIcon: const Icon(Icons.attach_money, color: Colors.black),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.black, width: 2)),
            ),
          ),
          
          // ✨ ACTUALIZADO: DESGLOSE DE TRANSPARENCIA DEFINITIVO COMPACTO
          if (_netGain > 0)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueGrey[50],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blueGrey[100]!),
              ),
              child: Column(
                children: [
                  _buildBreakdownRow("Comisión LAD", "-\$${_appCommission.toStringAsFixed(2)}"),
                  _buildBreakdownRow("Fee Stripe", "-\$${_stripeFee.toStringAsFixed(2)}"),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Divider(height: 1, thickness: 0.5),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          "GANANCIA NETA",
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "\$${_netGain.toStringAsFixed(2)}",
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(amount, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(OrderModel order, bool isNewOrder, bool isCounter, double? lastPrice, bool isNextFinal, AppLocalizations l10n) {
    if (_isLoading) return const Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator(color: Colors.black));
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25)), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isNewOrder && isCounter)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 0),
                  onPressed: () async {
                    if (lastPrice == null) return;
                    setState(() => _isLoading = true);
                    await _orderService.acceptPrice(orderId: order.id, price: lastPrice);
                    if (mounted) Navigator.pop(context);
                  },
                  child: Text(l10n.neg_btn_accept, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16)),
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: isNextFinal ? Colors.orange[800] : Colors.deepPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 5),
              onPressed: () async {
                if (_priceController.text.isEmpty) return;
                setState(() => _isLoading = true);
                await _orderService.proposePrice(orderId: order.id, price: double.parse(_priceController.text));
                if (mounted) Navigator.pop(context);
              },
              child: Text(isNextFinal ? l10n.neg_btn_final : (isNewOrder ? l10n.neg_btn_first : l10n.neg_btn_counter), style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              setState(() => _isLoading = true);
              await _orderService.messengerRejectOrder(order.id);
              if (mounted) Navigator.pop(context);
            },
            child: Text(l10n.neg_btn_reject, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
