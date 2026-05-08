import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lad_courier/models/order_model.dart';
import 'package:lad_courier/services/order_service.dart';
import 'package:lad_courier/l10n/app_localizations.dart';

class CompletedOrdersPage extends StatelessWidget {
  final bool isDriver;
  const CompletedOrdersPage({super.key, this.isDriver = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final OrderService orderService = OrderService();
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: Text(l10n.client_dash_history_title.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5)),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: isDriver
            ? orderService.getRecentCompletedOrdersForMessengerStream(uid)
            : orderService.getRecentCompletedOrdersStream(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("ERROR", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.black));

          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 80, color: Colors.black45),
                  const SizedBox(height: 15),
                  Text(l10n.client_dash_no_requests.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black, fontSize: 16)),
                  const SizedBox(height: 5),
                  const Text("36H HISTORY / PROTECCIÓN TOTAL",
                      style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (context, index) => _buildEnhancedOrderCard(context, orders[index], l10n),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedOrderCard(BuildContext context, OrderModel order, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black, width: 2.5),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: Colors.black, borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("ORDEN FINALIZADA", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w900, fontSize: 14)),
                Text("\$${order.price?.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(Icons.person, isDriver ? "CLIENTE: ${order.clientName}" : "DRIVER: ${order.messengerName}"),
                _infoRow(Icons.category, "SERVICIO: ${order.serviceType}"),
                if (order.packageDetails != null) _infoRow(Icons.inventory_2, "DETALLES: ${order.packageDetails}"),
                const Divider(color: Colors.black26),
                _infoRow(Icons.location_on, "RECOGIDA: ${order.pickupAddress}", color: Colors.green[900]),
                _infoRow(Icons.flag, "ENTREGA: ${order.dropoffAddress}", color: Colors.red[900]),
                const Divider(color: Colors.black, thickness: 2, height: 30),

                Row(
                  children: [
                    if (order.productPhotoUrl != null) Expanded(child: _photoBox(context, "FOTO RECIBO", order.productPhotoUrl!)),
                    const SizedBox(width: 10),
                    if (order.deliveryProofUrl != null) Expanded(child: _photoBox(context, "PRUEBA ENTREGA", order.deliveryProofUrl!)),
                  ],
                ),

                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black12)),
                  child: Column(children: [
                    const Text("MENSAJE DE ENTREGA:", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.black54)),
                    const SizedBox(height: 4),
                    Text(order.statusMessage ?? "ENTREGA REALIZADA CON ÉXITO", textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black, fontSize: 13)),
                  ]),
                ),
                const SizedBox(height: 15),
                Center(child: Text("FECHA Y HORA: ${order.completionTimestamp?.toDate().toString().substring(0, 16)}",
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.black45))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Icon(icon, size: 20, color: color ?? Colors.black),
        const SizedBox(width: 12),
        Expanded(child: Text(text.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black, fontSize: 12, height: 1.2))),
      ]),
    );
  }

  Widget _photoBox(BuildContext context, String label, String url) {
    return Column(children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
      const SizedBox(height: 6),
      GestureDetector(
        onTap: () => _showFullImage(context, url),
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(10)),
          child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(url, height: 110, width: double.infinity, fit: BoxFit.cover)),
        ),
      ),
    ]);
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(child: Center(child: Image.network(url))),
            Positioned(top: 40, right: 20, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 35), onPressed: () => Navigator.pop(context))),
          ],
        ),
      ),
    );
  }
}
