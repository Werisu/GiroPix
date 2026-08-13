import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Autenticação com Firebase + Google Sign-In.
class AuthService {
  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  bool _googleReady = false;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> ensureGoogleInitialized() async {
    if (_googleReady) return;
    await _googleSignIn.initialize();
    _googleReady = true;
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      await ensureGoogleInitialized();

      if (!_googleSignIn.supportsAuthenticate()) {
        throw AuthException(
          'Login com Google não é suportado neste dispositivo.',
        );
      }

      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw AuthException(
          'Não foi possível obter o token do Google. '
          'Verifique se o login Google está habilitado no Firebase.',
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      return await _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw AuthException('Login cancelado.');
      }
      if (e.code == GoogleSignInExceptionCode.clientConfigurationError) {
        throw AuthException(
          'Configuração do Google incompleta. '
          'Habilite o provedor Google em Firebase Authentication e confira o SHA-1.',
        );
      }
      throw AuthException(_mapGoogleError(e));
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    } on AuthException {
      rethrow;
    } catch (_) {
      throw AuthException('Falha ao entrar com Google. Tente novamente.');
    }
  }

  Future<void> signOut() async {
    try {
      await ensureGoogleInitialized();
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
    } catch (_) {
      await _auth.signOut();
    }
  }

  String _mapGoogleError(GoogleSignInException e) {
    switch (e.code) {
      case GoogleSignInExceptionCode.interrupted:
        return 'Login interrompido. Tente de novo.';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'Não foi possível abrir a tela de login do Google.';
      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'Provedor Google mal configurado no Firebase Console.';
      default:
        return e.description?.isNotEmpty == true
            ? e.description!
            : 'Erro no login com Google.';
    }
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'network-request-failed':
        return 'Sem conexão. Verifique a internet e tente de novo.';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      case 'account-exists-with-different-credential':
        return 'Já existe uma conta com este e-mail usando outro método.';
      case 'invalid-credential':
        return 'Credencial inválida. Tente entrar de novo.';
      case 'operation-not-allowed':
        return 'Login com Google não está habilitado no Firebase.';
      default:
        return e.message?.isNotEmpty == true
            ? e.message!
            : 'Falha na autenticação (${e.code}).';
    }
  }
}
