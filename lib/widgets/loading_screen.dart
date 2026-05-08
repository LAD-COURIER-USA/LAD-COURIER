import 'package:flutter/material.dart';

// Una pantalla de carga simple y centrada.
// Se usa mientras se determina el estado de autenticación del usuario.
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black, // Un fondo oscuro para la carga
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }
}
