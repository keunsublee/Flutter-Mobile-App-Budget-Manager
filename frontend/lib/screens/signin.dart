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
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  bool isSignUpMode = false;
  User? _currentUser;
  bool get isEmailUser => _currentUser?.email != null;

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
      widget.onSignIn();
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

  void _signInWithGitHub() async {
  try {
    await _authService.signInWithGitHub();
    _getCurrentUser();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Signed in with GitHub successfully!')),
    );
    Navigator.pop(context);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('GitHub Sign-in failed: $e')),
    );
  }
}

void _signUpWithEmail() async {
  try {
    await _authService.signUpWithEmail(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();

    if (user != null && idToken != null) {
      await _authService.userPost(
        uuid: user.uid,
        idToken: idToken,
        email: _emailController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        imgUrl: '',
      );
    }

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
            if (isEmailUser)
              ElevatedButton(
                onPressed: () async {
                  try {
                    await FirebaseAuth.instance.sendPasswordResetEmail(
                      email: _currentUser!.email!,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password reset email sent!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
                child: const Text('Reset Password'),
              ),
              ElevatedButton(
                onPressed: _signOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Sign Out'),
              ),
              const Divider(height: 30, thickness: 1),
            ],
            if (_currentUser == null || !isEmailUser) ...[
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
              if (isSignUpMode) ...[
                TextField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name'),
                ),
                TextField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                ),
              ],
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: isSignUpMode ? _signUpWithEmail : _signInWithEmail,
                child: Text(
                  isSignUpMode ? 'Create Account' : 'Email Login',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isSignUpMode = !isSignUpMode;
                  });
                },
                child: Text(
                  isSignUpMode ? 'Email Login' : 'Sign Up',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ],
            ElevatedButton(
              onPressed: _signInWithGoogle,
              child: const Text('Google Login',
              style: TextStyle(fontSize: 20)),
            ),
            ElevatedButton(
              onPressed: _signInWithGitHub,
              child: const Text(
                'GitHub Login',
                style: TextStyle(fontSize: 20),
              ),
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