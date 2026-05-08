import 'package:flutter/material.dart';
import 'package:lad_courier/auth_service.dart';
import 'package:lad_courier/widgets/my_button.dart';
import 'package:lad_courier/widgets/my_text_field.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lad_courier/l10n/app_localizations.dart';

class LoginPage extends StatefulWidget {
  final void Function()? onTap;
  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isLoading = false;

  void signIn(AppLocalizations l10n) async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.auth_error_fields)),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      await AuthService().signIn(
        email: emailController.text,
        password: passwordController.text,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasLaunchedBefore', true);

    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
        // CORRECCIÓN: Usamos la etiqueta dinámica para errores traducidos
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.auth_error_generic(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: _isLoading
              ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.black),
              const SizedBox(height: 16),
              Text(l10n.auth_role_preparing),
            ],
          )
              : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.lock, size: 100, color: Colors.black),
                const SizedBox(height: 50),
                Text(l10n.auth_login_welcome,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[700], fontSize: 16)),
                const SizedBox(height: 25),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: MyTextField(controller: emailController, hintText: l10n.auth_login_email, obscureText: false),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: MyTextField(controller: passwordController, hintText: l10n.auth_login_password, obscureText: true),
                ),
                const SizedBox(height: 25),

                MyButton(onTap: () => signIn(l10n), text: l10n.auth_login_btn),

                const SizedBox(height: 50),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    children: [
                      Text(l10n.auth_login_not_member, style: TextStyle(color: Colors.grey[700])),
                      GestureDetector(
                        onTap: widget.onTap,
                        child: Text(l10n.auth_login_register_now,
                            style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}