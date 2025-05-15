import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:group_1_project_2/auth.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _authService = AuthService();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _verificationCodeController = TextEditingController();
  
  bool _isLoading = false;
  bool _isVerificationSent = false;
  String _errorMessage = '';
  String? _verificationId;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  void _getCurrentUser() {
    _currentUser = _authService.currentUser;
    if (_currentUser == null) {
      setState(() {
        _errorMessage = 'User not found. Please sign in again.';
      });
    }
  }

  Future<void> _sendPasswordChangeVerification() async {
    // Validate passwords match
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'New passwords do not match';
      });
      return;
    }
    
    if (_currentPasswordController.text.isEmpty || _newPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both current and new password';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Get current user
      if (_currentUser == null || _currentUser!.email == null) {
        setState(() {
          _errorMessage = 'User not found. Please sign in again.';
          _isLoading = false;
        });
        return;
      }
      
      // First verify the current password is correct
      final AuthCredential credential = EmailAuthProvider.credential(
        email: _currentUser!.email!,
        password: _currentPasswordController.text,
      );
      
      // Re-authenticate user to verify current password
      await _currentUser!.reauthenticateWithCredential(credential);
      
      // Send password reset email as verification
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _currentUser!.email!);
      
      if (mounted) {
        setState(() {
          _isVerificationSent = true;
          _errorMessage = '';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A verification email has been sent. Please check your inbox and follow the link to verify your password change.'),
            duration: Duration(seconds: 8),
          ),
        );
      }
    } catch (e) {
      setState(() {
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'wrong-password':
              _errorMessage = 'Current password is incorrect';
              break;
            case 'too-many-requests':
              _errorMessage = 'Too many requests. Please try again later.';
              break;
            default:
              _errorMessage = 'Authentication error: ${e.message}';
          }
        } else {
          _errorMessage = 'An error occurred. Please try again.';
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _changePassword() async {
    // Validate passwords match
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'New passwords do not match';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final currentPassword = _currentPasswordController.text;
      final newPassword = _newPasswordController.text;
      
      if (currentPassword.isEmpty || newPassword.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter both current and new password';
          _isLoading = false;
        });
        return;
      }
      
      // Get current user
      if (_currentUser == null || _currentUser!.email == null) {
        setState(() {
          _errorMessage = 'User not found. Please sign in again.';
          _isLoading = false;
        });
        return;
      }
      
      // Create credentials with current password
      final AuthCredential credential = EmailAuthProvider.credential(
        email: _currentUser!.email!,
        password: currentPassword,
      );
      
      // Re-authenticate user
      await _currentUser!.reauthenticateWithCredential(credential);
      
      // Change password
      await _currentUser!.updatePassword(newPassword);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'wrong-password':
              _errorMessage = 'Current password is incorrect';
              break;
            case 'weak-password':
              _errorMessage = 'New password is too weak (at least 6 characters required)';
              break;
            case 'requires-recent-login':
              _errorMessage = 'Please sign out and sign in again before changing your password';
              break;
            default:
              _errorMessage = 'Authentication error: ${e.message}';
          }
        } else {
          _errorMessage = 'An error occurred. Please try again.';
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildVerificationSentUI() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Icon(
          Icons.email_outlined,
          size: 80,
          color: isDarkMode ? Colors.white70 : Colors.black54,
        ),
        const SizedBox(height: 20),
        Text(
          'Verification Email Sent',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'We\'ve sent a verification email to ${_currentUser?.email}. Please check your inbox and follow the link to reset your password.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Back to Profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: _sendPasswordChangeVerification,
          child: const Text(
            'Resend Verification Email',
            style: TextStyle(
              color: Colors.deepPurple,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordChangeUI() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Center(
          child: Icon(
            Icons.lock,
            size: 80,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 30),
        
        Text(
          'Current Password:',
          style: TextStyle(
            fontSize: 16,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _currentPasswordController,
            obscureText: true,
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              hintText: 'Enter your current password',
              hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black38),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'New Password:',
          style: TextStyle(
            fontSize: 16,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _newPasswordController,
            obscureText: true,
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              hintText: 'Enter your new password',
              hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black38),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Confirm New Password:',
          style: TextStyle(
            fontSize: 16,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _confirmPasswordController,
            obscureText: true,
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              hintText: 'Confirm your new password',
              hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black38),
            ),
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendPasswordChangeVerification,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Verify Password Change',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        title: const Text('Change Password', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(30),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withAlpha(26),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _errorMessage,
                            style: TextStyle(
                              color: Colors.red[400],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    
                    _isVerificationSent
                        ? _buildVerificationSentUI()
                        : _buildPasswordChangeUI(),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }
}