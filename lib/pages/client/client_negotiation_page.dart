import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lad_courier/models/order_model.dart';
import 'package:lad_courier/services/order_service.dart';
import 'package:lad_courier/l10n/app_localizations.dart';


class ClientNegotiationPage extends StatefulWidget {
  final String orderId;
  const ClientNegotiationPage({super.key, required this.orderId});

  @override
  State<ClientNegotiationPage> createState() => _ClientNegotiationPageState();
}

class _ClientNegotiationPageState extends State<ClientNegotiationPage> {
  final OrderService _orderService = OrderService();
  final _priceController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(l10n.neg_client_details_title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<OrderModel?>(
        stream: _orderService.getOrderStream(widget.orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) Navigator.of(context).pop(); });
            return Center(child: Text(l10n.neg_client_closing));
          }

          final order = snapshot.data!;
          final messengerOffers = order.negotiationHistory.where((h) => h['offeredBy'] == 'messenger').toList();
          if (messengerOffers.isEmpty) return Center(child: Text(l10n.neg_client_waiting, style: const TextStyle(fontWeight: FontWeight.bold)));

          final lastOffer = messengerOffers.last;
          final lastPrice = lastOffer['price'] as num;
          final isFinalOffer = messengerOffers.length >= 2;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildMessengerCard(order, l10n),
                      const SizedBox(height: 16),
                      _buildRouteCard(order, l10n),
                      const SizedBox(height: 16),
                      _buildPackageCard(order, l10n),
                      const SizedBox(height: 24),
                      _buildPriceDisplay(lastPrice, isFinalOffer, l10n),
                    ],
                  ),
                ),
              ),
              _buildActionPanel(order, lastPrice, isFinalOffer, l10n),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessengerCard(OrderModel order, AppLocalizations l10n) {
    return Card(
      elevation: 4,
      color: const Color(0xFFE3F2FD),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.blue, width: 1)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              backgroundImage: (order.messengerPhotoUrl != null && order.messengerPhotoUrl!.isNotEmpty) ? NetworkImage(order.messengerPhotoUrl!) : null,
              child: (order.messengerPhotoUrl == null || order.messengerPhotoUrl!.isEmpty) ? const Icon(Icons.person, size: 35, color: Colors.grey) : null,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.neg_client_driver_assigned, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                  Text(order.messengerName ?? 'Driver Lad Courier', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black)),
                  Text(order.serviceType.toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteCard(OrderModel order, AppLocalizations l10n) {
    return Card(
      elevation: 2,
      color: const Color(0xFFE8F5E9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.green, width: 1)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildRouteItem(Icons.location_on, l10n.order_details_pickup, order.pickupAddress, Colors.green[800]!),
            const Divider(height: 20, color: Colors.green),
            _buildRouteItem(Icons.flag, l10n.order_details_delivery, order.dropoffAddress, Colors.red[800]!),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteItem(IconData icon, String label, String address, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[800])),
              Text(address, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.black)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPackageCard(OrderModel order, AppLocalizations l10n) {
    return Card(
      color: const Color(0xFFFFF3E0),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.orange, width: 1.5)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2, size: 18, color: Colors.orange[900]),
                const SizedBox(width: 8),
                Text(l10n.neg_client_order_details, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.orange[900])),
              ],
            ),
            const Divider(color: Colors.orange),
            // TÁCTICO: Foto del producto/recibo visible durante negociación
            if (order.productPhotoUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
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
              ),
            Text(
              (order.packageDetails == null || order.packageDetails!.isEmpty) ? l10n.order_details_no_instructions : order.packageDetails!,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceDisplay(num price, bool isFinal, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isFinal ? Colors.red[900]! : Colors.green[900]!, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        children: [
          Text(isFinal ? l10n.neg_client_price_final : l10n.neg_client_price_proposal,
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: isFinal ? Colors.red[900] : Colors.green[900])),
          const SizedBox(height: 5),
          Text(NumberFormat.currency(symbol: '\$').format(price),
              style: const TextStyle(fontSize: 54, fontWeight: FontWeight.w900, color: Colors.black)),
        ],
      ),
    );
  }

  Widget _buildActionPanel(OrderModel order, num lastPrice, bool isFinal, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)], borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              onPressed: _isLoading ? null : () async {
                setState(() => _isLoading = true);
                await _orderService.acceptPrice(orderId: order.id, price: lastPrice.toDouble());
                if (mounted) Navigator.pop(context);
              },
              child: Text(isFinal ? l10n.neg_client_btn_accept_final : l10n.neg_client_btn_accept, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
            ),
            const SizedBox(height: 12),
            if (!isFinal)
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: () => _showCounterOfferDialog(l10n),
                child: Text(l10n.neg_client_btn_counter, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
              )
            else
              OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 55), side: const BorderSide(color: Colors.red, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: _isLoading ? null : () async {
                  setState(() => _isLoading = true);
                  await _orderService.rejectFinalOffer(orderId: order.id);
                  if (mounted) Navigator.pop(context);
                },
                child: Text(l10n.neg_client_btn_reject_cancel, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }

  void _showCounterOfferDialog(AppLocalizations l10n) {
    final NavigatorState pageNavigator = Navigator.of(context);
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final NavigatorState dialogNavigator = Navigator.of(dialogContext);
        return AlertDialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.greenAccent, width: 1)),
          title: Text(l10n.neg_client_dialog_title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.neg_client_dialog_body, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      labelText: l10n.neg_client_dialog_label,
                      labelStyle: const TextStyle(color: Colors.greenAccent),
                      prefixText: '\$ ',
                      prefixStyle: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 24),
                      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
                    ),
                    autofocus: true,
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(15, 0, 15, 20),
          actions: [
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent, width: 1.5), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: Text(l10n.neg_client_dialog_btn_cancel, maxLines: 1, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: () => dialogNavigator.pop(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 5,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: Text(l10n.neg_client_dialog_btn_send, maxLines: 1, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14)),
                    onPressed: () async {
                      final newPrice = double.tryParse(_priceController.text);
                      if (newPrice != null && newPrice > 0) {
                        await _orderService.counterOffer(orderId: widget.orderId, price: newPrice);
                        dialogNavigator.pop();
                        pageNavigator.pop();
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}