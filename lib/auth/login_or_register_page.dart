import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Para detectar si es Web
import 'package:universal_html/html.dart' as html; // Importación universal segura
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lad_courier/auth/login_page.dart';
import 'package:lad_courier/auth/register_page.dart';

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
    _checkReferral();
  }

  // --- LÓGICA DE DETECCIÓN DE ALTA PRECISIÓN ---
  Future<void> _checkReferral() async {
    // 🛡️ REFUERZO SOBERANO: Búsqueda inmediata y persistente
    for (int i = 0; i < 20; i++) {
      String? foundId;

      if (kIsWeb) {
        try {
          final String href = html.window.location.href;
          // Buscamos el ID con el patrón Regex que Safari no puede engañar
          final regExp = RegExp(r'[?&](id|ref)=([^&#/]+)');
          final match = regExp.firstMatch(href);
          if (match != null) {
            foundId = match.group(2);
          }
          
          // Respaldo de LocalStorage (Llave Unificada)
          if (foundId == null || foundId.isEmpty) {
            foundId = html.window.localStorage['pending_messenger_invitation'];
          }
        } catch (_) {}
      }

      final prefs = await SharedPreferences.getInstance();
      foundId ??= prefs.getString('pending_messenger_invitation');

      if (foundId != null && foundId.trim().isNotEmpty && mounted) {
        final String cleanId = foundId.trim();
        setState(() {
          _referredById = cleanId;
          _showInvitation = true; // 🚀 BINGO: Disparamos la bienvenida
        });
        await prefs.setString('pending_messenger_invitation', cleanId);
        return; 
      }
      await Future.delayed(const Duration(seconds: 1));
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
          // Capa Base
          showLoginPage
              ? LoginPage(onTap: togglePages)
              : RegisterPage(onTap: togglePages),

          // Capa Superior (Overlay): Invitación personalizada (SOLO WEB/PWA)
          if (kIsWeb && _showInvitation && _referredById != null)
            Positioned.fill(
              child: Container(
                color: Colors.black, 
                alignment: Alignment.center,
                padding: const EdgeInsets.all(25),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars_rounded, color: Colors.greenAccent, size: 60),
                      const SizedBox(height: 20),
                      const Text(
                        "¡HOLA iOS & FIRE! 🔥",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Has sido invitado a la red soberana.\n¿Es tu primera vez aquí?",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 40),
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _showInvitation = false;
                              showLoginPage = false; 
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: const Text("NO, SOY NUEVO (REGISTRARME)", style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                      
                      const SizedBox(height: 15),

                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: () {
                            html.window.open('https://www.tiktok.com/@lad_courier_usa/video/7671344211093900558', '_blank');
                          },
                          icon: const Icon(Icons.play_circle_fill, color: Colors.greenAccent),
                          label: const Text(
                            "VIDEO: ¿CÓMO INSTALAR EN MI PANTALLA?", 
                            style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _showInvitation = false;
                              showLoginPage = true; 
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white, width: 2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: const Text("SÍ, YA TENGO CUENTA (INICIAR)", style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),

                      const SizedBox(height: 30),
                      TextButton(
                        onPressed: () => setState(() => _showInvitation = false),
                        child: const Text("Omitir por ahora", style: TextStyle(color: Colors.grey)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
