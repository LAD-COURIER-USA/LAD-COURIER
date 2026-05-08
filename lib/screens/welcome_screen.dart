import 'package:flutter/material.dart';
import 'package:lad_courier/services/role_selection_service.dart';
import 'package:lad_courier/l10n/app_localizations.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final roleSelectionService = RoleSelectionService();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icono principal (Logo de la Franquicia)
              SizedBox(
                width: 150,
                height: 150,
                child: Image.asset('assets/images/ic_launcher.png'),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.welcome_title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.welcome_body,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 48),

              // --- BOTÓN DE CLIENTE ---
              ElevatedButton.icon(
                icon: SizedBox(width: 24, height: 24, child: Image.asset('assets/images/ic_launcher.png')),
                label: Text(l10n.welcome_btn_client),
                onPressed: () => roleSelectionService.selectRole(
                  context: context,
                  role: 'CLIENT',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),

              // --- BOTÓN DE MENSAJERO ---
              ElevatedButton.icon(
                icon: SizedBox(width: 24, height: 24, child: Image.asset('assets/images/ic_launcher.png')),
                label: Text(l10n.welcome_btn_driver),
                onPressed: () => roleSelectionService.selectRole(
                  context: context,
                  role: 'MESSENGER',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}