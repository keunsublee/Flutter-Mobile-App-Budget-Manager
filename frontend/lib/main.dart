import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 
import 'package:group_1_project_2/screens/budget.dart';
import 'package:group_1_project_2/screens/settings.dart';
import 'package:group_1_project_2/screens/profile.dart';
import 'package:group_1_project_2/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Budget App',
      debugShowCheckedModeBanner: false,

      // Light theme
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: Colors.deepPurple,
          secondary: Colors.deepPurple,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.grey[200],
        inputDecorationTheme: InputDecorationTheme(
          fillColor: Colors.grey[300],
        ),
        useMaterial3: true,
      ),

      // Dark theme
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Colors.deepPurple,
          secondary: Colors.deepPurple,
          surface: Colors.grey[900]!,
        ),
        scaffoldBackgroundColor: const Color(0xFF393438),
        cardColor: Colors.grey[800],
        inputDecorationTheme: InputDecorationTheme(
          fillColor: Colors.grey[700],
        ),
        useMaterial3: true,
      ),

      // Toggle between light/dark based on provider
      themeMode:
          themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // Named routes
      initialRoute: '/budget',
      routes: {
        '/budget': (_) => const BudgetScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/profile': (_) => const ProfileSettingScreen(),
      },
    );
  }
}
