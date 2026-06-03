import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<UserCredential> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  static Future<UserCredential> signUp(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  static Future<void> sendEmailVerification() =>
      _auth.currentUser!.sendEmailVerification();

  static Future<bool> isEmailVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  static Future<void> signOut() => _auth.signOut();

  static Future<void> updateDisplayName(String name) async {
    await _auth.currentUser!.updateDisplayName(name);
    await _auth.currentUser!.reload();
  }

  static Future<UserCredential> signInWithGoogle() async {
    final googleUser = await GoogleSignIn(
      clientId: '130637803692-p9qbueo75kmdob83da937ke1c6ieo9cp.apps.googleusercontent.com',
    ).signIn();
    if (googleUser == null) throw 'Google sign-in was cancelled.';
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  static Future<UserCredential> signInWithApple() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );
    final userCred = await _auth.signInWithCredential(oauthCredential);
    // Apple only sends the name on first sign-in — persist it immediately
    final fullName = [
      appleCredential.givenName,
      appleCredential.familyName,
    ].where((n) => n != null && n.isNotEmpty).join(' ');
    if (fullName.isNotEmpty &&
        (userCred.user?.displayName == null ||
            userCred.user!.displayName!.isEmpty)) {
      await userCred.user?.updateDisplayName(fullName);
    }
    return userCred;
  }
}
