import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lad_courier/models/user_model.dart';
import 'package:lad_courier/services/order_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lad_courier/l10n/app_localizations.dart';

class DriverSelectionPage extends StatefulWidget {
  final GeoPoint pickupLatLng;
  final GeoPoint dropoffLatLng;
  final String pickupAddress;
  final String dropoffAddress;
  final String serviceType;
  final String packageDetails;
  final String? productPhotoUrl;
  final String countryCode; // 🌍 SOPORTE INTERNACIONAL

  const DriverSelectionPage({
    super.key,
    required this.pickupLatLng,
    required this.dropoffLatLng,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.serviceType,
    required this.packageDetails,
    this.productPhotoUrl,
    this.countryCode = "US",
  });

  @override
  State<DriverSelectionPage> createState() => _DriverSelectionPageState();
}

class _DriverSelectionPageState extends State<DriverSelectionPage> {
  final OrderService _orderService = OrderService();
  bool _isCreating = false;

  String _normalize(String text) {
    return text.toLowerCase().trim()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll('ñ', 'n');
  }

  bool _isServiceMatch(List<dynamic> messengerServices, String selectedType) {
    final services = messengerServices.map((s) => _normalize(s.toString())).toList();
    final selected = _normalize(selectedType);
    
    if (services.any((s) => s == selected || s.contains(selected) || selected.contains(s))) {
      return true;
    }

    if (selected.contains('courier') || selected.contains('paquet') || selected.contains('mensaj')) {
      return services.any((s) => 
        s.contains('paquet') || s.contains('courier') || s.contains('coursier') || 
        s.contains('correio') || s.contains('kouriye') || s.contains('mesaj'));
    } else if (selected.contains('shop') || selected.contains('compra') || selected.contains('encargo')) {
      return services.any((s) => 
        s.contains('compra') || s.contains('shop') || s.contains('achat') || 
        s.contains('acha') || s.contains('komisyon') || s.contains('mandado'));
    } else if (selected.contains('logist') || selected.contains('carga') || selected.contains('flete')) {
      return services.any((s) => 
        s.contains('logist') || s.contains('carga') || s.contains('flete') || s.contains('especializada'));
    }
    return false;
  }

  Stream<List<UserModel>> _getCompatibleDrivers() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'MESSENGER')
        .where('isMessengerActive', isEqualTo: true) // 1. REQUISITO: DISPONIBLE
        .snapshots()
        .map((snapshot) {
      final allDrivers = snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
      
      final filtered = allDrivers.where((driver) {
        // 2. REQUISITO: PRESTAR EL SERVICIO SOLICITADO
        bool offersService = _isServiceMatch(driver.availableServices, widget.serviceType);
        if (!offersService || driver.workZoneCenter == null) {
          return false;
        }

        // 3. REQUISITO: COBERTURA (Dual Circle Logic - Basada en Membresía)
        final plan = (driver.subscriptionType ?? 'lite').toLowerCase();
        double pickupLimit = 5.0;
        double dropoffLimit = 5.0;

        if (plan == 'standard' || plan == 'standart') {
          pickupLimit = 25.0;
          dropoffLimit = 25.0;
        } else if (plan == 'pro') {
          pickupLimit = 25.0;
          dropoffLimit = 120.0; // El sello de LAD COURIER
        } else if (driver.maxRadiusMiles > 0) {
          pickupLimit = driver.maxRadiusMiles;
          dropoffLimit = driver.maxRadiusMiles;
        }

        double distToPickup = Geolocator.distanceBetween(
          driver.workZoneCenter!.latitude,
          driver.workZoneCenter!.longitude,
          widget.pickupLatLng.latitude,
          widget.pickupLatLng.longitude,
        ) / 1609.34;

        double distToDropoff = Geolocator.distanceBetween(
          driver.workZoneCenter!.latitude,
          driver.workZoneCenter!.longitude,
          widget.dropoffLatLng.latitude,
          widget.dropoffLatLng.longitude,
        ) / 1609.34;

        return distToPickup <= pickupLimit && distToDropoff <= dropoffLimit;
      }).toList();

      // 4. REQUISITO: ORDENAR POR CERCANÍA GPS REAL (Ubicación actual en ruta)
      filtered.sort((a, b) {
        // Usamos lastKnownLocation (GPS Real) si está disponible, sino el centro de su zona
        final locA = a.lastKnownLocation ?? a.workZoneCenter!;
        final locB = b.lastKnownLocation ?? b.workZoneCenter!;

        double distA = Geolocator.distanceBetween(
          locA.latitude, locA.longitude,
          widget.pickupLatLng.latitude, widget.pickupLatLng.longitude);
        double distB = Geolocator.distanceBetween(
          locB.latitude, locB.longitude,
          widget.pickupLatLng.latitude, widget.pickupLatLng.longitude);
        return distA.compareTo(distB);
      });

      // 5. REQUISITO: LIMITAR A LOS 5 MÁS CERCANOS AL PUNTO DE RECOGIDA
      return filtered.take(5).toList();
    });
  }

  Future<void> _sendOrder(UserModel driver, AppLocalizations l10n) async {
    setState(() => _isCreating = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return;
      }

      await _orderService.createOrder(
        clientId: currentUser.uid,
        clientName: currentUser.displayName ?? 'Cliente',
        clientPhotoUrl: currentUser.photoURL,
        assignedMessengerId: driver.uid,
        messengerName: driver.displayName ?? 'Driver',
        messengerPhotoUrl: driver.photoURL,
        serviceType: widget.serviceType,
        pickupAddress: widget.pickupAddress,
        pickupLatLng: widget.pickupLatLng,
        dropoffAddress: widget.dropoffAddress,
        dropoffLatLng: widget.dropoffLatLng,
        packageDetails: widget.packageDetails,
        productPhotoUrl: widget.productPhotoUrl,
        countryCode: widget.countryCode, // 🌍 ASIGNACIÓN DE PAÍS
      );

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("🚀 ${l10n.notification_order_sent_success}"),
              backgroundColor: Colors.black,
              duration: const Duration(seconds: 4),
            )
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l10n.driver_selection_title.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[100], height: 1),
        ),
      ),
      body: Stack(
        children: [
          StreamBuilder<List<UserModel>>(
            stream: _getCompatibleDrivers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.black));
              }
              final drivers = snapshot.data ?? [];

              if (drivers.isEmpty) {
                return _buildNoDriversFound(l10n);
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                itemCount: drivers.length,
                itemBuilder: (context, index) => _buildDriverCard(drivers[index], l10n),
              );
            },
          ),
          if (_isCreating)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text("ENVIANDO MISIÓN...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDriverCard(UserModel driver, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 8))
        ],
        border: Border.all(color: Colors.grey[100]!, width: 1),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 1.5)
                  ),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.grey[100],
                    backgroundImage: (driver.photoURL != null && driver.photoURL!.isNotEmpty)
                        ? NetworkImage(driver.photoURL!) : null,
                    child: (driver.photoURL == null || driver.photoURL!.isEmpty)
                        ? const Icon(Icons.person, size: 35, color: Colors.black) : null,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(driver.displayName?.toUpperCase() ?? "DRIVER",
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.directions_car, size: 14, color: Colors.orange),
                            const SizedBox(width: 6),
                            Text(driver.vehicleDescription?.toUpperCase() ?? "AUTO",
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.orange)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(driver.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                          const SizedBox(width: 15),
                          const Icon(Icons.phone, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(driver.phoneNumber ?? "---", style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: ElevatedButton(
              onPressed: () => _sendOrder(driver, l10n),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 4,
                shadowColor: Colors.black45,
              ),
              child: Text(
                "ENVIAR AL DRIVER ${driver.displayName?.split(' ').first.toUpperCase() ?? 'DRIVER'}",
                style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNoDriversFound(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search_rounded, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 25),
            const Text("ZONA SIN COBERTURA",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black)),
            const SizedBox(height: 15),
            Text(
              "No hay drivers disponibles para el servicio de '${widget.serviceType.toUpperCase()}' en esta zona en este momento.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.bold, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
