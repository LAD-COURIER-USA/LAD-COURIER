import 'package:flutter/material.dart';
import 'package:lad_courier/auth_service.dart';
import 'package:lad_courier/widgets/my_button.dart';
import 'package:lad_courier/widgets/my_text_field.dart';
import 'package:lad_courier/l10n/app_localizations.dart';

class RegisterPage extends StatefulWidget {
  final void Function()? onTap;
  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  void signUp(AppLocalizations l10n) async {
    if (nameController.text.trim().isEmpty) return _showSnackBar(l10n.auth_error_name);
    if (passwordController.text != confirmPasswordController.text) return _showSnackBar(l10n.auth_error_pass_match);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.black),
      ),
    );

    try {
      final result = await AuthService().signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        name: nameController.text.trim(),
      );

      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      if (result == 'SUCCESS') {
        // ✨ SISTEMA LAD: Limpieza total de rutas. Al ir a '/', el AuthGate detecta 
        // la sesión activa y carga el RoleDispatcher automáticamente.
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } else if (mounted) {
        _showSnackBar(result);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _showSnackBar("Error: ${e.toString()}");
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_add, size: 80, color: Colors.deepPurple),
                  const SizedBox(height: 25),
                  Text(l10n.auth_register_title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 25),
                  MyTextField(controller: nameController, hintText: l10n.auth_register_name, obscureText: false),
                  const SizedBox(height: 10),
                  MyTextField(controller: emailController, hintText: l10n.auth_login_email, obscureText: false),
                  const SizedBox(height: 10),
                  MyTextField(controller: passwordController, hintText: l10n.auth_login_password, obscureText: true),
                  const SizedBox(height: 10),
                  MyTextField(controller: confirmPasswordController, hintText: l10n.auth_register_confirm_pass, obscureText: true),
                  const SizedBox(height: 25),
                  MyButton(onTap: () => signUp(l10n), text: l10n.auth_register_btn),
                  const SizedBox(height: 30),
                  // 🛡️ NOTA DISCRETA PARA EL DESARROLLADOR/USUARIO
                  Text(
                    "Sincronización de seguridad inicial activa.\nSi demora, reinicia la app para agilizar.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text(l10n.auth_register_already_member, style: TextStyle(color: Colors.grey[700])),
                      const SizedBox(width: 5),
                      GestureDetector(
                          onTap: widget.onTap,
                          child: Text(l10n.auth_register_login_now, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}