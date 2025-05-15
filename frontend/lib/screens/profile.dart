import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:group_1_project_2/auth.dart';

class ProfileSettingScreen extends StatefulWidget {
  const ProfileSettingScreen({super.key});

  @override
  State<ProfileSettingScreen> createState() => _ProfileSettingScreenState();
}

class _ProfileSettingScreenState extends State<ProfileSettingScreen> {
  // API URL - your actual API URL
  final String baseUrl = 'https://group-one-backend-1076960172153.us-central1.run.app';
  
  // Use your existing auth service
  final _authService = AuthService();
  
  File? _image;
  String? _imageUrl;
  final _picker = ImagePicker();
  bool _isLoading = true;
  String? _userId;

  // Controllers for form fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Get user email from shared preferences
  Future<String?> _getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }

  // Save user email to shared preferences
  Future<void> _saveUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email);
  }

  // Get user ID from shared preferences
  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  // Save user ID to shared preferences
  Future<void> _saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
  }

  // Get user data from the server
  Future<Map<String, dynamic>?> _getUserByEmail(String email) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/user/$email'));
      
      if (response.statusCode == 200) {
        final List<dynamic> userList = jsonDecode(response.body);
        if (userList.isNotEmpty) {
          return userList[0];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Update user profile on the server
  Future<bool> _updateUserProfile(String userId, String? newEmail, String? newImg) async {
    try {
      final Map<String, dynamic> data = {};
      
      if (newEmail != null) {
        data['new_email'] = newEmail;
      }
      
      if (newImg != null) {
        data['new_img'] = newImg;
      }
      
      final response = await http.patch(
        Uri.parse('$baseUrl/user/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current Firebase user from your auth service
      final User? currentUser = _authService.currentUser;
      
      if (currentUser != null) {
        // Use Firebase user data
        if (mounted) {
          setState(() {
            _emailController.text = currentUser.email ?? '';
            _userId = currentUser.uid;
            
            // Try to get display name, or fetch from backend if not available
            if (currentUser.displayName != null && currentUser.displayName!.isNotEmpty) {
              _nameController.text = currentUser.displayName!;
            } else {
              // Fetch additional user data from your backend
              _getUserByEmail(currentUser.email!).then((userData) {
                if (userData != null && mounted) {
                  setState(() {
                    final firstName = userData['first_name'] ?? '';
                    final lastName = userData['last_name'] ?? '';
                    _nameController.text = '$firstName $lastName'.trim();
                    _imageUrl = userData['img_url'];
                  });
                }
              });
            }
            
            // Save the user ID for future use
            _saveUserId(currentUser.uid);
            if (currentUser.email != null) {
              _saveUserEmail(currentUser.email!);
            }
          });
        }
      } else {
        // Original code for fetching user data from your backend
        final email = await _getUserEmail();
        
        if (email != null) {
          // Fetch user data from the server
          final userData = await _getUserByEmail(email);
          
          if (userData != null && mounted) {
            setState(() {
              // Split the name into first and last name
              final firstName = userData['first_name'] ?? '';
              final lastName = userData['last_name'] ?? '';
              _nameController.text = '$firstName $lastName'.trim();
              _emailController.text = userData['email'] ?? '';
              _imageUrl = userData['img_url'];
              _userId = userData['user_id'];
              
              // Save the user ID for future use
              if (_userId != null) {
                _saveUserId(_userId!);
              }
            });
          }
        }
      }
    } catch (e) {
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load profile data')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _getImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null && mounted) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // Navigate to change password screen
  void _navigateToChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChangePasswordScreen(),
      ),
    );
  }

  Future<void> _saveProfile() async {
    // Show loading indicator
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Regular profile update
      String userId;
      
      // Try to get user ID from Firebase first
      final User? currentUser = _authService.currentUser;
      if (currentUser != null) {
        userId = currentUser.uid;
      } else {
        userId = _userId ?? await _getUserId() ?? '';
      }
      
      if (userId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User ID not found. Please log in again.')),
          );
        }
        return;
      }
      
      // Get the values from the form
      final email = _emailController.text.trim();
      final name = _nameController.text.trim();
      
      String? imageUrl;
      if (_image != null) {
        // In a real implementation, you would upload the image to storage
        // and get the URL back
        imageUrl = 'https://example.com/placeholder.jpg';
      }
      
      // Update Firebase user profile if available
      final User? user = _authService.currentUser;
      if (user != null) {
        try {
          // Update display name
          await user.updateDisplayName(name);
          
          // Update email if it changed
          if (email != user.email) {
            // Use verifyBeforeUpdateEmail instead of updateEmail
            await user.verifyBeforeUpdateEmail(email);
            
            // Show a message to the user that they need to verify their email
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Verification email sent. Please check your inbox to complete email update.')),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error updating Firebase profile: ${e.toString()}')),
            );
          }
          return;
        }
      }
      
      // Update profile in your backend
      final success = await _updateUserProfile(userId, email, imageUrl);
      
      if (success) {
        // Update the stored email if it changed
        final currentEmail = await _getUserEmail();
        if (email != currentEmail) {
          await _saveUserEmail(email);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile saved successfully!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save profile')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred while saving profile: ${e.toString()}')),
        );
      }
    } finally {
      // Hide loading indicator
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.deepPurple,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator()
              : SingleChildScrollView(
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
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          Text(
                            'Profile Setting',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 30),
                          
                          // Profile image
                          GestureDetector(
                            onTap: _getImage,
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.grey[700] : Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: _image != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(90),
                                      child: Image.file(
                                        _image!,
                                        width: 180,
                                        height: 180,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : _imageUrl != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(90),
                                          child: Image.network(
                                            _imageUrl!,
                                            width: 180,
                                            height: 180,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Center(
                                                child: Text(
                                                  '+',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: isDarkMode ? Colors.white70 : Colors.black54,
                                                    fontSize: 32,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            '+',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: isDarkMode ? Colors.white70 : Colors.black54,
                                              fontSize: 32,
                                            ),
                                          ),
                                        ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          
                          // Profile edit form
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Name:',
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
                                  controller: _nameController,
                                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                    hintText: 'Enter your name',
                                    hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black38),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Email:',
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
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                    hintText: 'Enter your email',
                                    hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black38),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          
                          // Save Profile Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Save',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white70 : Colors.black54,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Change Password Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.lock, color: Colors.white),
                              label: const Text(
                                'Change Password',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: _navigateToChangePassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[700],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
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
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}

// Separate Change Password Screen
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
  bool _isLoading = false;
  String _errorMessage = '';

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
      final User? user = _authService.currentUser;
      
      if (user == null || user.email == null) {
        setState(() {
          _errorMessage = 'User not found. Please sign in again.';
          _isLoading = false;
        });
        return;
      }
      
      // Create credentials with current password
      final AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      
      // Re-authenticate user
      await user.reauthenticateWithCredential(credential);
      
      // Change password
      await user.updatePassword(newPassword);
      
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        title: const Text('Change Password', style: TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
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
                    
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withAlpha(26), // Using withAlpha instead of withOpacity
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
                        onPressed: _isLoading ? null : _changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Change Password',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
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
    super.dispose();
  }
}