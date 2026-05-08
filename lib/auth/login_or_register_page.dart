import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Para detectar si es Web
import 'package:universal_html/html.dart' as html; // Importación universal segura
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lad_courier/auth/login_page.dart';
import 'package:lad_courier/auth/register_page.dart';
import 'package:lad_courier/widgets/invitation_card.dart'; // Tu widget personalizado

class LoginOrRegisterPage extends StatefulWidget {
  const LoginOrRegisterPage({super.key});

  @override
  State<LoginOrRegisterPage> createState() => _LoginOrRegisterPageState();
}

class _LoginOrRegisterPageState extends State<LoginOrRegisterPage> {
  bool showLoginPage = true;
  String? _referredById;
  bool _showInvitation = false;

  @override
  void initState() {
    super.initState();
    // Ejecutamos la detección de referido al iniciar
    _checkReferral();
  }

  // --- LÓGICA DE DETECCIÓN DE MENSAJERO DE CONFIANZA (OMNICANAL) ---
  Future<void> _checkReferral() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Revisar si ya lo teníamos guardado (Unificado con el sistema global LAD)
    String? storedId = prefs.getString('pending_messenger_invitation');

    // 2. ESCENARIO WEB: Si estamos en navegador, leemos el localStorage (inyectado por index.html)
    if (kIsWeb && storedId == null) {
      try {
        storedId = html.window.localStorage['referred_by_id'];
        if (storedId != null) {
          await prefs.setString('pending_messenger_invitation', storedId);
        }
      } catch (e) {
        debugPrint("Error leyendo localStorage: $e");
      }
    }

    // 🛡️ SISTEMA LAD: Hemos eliminado la lectura redundante del portapapeles aquí 
    // para evitar el molesto aviso de "Pegado desde el portapapeles" cada vez que 
    // entras a la pantalla. Ahora centralizamos todo en el arranque de la App (main.dart).

    // 4. Si encontramos un ID, activamos la Tarjeta de Invitación
    if (storedId != null && mounted) {
      setState(() {
        _referredById = storedId;
        _showInvitation = true;
      });
    }
  }

  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Capa Base: Pantalla de Login o Registro
          showLoginPage
              ? LoginPage(onTap: togglePages)
              : RegisterPage(onTap: togglePages),

          // Capa Superior (Overlay): Invitación personalizada
          if (_showInvitation && _referredById != null)
            Container(
              color: Colors.black.withValues(alpha: 0.85), // Fondo oscuro semi-transparente
              alignment: Alignment.center,
              padding: const EdgeInsets.all(25),
              child: InvitationCard(
                messengerId: _referredById!,
                onAccept: () {
                  setState(() => _showInvitation = false);
                  // Si aceptan, los llevamos directo a la pantalla de registro
                  if (showLoginPage) togglePages();
                },
                onReject: () async {
                  setState(() => _showInvitation = false);
                  // Si rechazan, limpiamos la referencia de la memoria
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('pending_messenger_invitation');
                  // Marcamos este ID como rechazado para esta sesión
                  await prefs.setBool('referral_rejected_$_referredById', true);
                  // También limpiamos en web si aplica
                  if (kIsWeb) html.window.localStorage.remove('referred_by_id');
                },
              ),
            ),
        ],
      ),
    );
  }
}
