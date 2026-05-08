import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_auth/local_auth.dart';

class BiometricVerificationPage extends StatefulWidget {
  const BiometricVerificationPage({super.key});

  @override
  State<BiometricVerificationPage> createState() => _BiometricVerificationPageState();
}

class _BiometricVerificationPageState extends State<BiometricVerificationPage> {
  final ImagePicker _picker = ImagePicker();
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isProcessing = false;
  File? _imageFile;

  Future<void> _takeSelfie() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );

      if (photo != null) {
        setState(() {
          _imageFile = File(photo.path);
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

  Future<void> _verifyAndProceed() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, toma una selfie primero.")),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw "Sesión no válida.";

      // 🛡️ SEGURIDAD NIVEL LUCRECIO: Forzar huella si el hardware lo permite
      bool authenticated = false;
      try {
        final bool canCheckBiometrics = await _auth.canCheckBiometrics;
        final bool isDeviceSupported = await _auth.isDeviceSupported();

        if (canCheckBiometrics || isDeviceSupported) {
          // Si el teléfono tiene sensor de huellas (canCheckBiometrics), biometricOnly es TRUE.
          // Esto impide que el driver use el PIN si tiene sensor de huellas.
          authenticated = await _auth.authenticate(
            localizedReason: 'Autenticación obligatoria para iniciar sesión de trabajo',
            options: AuthenticationOptions(
              stickyAuth: true,
              biometricOnly: canCheckBiometrics, 
            ),
          );
        } else {
          // Si el dispositivo es tan viejo que no soporta nada, por negocio dejamos pasar.
          authenticated = true; 
        }
      } catch (e) {
        debugPrint("Error en biometría local: $e");
        authenticated = false; 
      }

      if (!authenticated) {
        throw "Autenticación fallida o cancelada.";
      }

      // 2. SUBIDA DE EVIDENCIA
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('verifications/${user.uid}/evidence_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      await storageRef.putFile(_imageFile!);
      final selfieUrl = await storageRef.getDownloadURL();

      // 3. ACTUALIZACIÓN EN FIRESTORE (Campo exacto para el Dashboard)
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'lastIdentityVerification': FieldValue.serverTimestamp(),
        'lastVerificationPhoto': selfieUrl,
        'isVerified': true,
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
              const Icon(Icons.fingerprint, color: Colors.greenAccent, size: 80),
              const SizedBox(height: 20),
              const Text(
                "ACCESO SEGURO",
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Tómate la selfie y valida tu identidad con tu huella para activarte.",
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
                      color: _imageFile != null ? Colors.greenAccent : Colors.white24, 
                      width: 4
                    ),
                    image: _imageFile != null 
                      ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                      : null,
                  ),
                  child: _imageFile == null 
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_front, color: Colors.white24, size: 50),
                          SizedBox(height: 10),
                          Text("TOMAR SELFIE", style: TextStyle(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      )
                    : null,
                ),
              ),

              const SizedBox(height: 60),
              
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
                    child: const Text(
                      "COMPLETAR Y ENTRAR",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
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
