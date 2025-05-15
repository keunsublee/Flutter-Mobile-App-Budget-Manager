import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:group_1_project_2/auth.dart';
import 'package:group_1_project_2/screens/passwordChange.dart';

class ApiService {
  final String baseUrl = 'https://group-one-backend-1076960172153.us-central1.run.app';
  final http.Client _client;
  
  ApiService({http.Client? client}) : _client = client ?? http.Client();
  
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      print('📱 API: Fetching user data for email: $email');
      final response = await _client.get(Uri.parse('$baseUrl/user/$email'));
      
      print('📱 API: Server response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200) {
        final List<dynamic> userList = jsonDecode(response.body);
        if (userList.isNotEmpty) {
          print('📱 API: User found: ${userList[0]}');
          return userList[0];
        }
      }
      print('📱 API: User not found');
      return null;
    } catch (e) {
      print('📱 API: Error fetching user data: $e');
      return null;
    }
  }
  
  Future<bool> updateUserProfile(String userId, {String? newEmail, String? newImgUrl}) async {
    try {
      final Map<String, dynamic> data = {};
      
      if (newEmail != null) {
        data['new_email'] = newEmail;
      }
      
      if (newImgUrl != null) {
        data['new_img'] = newImgUrl;
      }
      
      if (data.isEmpty) {
        print('📱 API: No data to update');
        return false;
      }
      
      print('📱 API: Updating profile for user $userId with data: $data');
      
      final response = await _client.patch(
        Uri.parse('$baseUrl/user/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      
      print('📱 API: Server response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode != 200) {
        print('📱 API: Failed to update profile: ${response.body}');
      }
      
      return response.statusCode == 200;
    } catch (e) {
      print('📱 API: Exception during profile update: $e');
      return false;
    }
  }
  
  Future<bool> createUser(String email, String firstName, String lastName, String? imgUrl) async {
    try {
      final Map<String, dynamic> userData = {
        'first_name': firstName,
        'last_name': lastName,
        'img_url': imgUrl ?? '',
      };
      
      print('📱 API: Creating user with data: $userData');
      
      final response = await _client.post(
        Uri.parse('$baseUrl/user/$email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );
      
      print('📱 API: Server response: ${response.statusCode} - ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('📱 API: Error creating user: $e');
      return false;
    }
  }
}

class ProfileSettingScreen extends StatefulWidget {
  final ApiService? apiService;
  
  const ProfileSettingScreen({super.key, this.apiService});

  @override
  State<ProfileSettingScreen> createState() => _ProfileSettingScreenState();
}

class _ProfileSettingScreenState extends State<ProfileSettingScreen> {
  late final ApiService _apiService;
  final _authService = AuthService();

  File? _image;
  String? _imageUrl;
  final _picker = ImagePicker();
  bool _isLoading = true;
  String? _userId;
  DateTime? _createdOn;
  
  bool _isSocialSignIn = false;
  String _socialProvider = '';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? ApiService();
    _loadUserData();
  }

  Future<String?> _getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }

  Future<void> _saveUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email);
  }

  Future<void> _saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
  }

  bool _checkSocialSignIn(User user) {
    final providerData = user.providerData;
    if (providerData.isEmpty) return false;
    
    for (final provider in providerData) {
      final providerId = provider.providerId;
      if (providerId == 'google.com') {
        _socialProvider = 'Google';
        return true;
      } else if (providerId == 'github.com') {
        _socialProvider = 'GitHub';
        return true;
      }
    }
    
    return false;
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final User? currentUser = _authService.currentUser;
      
      if (currentUser != null) {
        _isSocialSignIn = _checkSocialSignIn(currentUser);
        print('User signed in with social provider: $_isSocialSignIn');
        if (_isSocialSignIn) {
          print('Social provider: $_socialProvider');
        }
        
        if (mounted) {
          setState(() {
            _emailController.text = currentUser.email ?? '';
            
            if (currentUser.displayName != null && currentUser.displayName!.isNotEmpty) {
              _nameController.text = currentUser.displayName!;
            }
          });
        }
        
        final userData = await _apiService.getUserByEmail(currentUser.email!);
        if (userData != null && mounted) {
          setState(() {
            _userId = userData['user_id'];
            print('Loaded user_id from GCP: $_userId');
            
            if (_userId != null) {
              _saveUserId(_userId!);
            }
            
            if (_nameController.text.isEmpty) {
              final firstName = userData['first_name'] ?? '';
              final lastName = userData['last_name'] ?? '';
              _nameController.text = '$firstName $lastName'.trim();
            }
            
            _imageUrl = userData['img_url'];
            
            if (userData['created_on'] != null) {
              _createdOn = DateTime.parse(userData['created_on']);
            }
          });
        } else {
          print('User not found in GCP database');
          
          if (currentUser.email != null) {
            final nameParts = currentUser.displayName?.split(' ') ?? ['New', 'User'];
            final firstName = nameParts.first;
            final lastName = nameParts.length > 1 ? nameParts.last : '';
            
            final success = await _apiService.createUser(
              currentUser.email!,
              firstName,
              lastName,
              currentUser.photoURL,
            );
            
            if (success) {
              print('Created new user in GCP database');
              await _loadUserData();
              return;
            } else {
              print('Failed to create user in GCP database');
            }
          }
        }
        
        if (currentUser.email != null) {
          _saveUserEmail(currentUser.email!);
        }
      } else {
        final email = await _getUserEmail();
        
        if (email != null) {
          final userData = await _apiService.getUserByEmail(email);
          
          if (userData != null && mounted) {
            setState(() {
              final firstName = userData['first_name'] ?? '';
              final lastName = userData['last_name'] ?? '';
              _nameController.text = '$firstName $lastName'.trim();
              _emailController.text = userData['email'] ?? '';
              _imageUrl = userData['img_url'];
              _userId = userData['user_id'];
              
              if (userData['created_on'] != null) {
                _createdOn = DateTime.parse(userData['created_on']);
              }
              
              if (_userId != null) {
                _saveUserId(_userId!);
              }
            });
          }
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
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
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800, // Limit image size to avoid large base64 strings
      maxHeight: 800,
      imageQuality: 70, // Compress image to reduce size
    );

    if (pickedFile != null && mounted) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _navigateToChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChangePasswordScreen(),
      ),
    );
  }
  
  void _showSocialSignInInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("$_socialProvider Sign-In"),
        content: Text(
          "You're signed in with $_socialProvider. Your name, email, and password are managed by $_socialProvider and cannot be changed here.\n\n"
          "To change these details, please visit your $_socialProvider account settings."
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<String?> _convertImageToBase64() async {
    if (_image == null) return null;
    
    try {
      // Read the image file as bytes
      final bytes = await _image!.readAsBytes();
      
      // Check file size before encoding (to avoid very large strings)
      if (bytes.length > 1024 * 1024) { // If larger than 1MB
        print('Image too large: ${bytes.length} bytes');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image is too large. Please select a smaller image.')),
          );
        }
        return null;
      }
      
      // Convert to base64
      final base64Image = base64Encode(bytes);
      
      // Create a data URL
      return 'data:image/jpeg;base64,$base64Image';
    } catch (e) {
      print('Error converting image to base64: $e');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final User? currentUser = _authService.currentUser;
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not found. Please log in again.')),
          );
        }
        return;
      }
      
      if (_isSocialSignIn) {
        String? imageUrl;
        if (_image != null) {
          // Convert image to base64
          imageUrl = await _convertImageToBase64();
          
          if (imageUrl == null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to process image')),
              );
            }
            setState(() {
              _isLoading = false;
            });
            return;
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No changes to save')),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }
        
        String userId;
        if (_userId == null) {
          print('User ID not found in state, fetching from GCP');
          final userData = await _apiService.getUserByEmail(currentUser.email!);
          
          if (userData == null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User not found in database. Please contact support.')),
              );
            }
            setState(() {
              _isLoading = false;
            });
            return;
          }
          
          userId = userData['user_id'];
          _userId = userId;
          await _saveUserId(userId);
        } else {
          userId = _userId!;
        }
        
        final success = await _apiService.updateUserProfile(
          userId,
          newImgUrl: imageUrl,
        );
        
        if (success) {
          // Update the local state with the new image URL
          setState(() {
            _imageUrl = imageUrl;
            _image = null; // Clear the selected image
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile image updated successfully!')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to update profile image')),
            );
          }
        }
      } else {
        final email = _emailController.text.trim();
        final name = _nameController.text.trim();
        
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please enter a valid email address')),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }
        
        String? imageUrl;
        if (_image != null) {
          // Convert image to base64
          imageUrl = await _convertImageToBase64();
          
          if (imageUrl == null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to process image')),
              );
            }
            setState(() {
              _isLoading = false;
            });
            return;
          }
        }
        
        String userId;
        if (_userId == null) {
          print('User ID not found in state, fetching from GCP');
          final userData = await _apiService.getUserByEmail(currentUser.email!);
          
          if (userData == null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User not found in database. Please contact support.')),
              );
            }
            setState(() {
              _isLoading = false;
            });
            return;
          }
          
          userId = userData['user_id'];
          _userId = userId;
          await _saveUserId(userId);
        } else {
          userId = _userId!;
        }
        
        print('Using user ID for update: $userId');
        
        bool firebaseUpdateSuccess = true;
        try {
          await currentUser.updateDisplayName(name);
          
          if (email != currentUser.email) {
            await currentUser.verifyBeforeUpdateEmail(email);
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Verification email sent. Please check your inbox to complete email update.')),
              );
            }
          }
        } catch (e) {
          firebaseUpdateSuccess = false;
          print('Firebase update error: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error updating Firebase profile: ${e.toString()}')),
            );
          }
        }
        
        if (firebaseUpdateSuccess) {
          final success = await _apiService.updateUserProfile(
            userId,
            newEmail: email != currentUser.email ? email : null,
            newImgUrl: imageUrl,
          );
          
          if (success) {
            // Update the local state with the new image URL if it was changed
            if (imageUrl != null) {
              setState(() {
                _imageUrl = imageUrl;
                _image = null; // Clear the selected image
              });
            }
            
            if (email != currentUser.email) {
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
                const SnackBar(content: Text('Failed to save profile to server. Your Firebase profile was updated.')),
              );
            }
          }
        }
      }
    } catch (e) {
      print('Profile save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred while saving profile: ${e.toString()}')),
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
                          
                          if (_isSocialSignIn)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withAlpha(50),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Signed in with $_socialProvider',
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _showSocialSignInInfo,
                                      child: Text('Info'),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size(50, 30),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          
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
                                  : _imageUrl != null && _imageUrl!.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(90),
                                          child: _imageUrl!.startsWith('data:image/')
                                              ? Image.memory(
                                                  base64Decode(_imageUrl!.split(',')[1]),
                                                  width: 180,
                                                  height: 180,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    print('Error loading base64 image: $error');
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
                                                )
                                              : Image.network(
                                                  _imageUrl!,
                                                  width: 180,
                                                  height: 180,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    print('Error loading network image: $error');
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
                          
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Name:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDarkMode ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  if (_isSocialSignIn)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: Icon(
                                        Icons.lock,
                                        size: 16,
                                        color: isDarkMode ? Colors.white54 : Colors.black38,
                                      ),
                                    ),
                                ],
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
                                  readOnly: _isSocialSignIn,
                                  enabled: !_isSocialSignIn,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Text(
                                    'Email:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDarkMode ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  if (_isSocialSignIn)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: Icon(
                                        Icons.lock,
                                        size: 16,
                                        color: isDarkMode ? Colors.white54 : Colors.black38,
                                      ),
                                    ),
                                ],
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
                                  readOnly: _isSocialSignIn,
                                  enabled: !_isSocialSignIn,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          
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
                                _isSocialSignIn ? 'Save Profile Image' : 'Save',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white70 : Colors.black54,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          if (!_isSocialSignIn)
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
                          
                          if (_isSocialSignIn)
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.info_outline, color: Colors.white),
                                label: const Text(
                                  'Manage Account',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: _showSocialSignInInfo,
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
