import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http; 
import 'dart:convert';

  final String baseUrl = 'https://group-one-backend-1076960172153.us-central1.run.app';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

Future<void> userPost({
  required String uuid,
  required String idToken,
  required String email,
  required String firstName,
  required String lastName,
  required String imgUrl,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/public.user/$uuid'),
    headers: {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'img_url': imgUrl,
    }),
  );

  
  Future<Map<String, dynamic>?> userGet() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user signed in');
    final idToken = await user.getIdToken();
    final uuid = user.uid;

    final response = await http.get(
      Uri.parse('$baseUrl/public.user/$uuid'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> userList = jsonDecode(response.body);
      if (userList.isNotEmpty) {
        return userList[0] as Map<String, dynamic>;
      }
      return null;
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to fetch user data: ${response.body}');
    }
  }


  if (response.statusCode != 200) {
    throw Exception('Failed to send user data: ${response.body}');
  }
}

Future<void> userPatch({
  required String uuid,
  required String idToken,
  String? email,
  String? firstName,
  String? lastName,
  String? imgUrl,
}) async {
  // Build the data map with only non-null fields
  final Map<String, dynamic> data = {};
  if (email != null) data['email'] = email;
  if (firstName != null) data['first_name'] = firstName;
  if (lastName != null) data['last_name'] = lastName;
  if (imgUrl != null) data['img_url'] = imgUrl;

  if (data.isEmpty) {
    throw Exception('No data provided for update.');
  }

  final response = await http.patch(
    Uri.parse('$baseUrl/public.user/$uuid'),
    headers: {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(data),
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to update user data: ${response.body}');
  }
}

Future<void> signInWithGitHub() async {
  try {
    // Trigger the GitHub sign-in flow
    final UserCredential userCredential = await _auth.signInWithProvider(GithubAuthProvider());

    // The user is now signed in
    print('GitHub Sign-in successful: ${userCredential.user}');
  } on FirebaseAuthException catch (e) {
    throw Exception('GitHub Sign-in failed: ${e.message}');
  }
}


  Future<void> signInAnonymously() async {
    try {
      await _auth.signInAnonymously();
    } catch (e) {
      throw Exception('Anonymous sign-in failed: $e');
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e));
    } catch (e) {
      throw Exception('Email sign-in failed: $e');
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e));
    } catch (e) {
      throw Exception('Email sign-up failed: $e');
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google Sign-In canceled');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
    } catch (e) {
      throw Exception('Google Sign-In failed: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await GoogleSignIn().signOut(); 
    } catch (e) {
      throw Exception('Sign-out failed: $e');
    }
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'The email is already in use.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'weak-password':
        return 'The password is too weak.';
      default:
        return e.message ?? 'An error occurred.';
    }
  }


}