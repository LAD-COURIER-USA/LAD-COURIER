import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lad_courier/models/user_model.dart';
import 'package:lad_courier/l10n/app_localizations.dart';

/// Un servicio dedicado para manejar toda la lógica relacionada con
/// la creación y gestión de invitaciones (Android e iPhone).
class InvitationService {

  /// --- 🤖 ENLACES DE NUEVA GENERACIÓN (V2026) ---

  /// Genera el enlace para usuarios Android (Vía Landing Page)
  String getAndroidLink(String uid) {
    return 'https://ladcourier.com/?id=$uid';
  }

  /// Genera el enlace para usuarios iPhone/iPad (Vía Landing Page con filtro iOS)
  String getIPhoneLink(String uid) {
    return 'https://ladcourier.com/?id=$uid&os=ios';
  }

  /// Método para compartir rápido (Usa el nuevo estándar SharePlus 2026)
  void shareLink(BuildContext context, {required bool isIPhone}) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String link = isIPhone ? getIPhoneLink(user.uid) : getAndroidLink(user.uid);
    final String msg = isIPhone 
      ? "¡Hola! 👋 Únete a mi red de confianza en LAD Courier (iOS/Web): $link"
      : "¡Hola! 👋 Descarga la App y únete a mi red en LAD Courier (Android): $link";

    SharePlus.instance.share(ShareParams(text: msg, subject: "Invitación LAD Courier"));
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
