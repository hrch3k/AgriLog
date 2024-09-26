import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'home_screen.dart'; // Ensure this contains DataScreen
import 'sign_in_screen.dart'; // Your sign-in screen
import 'package:firebase_auth/firebase_auth.dart'; // Firebase authentication
import 'package:flutter_dotenv/flutter_dotenv.dart'; // For loading environment variables
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore for accessing user data

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
  // Function to check if the user is an admin by querying Firestore
  Future<bool> _checkIfAdmin(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return userDoc['isAdmin'] ??
            false; // Return true if isAdmin is true, otherwise false
      }
      return false;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      // Listen to auth state changes
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show loading indicator while Firebase is connecting
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          User? user = snapshot.data;

          bool isDev = dotenv.env['IS_DEV'] == 'true';

          // If the user is logged in and either verified or we're in dev mode
          if (user != null && (user.emailVerified || isDev)) {
            // Check if the logged-in user is an admin
            return FutureBuilder<bool>(
              future: _checkIfAdmin(user.uid),
              builder: (context, adminSnapshot) {
                if (adminSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (adminSnapshot.hasData) {
                  bool isAdmin = adminSnapshot.data ?? false;
                  // After admin check, rebuild with updated isAdmin flag
                  return DataScreen(
                      isAdmin: isAdmin); // Pass isAdmin flag to DataScreen
                }

                return SignInPage(); // In case of an error or no data, show sign-in page
              },
            );
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
