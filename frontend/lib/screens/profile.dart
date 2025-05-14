import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfileSettingScreen extends StatefulWidget {
  const ProfileSettingScreen({super.key});

  @override
  State<ProfileSettingScreen> createState() => _ProfileSettingScreenState();
}

class _ProfileSettingScreenState extends State<ProfileSettingScreen> {
  File? _image;
  final _picker = ImagePicker();

  // Controllers for form fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _getImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _saveProfile() {
    // You can replace this with actual save logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved!')),
    );
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
                              hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black38),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Current Email:',
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
                              hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black38),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Password:',
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
                            controller: _passwordController,
                            obscureText: true,
                            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                              hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black38),
                            ),
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}