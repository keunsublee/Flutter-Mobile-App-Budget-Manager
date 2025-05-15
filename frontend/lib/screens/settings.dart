import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:group_1_project_2/theme.dart';
import 'package:group_1_project_2/screens/profile.dart';
import 'package:group_1_project_2/auth.dart';
import 'package:group_1_project_2/screens/signin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:group_1_project_2/screens/budget.dart';

final _authService = AuthService();

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = false;
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
  }

  void _toggleNotifications() {
    setState(() {
      _notificationsEnabled = !_notificationsEnabled;
    });
  }

  // Helper method to format date as month/day/year
  String _formatDate(DateTime date) {
    return "${date.month}/${date.day}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
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
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
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

                      Padding(
                        padding: const EdgeInsets.only(left: 40.0),
                        child: Text(
                          _currentUser != null
                              ? 'Signed in as: ${_currentUser!.email ?? _currentUser!.uid}'
                              : 'Not signed in',
                          style: const TextStyle(fontSize: 25),
                        ),
                      ),
                      const SizedBox(height:20),

                      // Personal Details Section
                      Row(
                        children: [
                          Icon(Icons.person, size: 28, color: Theme.of(context).iconTheme.color),
                          const SizedBox(width: 12),
                          Text(
                            'Personal Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      
                      // Account Creation Date with the actual date in month/day/year format
                      Padding(
                        padding: const EdgeInsets.only(left: 40.0),
                        child: Row(
                          children: [
                            Text(
                              'Account Creation Date: ',
                              style: TextStyle(
                                fontSize: 18,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                            Text(
                              _currentUser != null && _currentUser!.metadata.creationTime != null
                                  ? _formatDate(_currentUser!.metadata.creationTime!)
                                  : _formatDate(DateTime.now()),
                              style: TextStyle(
                                fontSize: 18,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                          ],
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
                        child: Padding(
                          padding: const EdgeInsets.only(left: 40.0),
                          child: Text(
                            'Edit Profile',
                            style: TextStyle(
                              fontSize: 18,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Preferences Section
                      Row(
                        children: [
                          Icon(Icons.settings, size: 28, color: Theme.of(context).iconTheme.color),
                          const SizedBox(width: 12),
                          Text(
                            'Preferences',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      
                      // Notifications with toggle switch
                      Padding(
                        padding: const EdgeInsets.only(left: 40.0, right: 20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Notifications',
                              style: TextStyle(
                                fontSize: 18,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                            // Custom toggle switch for notifications
                            GestureDetector(
                              onTap: _toggleNotifications,
                              child: Container(
                                width: 60,
                                height: 30,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: Colors.black,
                                ),
                                child: Stack(
                                  children: [
                                    AnimatedPositioned(
                                      duration: const Duration(milliseconds: 200),
                                      left: _notificationsEnabled ? 30 : 0,
                                      child: Container(
                                        width: 30,
                                        height: 30,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFF36859A), // Teal/blue color
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),
                      
                      // Theme with toggle switch
                      Padding(
                        padding: const EdgeInsets.only(left: 40.0, right: 20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Theme',
                              style: TextStyle(
                                fontSize: 18,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                            // Custom toggle switch for theme
                            GestureDetector(
                              onTap: () {
                                themeProvider.toggleTheme();
                              },
                              child: Container(
                                width: 60,
                                height: 30,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: Colors.black,
                                ),
                                child: Stack(
                                  children: [
                                    AnimatedPositioned(
                                      duration: const Duration(milliseconds: 200),
                                      left: isDarkMode ? 30 : 0,
                                      child: Container(
                                        width: 30,
                                        height: 30,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFF36859A), // Teal/blue color
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                       // Auth Buttons, put any other settings above
                      const SizedBox(height: 50),                    
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 60.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SignInScreen(
                                      onSignIn: _getCurrentUser, 
                                    ),
                                  ),
                                );
                              },
                              child: const Text('Sign In'),
                            ),
                            ElevatedButton(
                              onPressed: _signOut,
                              style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 205, 140, 135)),
                              child: const Text('Sign Out'),
                            ),
                          ],
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
       
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[900] : const Color(0xFFF8F8F8),
            border: Border(
              top: BorderSide(
                color: Colors.grey.withValues(alpha: 77, red: 158, green: 158, blue: 158),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(Icons.home,
                    size: 26, color: Theme.of(context).iconTheme.color),
                onPressed: () {}, // leave as-is or wire up later
              ),
              IconButton(
                icon: Icon(Icons.add,
                    size: 26, color: Theme.of(context).iconTheme.color),
                 onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BudgetScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.settings,
                    size: 26, color: Theme.of(context).iconTheme.color),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}