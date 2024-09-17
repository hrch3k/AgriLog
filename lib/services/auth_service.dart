import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign up with email and password, and send email verification
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send email verification
      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        await userCredential.user!.sendEmailVerification();
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'An unknown error occurred.';
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if the user's email is verified
      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        throw 'Please verify your email before logging in.';
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'An unknown error occurred.';
    }
  }

  // Check if the current user's email is verified
  bool isEmailVerified() {
    User? user = _auth.currentUser;
    return user != null && user.emailVerified;
  }

  // Sign out
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  // Resend email verification if needed
  Future<void> resendEmailVerification() async {
    User? user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }
}
