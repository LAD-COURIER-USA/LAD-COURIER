import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // 🚀 IMPORTACIÓN PARA debugPrint
import 'package:lad_courier/services/user_service.dart';

/// Servicio encargado de la autenticación y gestión de perfiles en Firestore.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Obtiene un stream con los datos del documento de usuario.
  Stream<DocumentSnapshot> getUserStream({required String uid}) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  /// Inicia sesión con email y contraseña.
  Future<UserCredential?> signIn({required String email, required String password}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      if (credential.user != null) {
        final userDoc = await _firestore.collection('users').doc(credential.user!.uid).get();
        if (!userDoc.exists) {
          await _createFirestoreUserDoc(credential.user!, credential.user!.email ?? email, "LAD User");
        }
      }
      return credential;
    } catch (e) {
      rethrow;
    }
  }

  /// Registra un nuevo usuario y vincula referidos si existen.
  Future<String> signUp({required String email, required String password, required String name}) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;

      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        String? referredBy = prefs.getString('pending_messenger_invitation');
        
        // 1. Creamos el documento primero
        await _createFirestoreUserDoc(user, email, name, invitingId: referredBy);
        
        // 2. ⏱️ VÁLVULA DE SEGURIDAD LAD: Aseguramos persistencia antes de liberar el flujo
        debugPrint("⏱️ SISTEMA LAD: Sincronizando perfiles...");
        await _firestore.collection('users').doc(user.uid).get(const GetOptions(source: Source.server));

        if (referredBy != null) {
          await prefs.remove('pending_messenger_invitation');
        }
      }
      return "SUCCESS";
    } catch (e) {
      return e.toString();
    }
  }

  /// Crea el esquema de datos inicial para un nuevo usuario en Firestore.
  Future<void> _createFirestoreUserDoc(User user, String email, String name, {String? invitingId}) async {
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': email,
      'displayName': name,
      'role': 'CLIENT',
      'createdAt': FieldValue.serverTimestamp(), // 🚀 Cambio a ServerTimestamp para mayor precisión
      'invitingMessengerId': invitingId,
      'linkedMessengerIds': invitingId != null ? [invitingId] : [],
      'availableServices': [],
      'isMessengerActive': false,
      'setupComplete': false,
      'maxRadiusMiles': 5.0,
      'maxDropoffRadiusMiles': 5.0,
      'subscriptionStatus': 'none',
      'subscriptionType': null,
      'photoURL': null,
      
      // ✨ ESTRATEGIA LAD DIGITAL SYSTEMS LLC - CAMPOS INICIALES
      'recruitedBy': invitingId != null ? 'driver_invite' : 'organic',
      'driverCategory': invitingId != null ? 'direct_network' : null,
      'hasBeenCountedForBonus': false,
      'monthlyDirectNetworkCount': 0,
      'monthlyBagReferralCount': 0,
      'monthlyClientReferralCount': 0,
      'lastBonusMonthEarned': null,
    }, SetOptions(merge: true)); // 🛡️ BLINDAJE LAD: Evita borrar el token si se guardó milisegundos antes
  }

  /// Finaliza la configuración inicial asignando el rol seleccionado.
  Future<void> completeFirstTimeSetup({required String role}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'role': role,
        'setupComplete': true,
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  /// Activa el modo driver con un plan específico y radio.
  Future<String> activateAndSwitchToDriver({required String planType, required double radius}) async {
    final user = _auth.currentUser;
    if (user == null) return "AUTH_ERROR";
    try {
      // 1. Actualizar perfil a Driver
      await _firestore.collection('users').doc(user.uid).set({
        'role': 'MESSENGER',
        'subscriptionType': planType,
        'subscriptionStatus': 'active',
        'maxRadiusMiles': radius,
        'maxDropoffRadiusMiles': planType == 'pro' ? 120.0 : radius,
        'isMessengerActive': true,
        'setupComplete': true,
      }, SetOptions(merge: true));

      // 2. Ejecutar lógica de Bonos si es referido por otro driver
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final String? inviterId = userDoc.data()?['invitingMessengerId'];
      final bool alreadyCounted = userDoc.data()?['hasBeenCountedForBonus'] ?? false;

      if (inviterId != null && !alreadyCounted) {
        // Llamamos al UserService para procesar el reclutamiento táctico
        await _userService.processReferralBonus(inviterId, user.uid);
      }

      return "SUCCESS";
    } catch (e) {
      return e.toString();
    }
  }

  /// Cambia el rol del usuario actual entre CLIENT y MESSENGER.
  Future<String> switchUserRole({required String newRole}) async {
    final user = _auth.currentUser;
    if (user == null) return "AUTH_ERROR";
    try {
      final Map<String, dynamic> updateData = {'role': newRole};
      if (newRole == 'CLIENT') updateData['isMessengerActive'] = false;
      await _firestore.collection('users').doc(user.uid).set(updateData, SetOptions(merge: true));
      return "SUCCESS";
    } catch (e) {
      return e.toString();
    }
  }

  /// ELIMINACIÓN TÁCTICA DE CUENTA
  Future<String> deleteUserAccount() async {
    final user = _auth.currentUser;
    if (user == null) return "NO_USER";

    try {
      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();
      return "SUCCESS";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return "REAUTH_NEEDED";
      }
      return e.message ?? "Error desconocido";
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
