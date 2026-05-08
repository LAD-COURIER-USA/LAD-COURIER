import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InvitationCard extends StatelessWidget {
  final String messengerId;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const InvitationCard({
    super.key,
    required this.messengerId,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(messengerId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return _buildErrorCard();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final String name = data['displayName'] ?? "Mensajero Profesional";
        final String? photo = data['photoURL'];
        final String vehicle = data['vehicleDescription'] ?? "Vehículo verificado";
        final String phone = data['phoneNumber'] ?? "Contacto en la app";

        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  _buildBody(photo, name, vehicle, phone),
                  const Divider(height: 1, indent: 20, endIndent: 20, color: Colors.black12),
                  _buildFooter(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      // LÍNEA 74-75: Aplicamos 'const' al Row y su lista de hijos para rendimiento óptimo
      child: const Row(
        children: [
          Icon(Icons.verified_user, color: Colors.greenAccent, size: 18),
          SizedBox(width: 10),
          // SOLUCIÓN AL OVERFLOW: El Flexible permite que el texto se adapte al ancho disponible
          Flexible(
            child: Text(
              "TARJETA DE PRESENTACIÓN DIGITAL",
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(String? photo, String name, String vehicle, String phone) {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.grey[200],
            backgroundImage: photo != null ? NetworkImage(photo) : null,
            child: photo == null ? const Icon(Icons.person, size: 35, color: Colors.black38) : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                _buildInfoRow(Icons.directions_car_filled_rounded, vehicle),
                const SizedBox(height: 4),
                _buildInfoRow(Icons.phone_android_rounded, phone),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            "\"Te invito a ser parte de mi red de clientes para un servicio personalizado.\"",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: TextButton(
                      onPressed: onReject,
                      child: const Text("MÁS TARDE", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12))
                  )
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: onAccept,
                  child: const Text("ACEPTAR", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(children: [
      Icon(icon, size: 14, color: Colors.black38),
      const SizedBox(width: 6),
      Expanded(
          child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              overflow: TextOverflow.ellipsis
          )
      )
    ]);
  }

  Widget _buildErrorCard() {
    return const Center(
      child: Material(
        color: Colors.transparent,
        child: Text(
          "Error: No se pudo encontrar al mensajero.",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}