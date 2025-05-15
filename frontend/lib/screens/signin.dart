import 'package:flutter/material.dart';
import 'package:group_1_project_2/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';

final _authService = AuthService();

class SignInScreen extends StatefulWidget {
  final VoidCallback onSignIn;

  const SignInScreen({super.key, required this.onSignIn});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  void _getCurrentUser() {
    setState(() {
      _currentUser = _authService.currentUser;
    });
  }
   void _signOut() async {
    await _authService.signOut();
    _getCurrentUser();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Signed out successfully!')),
    );
  }

 void _signInWithEmail() async {
    try {
      await _authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      _getCurrentUser();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed in successfully!')),
      );
      Navigator.pop(context); 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-in failed: $e')),
      );
    }
  }

  void _signInWithGoogle() async {
    try {
      await _authService.signInWithGoogle();
      _getCurrentUser(); 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed in with Google successfully!')),
      );
      Navigator.pop(context); 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-in failed: $e')),
      );
    }
  }

void _signUpWithEmail() async {
    try {
      await _authService.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully!')),
      );
      Navigator.pop(context); 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-up failed: $e')),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_currentUser != null) ...[
              Text(
                'Signed in as: ${_currentUser!.email ?? _currentUser!.uid}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _signOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Sign Out'),
              ),
              const Divider(height: 30, thickness: 1),
            ],
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _signInWithEmail,
              child: const Text(
              'Email Login',
              style: TextStyle(fontSize: 20), 
              ),
            ),
            ElevatedButton(
              onPressed: _signInWithGoogle,
              child: const Text('Google Login',
              style: TextStyle(fontSize: 20)),
            ),
            ElevatedButton(
              onPressed: _signUpWithEmail,
              child: const Text('Email Sign Up',
              style: TextStyle(fontSize: 20)),
            ),

            const SizedBox(height: 100),
            const Text(
              'By signing in, you agree to our Terms of Service and Privacy Policy.\nContact support at fluttergroup6@gmail.com',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize:15),
            ),
            const Spacer(),
            Padding(
              padding: EdgeInsets.only(bottom: 60.0),
              child: const Text(
              'The Flutter Budget App Group',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
      
            
          ],
        ),
      ),
    );
  }
}