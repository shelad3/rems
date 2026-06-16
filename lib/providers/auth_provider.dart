import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../services/push_service.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestore = FirestoreService.instance;

  AuthStatus _status = AuthStatus.uninitialized;
  UserProfile? _user;
  bool _isLoading = false;
  String? _error;
  bool _registrationInProgress = false;
  bool _isProcessingAuth = false;
  StreamSubscription? _authSubscription;

  AuthStatus get status => _status;
  UserProfile? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    _authSubscription = _auth.authStateChanges().listen(
      _onAuthStateChanged,
      onError: (e) => debugPrint('Auth stream error: $e'),
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (_isProcessingAuth) return;
    _isProcessingAuth = true;
    try {
      if (firebaseUser == null) {
        _status = AuthStatus.unauthenticated;
        _user = null;
        notifyListeners();
        return;
      }

      final alreadyLoading = _isLoading;
      if (!alreadyLoading) {
        _isLoading = true;
        notifyListeners();
      }

      try {
        final firestoreData = await _firestore.getUser(firebaseUser.uid);
        if (firestoreData != null) {
          _user = UserProfile.fromFirestore(firestoreData, firebaseUser.uid);
        }

        if (_user == null && !_registrationInProgress) {
          final currentUser = _auth.currentUser;
          if (currentUser != null) {
            final data = {
              'email': currentUser.email ?? '',
              'name': currentUser.displayName ?? '',
              'phone': '',
              'role': 'tenant',
              'isActive': true,
              'createdAt': DateTime.now().toIso8601String(),
            };
            await _firestore.upsertUser(firebaseUser.uid, data);
            _user = UserProfile.fromFirestore(data, firebaseUser.uid);
          }
        }

        if (_user != null) {
          _status = AuthStatus.authenticated;
        } else if (!_registrationInProgress) {
          _status = AuthStatus.unauthenticated;
        }
      } catch (e) {
        debugPrint('Auth state error: $e');
        _status = AuthStatus.unauthenticated;
      }

      if (!alreadyLoading) {
        _isLoading = false;
        notifyListeners();
      } else {
        notifyListeners();
      }

      if (_user != null) {
        unawaited(_saveFcmToken(firebaseUser.uid));
      }
    } finally {
      _isProcessingAuth = false;
    }
  }

  Future<void> _saveFcmToken(String uid) async {
    final token = PushService.instance.fcmToken;
    if (token != null) {
      try {
        await _firestore.usersRef.doc(uid).set(
          {'fcmToken': token, 'updatedAt': DateTime.now().toIso8601String()},
          SetOptions(merge: true),
        );
      } catch (e) {
        debugPrint('FCM token save error: $e');
      }
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    _isProcessingAuth = true;
    notifyListeners();

    try {
      final result = await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
      final firebaseUser = result.user!;

      final firestoreData = await _firestore.getUser(firebaseUser.uid);
      if (firestoreData != null) {
        _user = UserProfile.fromFirestore(firestoreData, firebaseUser.uid);
      }

      if (_user != null) {
        _status = AuthStatus.authenticated;
        _isLoading = false;
        notifyListeners();
        unawaited(_saveFcmToken(firebaseUser.uid));
        return true;
      }

      _error = 'User profile not found. Try registering again.';
      _status = AuthStatus.unauthenticated;
      _isLoading = false;
      notifyListeners();
      return false;
    } on FirebaseAuthException catch (e) {
      _error = _getFirebaseErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Login failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    } finally {
      _isProcessingAuth = false;
    }
  }

  Future<bool> register(
      String email, String password, String name, String role,
      {String phone = '', int? ownerId, int? tenantId}) async {
    _isLoading = true;
    _error = null;
    _registrationInProgress = true;
    _isProcessingAuth = true;
    notifyListeners();

    User? createdUser;

    try {
      final result = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      final firebaseUser = result.user!;
      createdUser = firebaseUser;

      await firebaseUser.updateDisplayName(name);

      int? autoOwnerId = ownerId;
      int? autoTenantId = tenantId;

      if (role == 'owner' && autoOwnerId == null) {
        autoOwnerId = DateTime.now().millisecondsSinceEpoch;
        try {
          await _firestore.db.collection('owners').doc(autoOwnerId.toString()).set({
            'name': name,
            'email': email.trim(),
            'phone': phone,
            'address': '',
            'notes': 'Auto-created on registration',
            'lookingFor': '',
            'createdAt': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          debugPrint('Firestore owner sync error: $e');
        }
      }

      if (role == 'tenant' && autoTenantId == null) {
        autoTenantId = DateTime.now().millisecondsSinceEpoch;
        try {
          await _firestore.db.collection('tenants').doc(autoTenantId.toString()).set({
            'name': name,
            'email': email.trim(),
            'phone': phone,
            'createdAt': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          debugPrint('Firestore tenant sync error: $e');
        }
      }

      _user = UserProfile(
        uid: firebaseUser.uid,
        email: email.trim(),
        name: name,
        role: role,
        phone: phone,
        ownerId: autoOwnerId,
        tenantId: autoTenantId,
      );

      try {
        await _firestore.upsertUser(firebaseUser.uid, _user!.toFirestoreMap());
      } catch (e) {
        debugPrint('Firestore upsertUser error: $e');
      }

      _registrationInProgress = false;
      _isProcessingAuth = false;
      _status = AuthStatus.authenticated;
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _registrationInProgress = false;
      _isProcessingAuth = false;
      _status = AuthStatus.unauthenticated;
      _error = _getFirebaseErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _registrationInProgress = false;
      _isProcessingAuth = false;
      _status = AuthStatus.unauthenticated;
      _error = 'Registration failed: $e';
      debugPrint('Registration error: $e');
      _isLoading = false;

      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {
          await _auth.signOut();
        }
      }

      notifyListeners();
      return false;
    }
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
  }) async {
    if (_user == null) return;
    _isLoading = true;
    notifyListeners();

    _user = _user!.copyWith(name: name, phone: phone);
    try {
      await _firestore.updateUser(_user!.uid, {
        'name': name,
        'phone': phone,
      });
    } catch (e) {
      debugPrint('Firestore updateUser error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateRole(String role) async {
    if (_user == null) return;
    _user = _user!.copyWith(role: role);
    try {
      await _firestore.updateUser(_user!.uid, {'role': role});
    } catch (e) {
      debugPrint('Firestore updateRole error: $e');
    }
    notifyListeners();
  }

  Future<void> updateLink({int? ownerId, int? tenantId}) async {
    if (_user == null) return;
    _user = _user!.copyWith(ownerId: ownerId, tenantId: tenantId);
    notifyListeners();
  }

  Future<void> logout() async {
    await _auth.signOut();
    _status = AuthStatus.unauthenticated;
    _user = null;
    notifyListeners();
  }

  Future<void> reloadUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final data = await _firestore.getUser(currentUser.uid);
      if (data != null) {
        _user = UserProfile.fromFirestore(data, currentUser.uid);
      }
      notifyListeners();
    }
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-credential':
        return 'Invalid email or password';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password should be at least 6 characters';
      case 'invalid-email':
        return 'Invalid email address';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return code;
    }
  }
}
