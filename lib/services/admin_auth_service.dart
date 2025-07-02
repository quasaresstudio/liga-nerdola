import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Login com verificação no Firestore
  Future<User?> login(String email, String senha) async {
    final UserCredential cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: senha,
    );

    final uid = cred.user?.uid;
    if (uid == null) {
      throw FirebaseAuthException(code: 'no-uid', message: 'Usuário sem UID');
    }

    // Verifica se há algum admin com esse UID
    final query = await _db
        .collection('admin_users')
        .where('uid', isEqualTo: uid)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw FirebaseAuthException(code: 'not-admin', message: 'Acesso negado');
    }

    return cred.user;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
}
