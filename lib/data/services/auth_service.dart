import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

const String superAdminEmail = 'sheldonramu8@gmail.com';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  GoogleSignIn get _googleSignIn => GoogleSignIn.instance;
  bool _googleInitialized = false;

  bool get isSuperAdminEmail => _auth.currentUser?.email == superAdminEmail;

  String _resolveRole(String requestedRole) {
    final email = _auth.currentUser?.email ?? '';
    return email == superAdminEmail ? 'admin' : requestedRole;
  }

  String _resolveStatus() {
    final email = _auth.currentUser?.email ?? '';
    return email == superAdminEmail ? 'active' : 'pending';
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await _googleSignIn.initialize();
    _googleInitialized = true;
  }

  Future<UserModel?> getCurrentUserModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
    String? county,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await credential.user!.sendEmailVerification();

    final userModel = UserModel(
      uid: credential.user!.uid,
      fullName: fullName,
      phone: phone,
      email: email,
      role: _resolveRole(role),
      status: _resolveStatus(),
      county: county,
    );

    await _firestore.collection('users').doc(credential.user!.uid).set(userModel.toMap());

    return credential;
  }

  Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      final userModel = UserModel(
        uid: uid,
        fullName: 'User',
        phone: '',
        email: credential.user!.email ?? email,
        role: _resolveRole('owner'),
        status: _resolveStatus(),
        isVerified: credential.user!.emailVerified,
      );
      await _firestore.collection('users').doc(uid).set(userModel.toMap());
    } else {
      final updates = <String, dynamic>{'lastLoginAt': Timestamp.now()};
      if (credential.user!.email == superAdminEmail) {
        updates['role'] = 'admin';
        updates['status'] = 'active';
      }
      await _firestore.collection('users').doc(uid).update(updates);
    }

    return credential;
  }

  Future<UserCredential> signInWithGoogle() async {
    await _ensureGoogleInitialized();

    final googleUser = await _googleSignIn.authenticate();
    final auth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: auth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        final email = user.email ?? '';
        final role = email == superAdminEmail ? 'admin' : 'tenant';
        final status = email == superAdminEmail ? 'active' : 'pending';
        final userModel = UserModel(
          uid: user.uid,
          fullName: user.displayName ?? 'User',
          phone: user.phoneNumber ?? '',
          email: email,
          role: role,
          status: status,
          photoUrl: user.photoURL,
        );
        await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
      } else {
        final updates = <String, dynamic>{'lastLoginAt': Timestamp.now()};
        if (user.email == superAdminEmail) {
          updates['role'] = 'admin';
          updates['status'] = 'active';
        }
        await _firestore.collection('users').doc(user.uid).update(updates);
      }
    }

    return userCredential;
  }

  Future<void> signInWithPhone({
    required String phone,
    required Function(String verificationId, int? forceResendToken) codeSent,
    required Function(FirebaseAuthException error) verificationFailed,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: verificationFailed,
      codeSent: (verificationId, forceResentToken) {
        codeSent(verificationId, forceResentToken);
      },
      codeAutoRetrievalTimeout: (verificationId) {},
    );
  }

  Future<UserCredential> verifyPhoneCode({
    required String verificationId,
    required String smsCode,
    required String fullName,
    required String role,
    String? county,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        final userModel = UserModel(
          uid: user.uid,
          fullName: fullName,
          phone: user.phoneNumber ?? '',
          email: user.email ?? '',
          role: role,
          status: 'active',
          county: county,
        );
        await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
      }
    }

    return userCredential;
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    await _firestore.collection('users').doc(user.uid).update(data);
  }

  Future<void> updateStatus(String uid, String status) async {
    await _firestore.collection('users').doc(uid).update({'status': status});
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    if (_googleInitialized) {
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
  }

  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return user.emailVerified;
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.read(authServiceProvider).authStateChanges;
});

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  return ref.read(authServiceProvider).getCurrentUserModel();
});
