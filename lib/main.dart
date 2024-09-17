import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'home_screen.dart'; // Your main content screen
import 'sign_in_screen.dart'; // Your sign-in screen
import 'package:firebase_auth/firebase_auth.dart'; // Firebase authentication
import 'package:flutter_dotenv/flutter_dotenv.dart'; // For loading environment variables

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from the .env file
  await dotenv.load(fileName: "assets/.env");

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriLog',
      home: AuthWrapper(), // Use AuthWrapper to handle login state
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      // Listen to auth state changes
      builder: (context, snapshot) {
        // Debugging: Print whenever the auth state changes
        print('User state changed: ${snapshot.data}');

        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show loading indicator while Firebase is connecting
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          User? user = snapshot.data;

          // Check if we're in development mode, and optionally skip email verification
          bool isDev = dotenv.env['IS_DEV'] == 'true';

          // If the user is logged in and either verified or we're in dev mode
          if (user != null && (user.emailVerified || isDev)) {
            return DataScreen(); // Go to your main content screen (e.g., DataScreen)
          } else {
            // User is logged in but hasn't verified their email
            return SignInPage(showEmailNotVerified: true);
          }
        }

        // If no user is logged in, show the sign-in screen
        return SignInPage(showEmailNotVerified: false);
      },
    );
  }
}
