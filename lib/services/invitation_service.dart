import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lad_courier/models/user_model.dart';
import 'package:lad_courier/l10n/app_localizations.dart';

/// Un servicio dedicado para manejar toda la lógica relacionada con
/// la creación y gestión de invitaciones.
class InvitationService {
  /// Construye un enlace de invitación personal para el usuario actual (Referido estándar)
  void shareInvitationLink(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final l10n = AppLocalizations.of(context)!;

    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.service_invitation_error_user),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final String userId = user.uid;
    const String domain = "ladcourier.com";
    final String invitationLink = 'https://$domain/invite?id=$userId&type=referral';

    final String shareMessage = l10n.service_invitation_share_msg(invitationLink);

    SharePlus.instance.share(
      ShareParams(
        text: shareMessage,
        subject: l10n.service_invitation_subject,
      ),
    );
  }

  /// NUEVO MÉTODO TÁCTICO: Recomendar un mensajero específico por parte de un cliente.
  /// Incluye banderas para evitar que cuente como red de crecimiento del mensajero.
  void shareMessengerRecommendation({
    required BuildContext context,
    required UserModel messenger,
    required UserModel client,
  }) {
    final l10n = AppLocalizations.of(context)!;
    const String domain = "ladcourier.com";

    // El enlace incluye el ID del cliente (quien invita), el ID del mensajero (el recomendado)
    // y el tipo 'recommendation' para que el sistema sepa que no es captación directa del mensajero.
    final String invitationLink =
        'https://$domain/invite?id=${client.uid}&recommendedMessengerId=${messenger.uid}&type=recommendation';

    final String shareMessage = l10n.service_recommend_share_msg(
      messenger.displayName ?? "Driver",
      invitationLink,
    );

    SharePlus.instance.share(
      ShareParams(
        text: shareMessage,
        subject: l10n.service_recommend_subject,
      ),
    );
  }
}