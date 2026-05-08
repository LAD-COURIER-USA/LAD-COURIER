import 'package:flutter/material.dart';
import 'package:lad_courier/services/role_selection_service.dart';
import 'package:lad_courier/l10n/app_localizations.dart';

class RoleDispatcher extends StatefulWidget {
  const RoleDispatcher({super.key});

  @override
  State<RoleDispatcher> createState() => _RoleDispatcherState();
}

class _RoleDispatcherState extends State<RoleDispatcher> {
  final RoleSelectionService _roleSelectionService = RoleSelectionService();
  bool _isLoading = false;

  void _onRoleSelected(String role) async {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      await _roleSelectionService.selectRole(context: context, role: role).timeout(
        const Duration(seconds: 12),
        onTimeout: () => throw "La sincronización de seguridad está tardando. Por favor, intenta de nuevo o reinicia la app.",
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.auth_error_generic(e.toString())), backgroundColor: Colors.red)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.delivery_dining, size: 80, color: Colors.deepPurple),
                const SizedBox(height: 24),
                Text(l10n.auth_role_title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black)),
                const SizedBox(height: 10),
                Text(l10n.auth_role_subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 50),
                if (_isLoading)
                  const Column(
                    children: [
                      CircularProgressIndicator(color: Colors.black),
                      SizedBox(height: 20),
                      Text("Sincronizando...", style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  )
                else ...[
                  _buildRoleButton(context, Icons.person, l10n.auth_role_client, 'CLIENT', Colors.black),
                  const SizedBox(height: 20),
                  _buildRoleButton(context, Icons.two_wheeler, l10n.auth_role_messenger, 'DRIVER', Colors.deepPurple),
                ],
                const Spacer(),
                // 🛡️ NOTA DISCRETA AL PIE
                const Text(
                  "Sincronización de seguridad activa.\nSi demora, reinicia la app para agilizar.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(BuildContext context, IconData icon, String label, String role, Color color) {
    return SizedBox(
      height: 65,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 28),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        onPressed: () => _onRoleSelected(role),
      ),
    );
  }
}
