import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/inspector_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference<Map<String, dynamic>> _usersCollection =
      FirebaseFirestore.instance.collection('users');

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<InspectorUser> signUp({
    required String email,
    required String password,
    required String companyId,
    UserRole role = UserRole.inspector,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = InspectorUser(uid: cred.user!.uid, role: role, companyId: companyId);
    await _usersCollection.doc(user.uid).set(user.toMap());
    return user;
  }

  Future<void> signIn({required String email, required String password}) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();

  Future<InspectorUser?> fetchUser(String uid) async {
    final snap = await _usersCollection.doc(uid).get();
    if (!snap.exists) return null;
    return InspectorUser.fromMap(uid, snap.data()!);
  }
}
