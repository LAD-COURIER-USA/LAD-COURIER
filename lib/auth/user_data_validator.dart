import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lad_courier/auth_service.dart';
import 'package:lad_courier/l10n/app_localizations.dart';

class UserDataValidator extends StatefulWidget {
  final AuthService authService;
  final Widget Function(BuildContext, Map<String, dynamic>?) builder;

  const UserDataValidator({
    super.key,
    required this.authService,
    required this.builder,
  });

  @override
  State<UserDataValidator> createState() => _UserDataValidatorState();
}

class _UserDataValidatorState extends State<UserDataValidator> {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final l10n = AppLocalizations.of(context)!;

    if (currentUser == null) return widget.builder(context, null);

    return StreamBuilder<DocumentSnapshot>(
      stream: widget.authService.getUserStream(uid: currentUser.uid),
      builder: (context, snapshot) {
        // 🛡️ AUDITORÍA: SI LA RED MUERE, AVISAMOS EN LUGAR DE MAREARNOS
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.signal_wifi_connected_no_internet_4, size: 70, color: Colors.red),
                  const SizedBox(height: 20),
                  const Text("LAD COURIER: SIN CONEXIÓN", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
                  const Padding(
                    padding: EdgeInsets.all(25),
                    child: Text("Tu dispositivo no puede contactar con nuestros servidores. Por favor revisa tu internet o DNS.", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                    child: const Text("REINTENTAR", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasData && !snapshot.data!.exists) {
          return widget.builder(context, null);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.black)),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        return widget.builder(context, userData);
      },
    );
  }
}
