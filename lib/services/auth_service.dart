import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();
  factory AuthService() => instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Future<void>? _initTask;

  Future<void> _ensureInitialized() async {
    _initTask ??= _googleSignIn.initialize();
    try {
      await _initTask;
    } catch (_) {
      _initTask = null;
      rethrow;
    }
  }

  //permite que AuthWrapper escuche si la sesion esta activa (streaming)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  //obtiene usuario actual
  User? get currentUser => _auth.currentUser;

  //solo permite iniciar sesion con google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      await _ensureInitialized();

      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (ex) {
      if (ex.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _ensureInitialized();
      await _googleSignIn.signOut();
    } finally {
      await _auth.signOut();
    }
  }
}
