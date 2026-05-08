import 'package:flutter/material.dart';
import 'package:lad_courier/auth_service.dart';
import 'package:lad_courier/l10n/app_localizations.dart';

class RoleSelectionService {
  final AuthService _authService = AuthService();

  Future<void> selectRole({required BuildContext context, required String role}) async {
    try {
      await _authService.completeFirstTimeSetup(role: role);
    } catch (e) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.auth_error_role_save(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
