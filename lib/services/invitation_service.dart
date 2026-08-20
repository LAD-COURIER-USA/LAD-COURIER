import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lad_courier/models/user_model.dart';
import 'package:lad_courier/l10n/app_localizations.dart';

/// Un servicio dedicado para manejar toda la lógica relacionada con
/// la creación y gestión de invitaciones (Android e iPhone).
class InvitationService {

  /// --- 🤖 ENLACE UNIFICADO SOBERANO (V2026) ---

  /// Genera el enlace maestro que lleva a la Landing Page
  String getUnifiedLink(String uid) {
    return 'https://ladcourier.com/?id=$uid';
  }

  /// Método para compartir rápido (Usa el nuevo estándar SharePlus 2026)
  void shareLink(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String link = getUnifiedLink(user.uid);
    
    // 🛡️ MENSAJE AMISTOSO RESTAURADO Y CORREGIDO
    final String msg = "¡Hola! 👋 Te invito a formar parte de mi red de confianza en LAD Courier USA. "
        "Descarga la App o accede vía Web para enviarme tus pedidos directamente y sin intermediarios. "
        "Aquí tienes el acceso a mi búnker personal: $link";

    SharePlus.instance.share(ShareParams(text: msg, subject: "Invitación a LAD Courier USA"));
  }

  /// --- 🏛️ FUNCIONES ORIGINALES ACTUALIZADAS ---

  /// Construye un enlace de invitación personal (Referido estándar)
  void shareInvitationLink(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final l10n = AppLocalizations.of(context)!;

    if (user == null) return;

    final String userId = user.uid;
    final String invitationLink = 'https://ladcourier.com/?id=$userId&type=referral';
    final String shareMessage = l10n.service_invitation_share_msg(invitationLink);

    SharePlus.instance.share(ShareParams(text: shareMessage, subject: l10n.service_invitation_subject));
  }

  /// Recomendar un mensajero específico por parte de un cliente.
  void shareMessengerRecommendation({
    required BuildContext context,
    required UserModel messenger,
    required UserModel client,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final String invitationLink =
        'https://ladcourier.com/?id=${client.uid}&recommendedMessengerId=${messenger.uid}&type=recommendation';

    final String shareMessage = l10n.service_recommend_share_msg(
      messenger.displayName ?? "Driver",
      invitationLink,
    );

    SharePlus.instance.share(ShareParams(text: shareMessage, subject: l10n.service_recommend_subject));
  }
}
