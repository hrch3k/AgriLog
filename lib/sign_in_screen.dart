import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'sign_up_screen.dart';
import 'home_screen.dart'; // Import the home screen with DataScreen
import 'main.dart'; // Import AuthWrapper
import 'package:firebase_auth/firebase_auth.dart'; // Import for FirebaseAuthException
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv for environment variables

class SignInPage extends StatefulWidget {
  final bool
      showEmailNotVerified; // To show the email verification message if needed

  SignInPage(
      {this.showEmailNotVerified = false}); // Default to false if not passed
  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>(); // Key to validate the form

  // Controllers to capture email and password input
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final AuthService _authService = AuthService(); // Instance of AuthService

  String _errorMessage = ''; // Variable to store error messages
  bool _isLoading = false; // Variable to handle loading state
  bool _passwordVisible = false; // Variable to toggle password visibility

  @override
  void dispose() {
    // Dispose controllers when the widget is disposed to prevent memory leaks
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Sign-in function that handles Firebase authentication
  void _signIn() async {
    if (_formKey.currentState!.validate()) {
      // Form is valid, proceed with signing in
      setState(() {
        _isLoading = true;
        _errorMessage = ''; // Reset error message
      });
      try {
        // Attempt to sign in using email and password
        UserCredential userCredential = await _authService.signInWithEmail(
          _emailController.text.trim(), // Email input
          _passwordController.text.trim(), // Password input
        );

        User? user = userCredential.user; // Get the signed-in user

        // Check if we are in development mode or production
        bool isDev = dotenv.env['IS_DEV'] == 'true';

        // If user is signed in and email verification is required in production
        if (user != null) {
          if (!isDev && !user.emailVerified) {
            // If in production and email not verified, show dialog to verify email
            _showEmailNotVerifiedDialog();
          } else {
            // User is signed in and verified or in dev mode
            if (mounted) {
              // Instead of navigating directly to DataScreen, navigate back to AuthWrapper to handle the admin check
              Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (context) =>
                    MyApp(), // Re-navigate to the app (AuthWrapper will be called)
              ));
            }
          }
        }
      } on FirebaseAuthException catch (e) {
        // Catch FirebaseAuthException and show friendly error message
        print(e.toString());
        setState(() {
          _errorMessage = _getFriendlyErrorMessage(e);
        });
      } catch (e) {
        // Catch any other exceptions and display a generic error message
        print(e.toString());
        setState(() {
          _errorMessage = 'An unexpected error occurred. Please try again.';
        });
      } finally {
        // Stop the loading indicator
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      // Form is not valid, show error message
      setState(() {
        _errorMessage = 'Please fix the errors above.';
      });
    }
  }

  // Show a dialog when the email is not verified
  void _showEmailNotVerifiedDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Email Not Verified'),
          content: Text('Please verify your email before proceeding.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('OK'),
            ),
            TextButton(
              onPressed: () async {
                // Resend email verification link
                User? user = FirebaseAuth.instance.currentUser;
                if (user != null && !user.emailVerified) {
                  await user.sendEmailVerification();
                  // Show a message to the user that the email has been sent
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Verification email sent!'),
                  ));
                }
                Navigator.of(context)
                    .pop(); // Close the dialog after sending the email
              },
              child: Text('Resend Verification Email'),
            ),
          ],
        );
      },
    );
  }

  // Friendly error messages for FirebaseAuthException
  String _getFriendlyErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This user has been disabled.';
      default:
        return 'An unknown error occurred.';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set form width based on screen size (responsive)
    double screenWidth = MediaQuery.of(context).size.width;
    double formWidth = screenWidth > 600 ? 400 : screenWidth * 0.85;

    return Scaffold(
      appBar: AppBar(
        title: Text('Sign In'),
        centerTitle: true, // Center the title in the AppBar
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: formWidth,
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey, // Assign the form key to manage validation
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo image
                  Image.asset(
                    'assets/logo.png',
                    height: 100,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Please sign in to AgriLog.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 30),
                  // Email input field
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    // Email field validation
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null; // Validation passed
                    },
                  ),
                  SizedBox(height: 20),
                  // Password input field
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: Icon(Icons.lock),
                      suffixIcon: IconButton(
                        // Toggle password visibility
                        icon: Icon(
                          _passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _passwordVisible = !_passwordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    obscureText: !_passwordVisible,
                    // Hide or show password text
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null; // Validation passed
                    },
                  ),
                  SizedBox(height: 10),
                  // Show error message if any
                  _errorMessage.isNotEmpty
                      ? Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.red),
                        )
                      : SizedBox.shrink(),
                  SizedBox(height: 20),
                  // Sign in button with loading state
                  SizedBox(
                    width: double.infinity,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _isLoading ? null : _signIn,
                          // Disable button if loading
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          child: Text(
                            'Sign In',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                        // Show loading indicator if signing in
                        if (_isLoading)
                          CircularProgressIndicator(
                            color: Colors.white,
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  // Button to navigate to sign-up screen
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SignUpPage()),
                            );
                          },
                    child: Text(
                      'Don\'t have an account? Sign Up',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
