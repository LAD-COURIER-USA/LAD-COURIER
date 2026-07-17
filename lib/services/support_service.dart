import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SupportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> sendTicket({
    required String subject,
    required String message,
    required String role,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _db.collection('support_tickets').add({
      'uid': user.uid,
      'email': user.email,
      'role': role,
      'subject': subject,
      'message': message,
      'status': 'PENDING',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
