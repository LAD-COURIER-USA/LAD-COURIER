import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lad_courier/auth/login_or_register_page.dart';
import 'package:lad_courier/auth/role_dispatcher.dart';
import 'package:lad_courier/auth/user_data_validator.dart';
import 'package:lad_courier/screens/client_dashboard.dart';
import 'package:lad_courier/screens/driver_dashboard.dart';
import 'package:lad_courier/screens/driver_work_zone_page.dart';
import 'package:lad_courier/screens/admin/control_tower_page.dart';
import 'package:lad_courier/services/order_service.dart';
import 'package:lad_courier/models/order_model.dart';
import 'package:lad_courier/auth_service.dart';
import 'package:provider/provider.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Colors.black),
              ),
            );
          }
          if (!snapshot.hasData) return const LoginOrRegisterPage();

          final User user = snapshot.data!;
          return UserDataValidator(
            authService: authService,
            builder: (context, userDataMap) {
              if (userDataMap == null) return const RoleDispatcher();

              if (!(userDataMap['setupComplete'] ?? false)) return const RoleDispatcher();

              final role = (userDataMap['role'] as String? ?? '').toUpperCase();
              final franchiseStatus = (userDataMap['driverFranchiseStatus'] as String? ?? 'ACTIVE').toUpperCase();

              // 🛡️ REGLA SOBERANA: Si el Driver está sancionado, le mostramos el muro
              if (role == 'DRIVER' && franchiseStatus != 'ACTIVE') {
                return _buildSuspensionMuro(context, userDataMap);
              }

              if (role == 'CLIENT') return const ClientDashboard();
              if (role == 'ADMIN') return const ControlTowerPage();

              return StreamBuilder<List<OrderModel>>(
                stream: OrderService().getActiveOrdersStream(user.uid),
                builder: (context, orderSnapshot) {
                  if (orderSnapshot.hasData && orderSnapshot.data!.isNotEmpty) {
                    return const DriverWorkZonePage();
                  }
                  return const DriverDashboard();
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSuspensionMuro(BuildContext context, Map<String, dynamic> data) {
    final String reason = data['suspensionMessage'] ?? "Incumplimiento de términos de microfranquicia.";
    final String status = data['driverFranchiseStatus'] ?? 'SUSPENDED';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == 'REVOKED' ? Icons.gavel : Icons.timer_off, 
              color: Colors.redAccent, 
              size: 80
            ),
            const SizedBox(height: 30),
            Text(
              status == 'REVOKED' ? "FRANQUICIA REVOCADA" : "DRIVER SUSPENDIDO",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 20),
            Text(
              "Motivo: $reason",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 50),
            const Text(
              "Aun puedes seguir operando como CLIENTE mientras se resuelve tu situación.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid != null) {
                  await FirebaseFirestore.instance.collection('users').doc(uid).update({'role': 'CLIENT'});
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
              child: const Text("CONTINUAR COMO CLIENTE"),
            ),
          ],
        ),
      ),
    );
  }
}
