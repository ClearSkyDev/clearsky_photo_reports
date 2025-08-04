import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/inspector_user.dart';
import '../utils/logging.dart';
import 'audit_log_service.dart';

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
    logger().d('[AuthService] signUp email=$email, company=$companyId');
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user =
        InspectorUser(uid: cred.user!.uid, role: role, companyId: companyId);
    await _usersCollection.doc(user.uid).set(user.toMap());
    await AuditLogService()
        .logAction('sign_up', targetId: user.uid, targetType: 'user');
    return user;
  }

  Future<void> signIn({required String email, required String password}) async {
    logger().d('[AuthService] signIn email=$email');
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    await AuditLogService().logAction('login');
  }

  Future<void> sendSignInLink(String email, String url) {
    logger().d('[AuthService] sendSignInLink to $email');
    final settings = ActionCodeSettings(
      url: url,
      handleCodeInApp: true,
      iOSBundleId: 'com.clearsky.photoReports',
      androidPackageName: 'com.clearsky.photoReports',
      androidInstallApp: true,
      androidMinimumVersion: '21',
    );
    return _auth.sendSignInLinkToEmail(
        email: email, actionCodeSettings: settings);
  }

  Future<void> signInWithLink(String email, String link) {
    logger().d('[AuthService] signInWithLink for $email');
    return _auth.signInWithEmailLink(email: email, emailLink: link);
  }

  Future<void> sendPasswordReset(String email) {
    logger().d('[AuthService] sendPasswordReset to $email');
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() {
    logger().d('[AuthService] signOut');
    return _auth.signOut();
  }

  Future<InspectorUser?> fetchUser(String uid) async {
    logger().d('[AuthService] fetchUser $uid');
    final snap = await _usersCollection.doc(uid).get();
    if (!snap.exists) return null;
    return InspectorUser.fromMap(uid, snap.data()!);
  }
}
