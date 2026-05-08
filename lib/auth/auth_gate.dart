import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lad_courier/auth/login_or_register_page.dart';
import 'package:lad_courier/auth/role_dispatcher.dart';
import 'package:lad_courier/auth/user_data_validator.dart';
import 'package:lad_courier/screens/client_dashboard.dart';
import 'package:lad_courier/screens/driver_dashboard.dart';
import 'package:lad_courier/screens/driver_work_zone_page.dart';
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
              // ⏱️ SISTEMA LAD: Si el documento no existe aún, mostramos carga un momento
              // para dar tiempo a que la transacción de registro termine en Firestore.
              if (userDataMap == null) {
                 return const RoleDispatcher();
              }

              if (!(userDataMap['setupComplete'] ?? false)) return const RoleDispatcher();

              final role = (userDataMap['role'] as String? ?? '').toUpperCase();
              if (role == 'CLIENT') return const ClientDashboard();

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
}
