import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../data/local/hive_service.dart';
import '../data/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService})
    : _authService = authService ?? AuthService() {
    _guestMode = HiveService.getGuestMode() || !_authService.isAvailable;
    if (_guestMode) {
      _initialized = true;
    }
    _subscription = _authService.authStateChanges().listen((user) {
      _user = user;
      if (user != null && _guestMode) {
        _guestMode = false;
        HiveService.setGuestMode(false);
      }
      _initialized = true;
      notifyListeners();
    });
  }

  final AuthService _authService;
  StreamSubscription<User?>? _subscription;

  User? _user;
  bool _guestMode = false;
  bool _initialized = false;
  bool _busy = false;
  String? _error;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isGuest => _guestMode && _user == null;
  bool get canUseApp => isAuthenticated || _guestMode;
  bool get googleSignInAvailable => _authService.isAvailable;
  bool get initialized => _initialized;
  bool get busy => _busy;
  String? get error => _error;
  String? get displayName => _user?.displayName;
  String? get email => _user?.email;
  String? get photoUrl => _user?.photoURL;

  Future<void> continueAsGuest() async {
    _error = null;
    _guestMode = true;
    await HiveService.setGuestMode(true);
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    if (_busy) return false;
    _busy = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signInWithGoogle();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Falha ao entrar com Google.';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    if (_busy) return;
    _busy = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signOut();
      _guestMode = true;
      await HiveService.setGuestMode(true);
    } on AuthException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Falha ao sair da conta.';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
