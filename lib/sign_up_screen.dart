import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import for FirebaseAuthException
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv for environment variables
import 'sign_in_screen.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final AuthService _authService = AuthService();
  String _errorMessage = '';
  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      try {
        // Sign up the user with Firebase Authentication
        UserCredential userCredential = await _authService.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        User? user = userCredential.user;

        // Add user data to Firestore if sign-up is successful
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'email': _emailController.text.trim(),
            'nickname': 'User ${user.uid.substring(0, 6)}',
            // Optional: Use part of user ID as a default nickname
            'createdAt': FieldValue.serverTimestamp(),
          });

          // Use dotenv to check if email verification should be skipped
          bool isDev = dotenv.env['IS_DEV'] == 'true';

          if (!isDev) {
            // In production, send verification email
            await user.sendEmailVerification();
            _showVerifyEmailDialog();
          } else {
            // Skip verification and navigate to Sign-In page in development
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => SignInPage()),
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        String error = _getFriendlyErrorMessage(e);
        setState(() {
          _errorMessage = error;
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'An unexpected error occurred. Please try again.';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _errorMessage = 'Please fix the errors above.';
      });
    }
  }

  void _showVerifyEmailDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Verify Your Email'),
          content: Text(
              'A verification link has been sent to your email. Please verify your email before logging in.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          SignInPage()), // Directly navigate to SignInPage
                );
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String _getFriendlyErrorMessage(FirebaseAuthException e) {
    String errorMessage = '';
    switch (e.code) {
      case 'email-already-in-use':
        errorMessage = 'This email is already in use.';
        break;
      case 'invalid-email':
        errorMessage = 'Invalid email address.';
        break;
      case 'weak-password':
        errorMessage = 'The password is too weak.';
        break;
      default:
        errorMessage = 'An unknown error occurred.';
    }
    return errorMessage;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double formWidth = screenWidth > 600 ? 400 : screenWidth * 0.85;

    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: formWidth,
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset('assets/logo.png', height: 100),
                  SizedBox(height: 20),
                  Text(
                    'Ustvarite nov račun',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
                  ),
                  SizedBox(height: 30),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                      suffixIcon: IconButton(
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters long';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _confirmPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _confirmPasswordVisible = !_confirmPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    obscureText: !_confirmPasswordVisible,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  _errorMessage.isNotEmpty
                      ? Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.red),
                        )
                      : SizedBox.shrink(),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _isLoading ? null : _signUp,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          child: Text(
                            'Sign Up',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                        if (_isLoading)
                          CircularProgressIndicator(
                            color: Colors.white,
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: Text(
                      'Already have an account? Sign In',
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
