import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 
import 'screens/settings.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the current theme from the provider
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      title: 'Budget App',
      debugShowCheckedModeBanner: false,
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
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Colors.deepPurple,
          secondary: Colors.deepPurple,
          surface: Colors.grey[900]!, 
        ),
        scaffoldBackgroundColor: Colors.black,
        cardColor: Colors.grey[800],
        inputDecorationTheme: InputDecorationTheme(
          fillColor: Colors.grey[700],
        ),
        useMaterial3: true,
      ),
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const SettingsScreen(),
    );
  }
}