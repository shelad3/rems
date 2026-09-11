import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/models/user_model.dart';

enum PhoneAuthStep { codeSent, autoSignedIn, failed }

final authProvider = ChangeNotifierProvider<AuthNotifier>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});

class AuthNotifier extends ChangeNotifier {
  final AuthService _authService;
  UserModel? _user;
  bool _loading = false;
  String? _error;
  String? _pendingVerificationId;

  AuthNotifier(this._authService);

  UserModel? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isAuthenticated => _authService.currentUser != null;
  bool get isPremium => _user?.subscriptionTier == 'premium';
  bool get isApproved => _user?.status == 'active';

  Future<void> loadUser() async {
    _loading = true;
    notifyListeners();
    try {
      _user = await _authService.getCurrentUserModel();
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
    String? county,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.registerWithEmail(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        role: role,
        county: county,
      );
      await loadUser();
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.loginWithEmail(email: email, password: password);
      await loadUser();
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.signInWithGoogle();
      await loadUser();
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyPhoneAndLogin({
    required String verificationId,
    required String smsCode,
    required String fullName,
    required String role,
    String? county,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.verifyPhoneCode(
        verificationId: verificationId,
        smsCode: smsCode,
        fullName: fullName,
        role: role,
        county: county,
      );
      await loadUser();
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<PhoneAuthStep> sendPhoneCode(String phone) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _authService.signInWithPhone(phone);
      if (result.error != null) {
        _error = result.error;
        _loading = false;
        notifyListeners();
        return PhoneAuthStep.failed;
      }
      if (result.autoSignedIn) {
        _pendingVerificationId = null;
        await loadUser();
        _loading = false;
        notifyListeners();
        return PhoneAuthStep.autoSignedIn;
      }
      _pendingVerificationId = result.verificationId;
      _loading = false;
      notifyListeners();
      return PhoneAuthStep.codeSent;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return PhoneAuthStep.failed;
    }
  }

  Future<bool> verifySmsCode(String code) async {
    final verificationId = _pendingVerificationId;
    if (verificationId == null) {
      _error = 'Verification expired. Request a new code.';
      return false;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.verifyPhoneCode(
        verificationId: verificationId,
        smsCode: code,
        fullName: '',
        role: 'tenant',
      );
      _pendingVerificationId = null;
      await loadUser();
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  String? get pendingVerificationId => _pendingVerificationId;

  Future<bool> sendPasswordReset(String email) async {
    try {
      await _authService.sendPasswordReset(email);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
