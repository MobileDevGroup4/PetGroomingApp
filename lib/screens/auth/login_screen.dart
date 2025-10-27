import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/validators.dart';
import 'registration_screen.dart';
import 'password_reset_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../pages/StaffNavigation.dart';
import '../../main.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('Attempting login with email: ${_emailController.text.trim()}');
      
      // Store credentials
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      
      // Login without capturing result - this avoids the Pigeon type error
      FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      ).then((_) async {
        // Wait for auth state to update
        await Future.delayed(const Duration(milliseconds: 500));
        
        final user = FirebaseAuth.instance.currentUser;
        
        if (user == null) {
          throw Exception('Login failed: No user found');
        }
        
        print('Login successful: ${user.uid}');

        if (!mounted) return;

        try {
          // Check if user is staff
          final docSnapshot = await FirebaseFirestore.instance
              .collection('profiles')
              .doc(user.uid)
              .get();

          final isStaff = docSnapshot.exists && 
              (docSnapshot.data()?['isStaff'] as bool? ?? false);

          print('User is staff: $isStaff');

          if (!mounted) return;

          // Navigate to appropriate screen
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => isStaff 
                ? const StaffNavigation() 
                : const App(),
            ),
            (route) => false,
          ).then((_) {
            // Show success message AFTER navigation
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isStaff 
                    ? 'Welcome back, staff member!' 
                    : 'Login successful!'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          });
        } catch (e) {
          print('Error checking staff status: $e');
          if (mounted) {
            // Default to regular app if staff check fails
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => const App(),
              ),
              (route) => false,
            );
          }
        }
        
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }).catchError((error) {
        print('Login error: $error');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          String errorMessage = 'Login failed';
          
          if (error is FirebaseAuthException) {
            switch (error.code) {
              case 'user-not-found':
                errorMessage = 'No user found with this email';
                break;
              case 'wrong-password':
                errorMessage = 'Wrong password';
                break;
              case 'invalid-email':
                errorMessage = 'Invalid email address';
                break;
              case 'user-disabled':
                errorMessage = 'This user account has been disabled';
                break;
              case 'invalid-credential':
                errorMessage = 'Invalid email or password';
                break;
              case 'too-many-requests':
                errorMessage = 'Too many failed attempts. Please try again later';
                break;
              default:
                errorMessage = error.message ?? 'Login failed';
            }
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
      
    } catch (e) {
      print('Unexpected error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome Back'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),

              // App logo or title
              const Icon(Icons.pets, size: 80, color: Colors.amber),

              const SizedBox(height: 16),

              const Text(
                'Pet Grooming',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 48),

              // Email field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: validateEmail,
                enabled: !_isLoading,
              ),

              const SizedBox(height: 16),

              // Password field
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),

              const SizedBox(height: 8),

              // Forgot password link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading ? null : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PasswordResetScreen(),
                      ),
                    );
                  },
                  child: const Text('Forgot Password?'),
                ),
              ),

              const SizedBox(height: 16),

              // Login button
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Login', style: TextStyle(fontSize: 16)),
              ),

              const SizedBox(height: 24),

              // Don't have account link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?"),
                  TextButton(
                    onPressed: _isLoading ? null : () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const RegistrationScreen(),
                        ),
                      );
                    },
                    child: const Text('Register'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}