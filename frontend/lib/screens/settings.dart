import 'package:flutter/material.dart';
import 'profile.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Purple header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 20, left: 20),
            color: const Color(0xFF673AB7), // Deep Purple
            child: const Text(
              'Settings',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          
          // Main content with rounded top corners
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFD3D3D3), // Light gray
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Personal Details Section
                      Row(
                        children: const [
                          Icon(Icons.person, size: 28),
                          SizedBox(width: 12),
                          Text(
                            'Personal Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      
                      // Account Creation Date
                      const Padding(
                        padding: EdgeInsets.only(left: 40.0),
                        child: Text(
                          'Account Creation Date',
                          style: TextStyle(
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      
                      // Edit Profile - Clickable
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfileSettingScreen(),
                            ),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(left: 40.0),
                          child: Text(
                            'Edit Profile',
                            style: TextStyle(
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Preferences Section
                      Row(
                        children: const [
                          Icon(Icons.settings, size: 28),
                          SizedBox(width: 12),
                          Text(
                            'Preferences',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      
                      // Notifications
                      const Padding(
                        padding: EdgeInsets.only(left: 40.0),
                        child: Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      
                      // Theme
                      const Padding(
                        padding: EdgeInsets.only(left: 40.0),
                        child: Text(
                          'Theme',
                          style: TextStyle(
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 60, // Smaller height for bottom navigation
        decoration: const BoxDecoration(
          color: Color(0xFFF8F8F8), // Very light gray/almost white
          border: Border(
            top: BorderSide(
              color: Colors.grey,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.home, size: 26),
              onPressed: () {
                // Navigate to home
              },
            ),
            IconButton(
              icon: const Icon(Icons.add, size: 26),
              onPressed: () {
                // Navigate to add
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings, size: 26, color: Color(0xFF673AB7)),
              onPressed: () {
                // Already on settings
              },
            ),
          ],
        ),
      ),
    );
  }
}