import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // 🛡️ PARA kIsWeb y defaultTargetPlatform
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart'; // ✅ CORREGIDO: Usando cloud_functions
import 'package:local_auth/local_auth.dart';
import 'package:otp/otp.dart'; // ✅ CORREGIDO: Usando la librería 'otp'
import 'package:lad_courier/screens/messenger/liveness_selfie_page.dart';
import 'package:lad_courier/services/storage_service.dart'; // ✅ AÑADIDO PARA SUBIDA REAL

class BiometricVerificationPage extends StatefulWidget {
  const BiometricVerificationPage({super.key});

  @override
  State<BiometricVerificationPage> createState() => _BiometricVerificationPageState();
}

class _BiometricVerificationPageState extends State<BiometricVerificationPage> {
  final LocalAuthentication _auth = LocalAuthentication();
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');
  final StorageService _storageService = StorageService();
  
  bool _isProcessing = false;
  String? _localImagePath; 
  
  // 🛡️ REFUERZO V19.3: Lógica de Autenticador (TOTP) para Web/iPad
  final TextEditingController _otpController = TextEditingController();
  bool _showOtpField = false;
  String? _totpSecret;

  Future<void> _takeSelfie() async {
    try {
      final String? localPath = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LivenessSelfiePage()),
      );

      if (localPath != null) {
        setState(() {
          _localImagePath = localPath;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al abrir cámara: $e")),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserSecurity();
  }

  Future<void> _loadUserSecurity() async {
    final user = await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).get();
    if (mounted) {
      setState(() {
        _totpSecret = user.data()?['totpSecret'];
      });
    }
  }

  Future<void> _verifyAndProceed() async {
    if (_localImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Por favor, toma una selfie primero.")));
      return;
    }

    // 🛡️ Si estamos en Web y no hemos configurado el Authenticator, avisamos
    if (kIsWeb && (_totpSecret == null || _totpSecret!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("⚠️ Debes configurar tu Llave de Seguridad en tu Perfil primero."),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    // 🛡️ Si estamos en Web, pedimos el código de 6 dígitos antes de subir nada
    if (kIsWeb && !_showOtpField) {
      setState(() => _showOtpField = true);
      return;
    }

    if (_showOtpField) {
      if (_otpController.text.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ingresa el código de 6 dígitos de tu Authenticator.")));
        return;
      }
      
      // 🛡️ REFUERZO V19.3: Validación REAL contra Google Authenticator
      final String expectedCode = OTP.generateTOTPCodeString(
        _totpSecret!,
        DateTime.now().millisecondsSinceEpoch,
        algorithm: Algorithm.SHA1,
        isGoogle: true
      );

      if (_otpController.text != expectedCode) {
        _otpController.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("❌ CÓDIGO INCORRECTO: Revisa tu Authenticator."),
          backgroundColor: Colors.red,
        ));
        return;
      }
      debugPrint("✅ SISTEMA LAD: Código TOTP verificado.");
    }

    setState(() => _isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw "Sesión no válida.";

      // 🛡️ SEGURIDAD LAD: La biometría local solo se pide en Nativo (Android/iOS)
      bool authenticated = false;
      if (!kIsWeb) {
        try {
          final bool canCheckBiometrics = await _auth.canCheckBiometrics;
          final bool isDeviceSupported = await _auth.isDeviceSupported();

          if (canCheckBiometrics || isDeviceSupported) {
            authenticated = await _auth.authenticate(
              localizedReason: 'Autenticación obligatoria para iniciar sesión de trabajo',
              options: AuthenticationOptions(
                stickyAuth: true,
                biometricOnly: canCheckBiometrics, 
              ),
            );
          } else {
            authenticated = true; 
          }
        } catch (e) {
          debugPrint("Error biometría local: $e");
          authenticated = false; 
        }
      } else {
        // 🌐 EN WEB (iPad/PC): La seguridad se delega al código del Authenticator
        authenticated = true; 
      }

      if (!authenticated) {
        throw "Autenticación fallida o cancelada.";
      }

      // 🛡️ REFUERZO V19.2: Subida REAL y Auditoría Cloud para Web
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🚀 SUBIENDO SELFIE AL BÚNKER..."), duration: Duration(seconds: 2))
        );
      }

      final String? selfieUrl = await _storageService.uploadFile(
        'order_photos', 
        "auth_${user.uid}_${DateTime.now().millisecondsSinceEpoch}", 
        _localImagePath! // Aquí pasamos el String (Ruta/Blob)
      );

      if (selfieUrl == null) {
        throw "Error crítico: No se pudo subir la foto al búnker.";
      }

      if (kIsWeb) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("👁️ AUDITANDO IDENTIDAD (IA GOOGLE)..."), duration: Duration(seconds: 2))
          );
        }

        final result = await _functions.httpsCallable('verifyLivenessCloud').call({
          'imageUrl': selfieUrl,
        });

        if (result.data['success'] != true) {
          throw result.data['error'] ?? "Fallo en la auditoría de identidad.";
        }
        debugPrint("✅ SISTEMA LAD: Auditoría Forense APROBADA.");
      }

      // 3. ACTUALIZACIÓN EN FIRESTORE
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'lastBiometricVerification': FieldValue.serverTimestamp(),
        'lastVerificationPhoto': selfieUrl,
        'isIdentityVerified': true,
        'verificationStatus': 'APROBADO_DOC',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ IDENTIDAD VERIFICADA EXITOSAMENTE"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); 
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ ERROR: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
          child: Column(
            children: [
              const Icon(Icons.security, color: Colors.greenAccent, size: 80),
              const SizedBox(height: 20),
              const Text(
                "VERIFICACIÓN SEGURA",
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Válida tu selfie y código de seguridad para continuar.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 50),
              
              GestureDetector(
                onTap: _isProcessing ? null : _takeSelfie,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _localImagePath != null ? Colors.greenAccent : Colors.white24, 
                      width: 4
                    ),
                  ),
                  child: _localImagePath == null 
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_front, color: Colors.white24, size: 50),
                          SizedBox(height: 10),
                          Text("TOMAR SELFIE", style: TextStyle(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      )
                    : ClipOval(
                        child: Image.network(_localImagePath!, fit: BoxFit.cover),
                      ),
                ),
              ),

              const SizedBox(height: 60),
              
              if (_showOtpField) ...[
                const SizedBox(height: 30),
                const Text("CÓDIGO GOOGLE AUTHENTICATOR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.greenAccent, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 10),
                  decoration: InputDecoration(
                    counterText: "",
                    filled: true,
                    fillColor: Colors.white10,
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.greenAccent)),
                    hintText: "000000",
                    hintStyle: const TextStyle(color: Colors.white24, letterSpacing: 10),
                  ),
                  onChanged: (v) {
                    if (v.length == 6) _verifyAndProceed();
                  },
                ),
                const SizedBox(height: 20),
              ],

              if (_isProcessing)
                const CircularProgressIndicator(color: Colors.greenAccent)
              else ...[
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _verifyAndProceed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: Text(
                      _showOtpField ? "VERIFICAR Y ENTRAR" : "COMPLETAR PASO 1",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("CANCELAR", style: TextStyle(color: Colors.white54)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
