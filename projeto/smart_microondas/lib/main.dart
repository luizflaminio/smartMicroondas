// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(SmartMicroondasApp());
}

class SmartMicroondasApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Microondas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Colors
        primarySwatch: Colors.blue,
        primaryColor: Colors.blue[700],
        scaffoldBackgroundColor: Colors.grey[50],
        
        // Material 3
        useMaterial3: true,
        
        // AppBar
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        
        // Cards
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        
        // Buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            elevation: 2,
          ),
        ),
        
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        
        // Input
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        
        // Floating Action Button
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
        ),
        
        // Divider
        dividerTheme: DividerThemeData(
          thickness: 1,
          color: Colors.grey[300],
        ),
      ),
      home: MainScreen(),
    );
  }
}