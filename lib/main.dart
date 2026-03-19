import 'dart:ui';
import 'package:flutter/material.dart';

void main() {
  runApp(const FourUApp());
}

class FourUApp extends StatelessWidget {
  const FourUApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '4U',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            color: const Color(0xFFF8F8F8),
            // Note: To add the topographical pattern, you would add a DecorationImage here:
            // decoration: const BoxDecoration(
            //   image: DecorationImage(
            //     image: AssetImage('assets/topography.png'),
            //     opacity: 0.1,
            //     fit: BoxFit.cover,
            //   ),
            // ),
          ),

          // Search Bar at the top
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'O que precisas?',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(left: 20.0, right: 10.0),
                      child: Text(''), // Spacer to match padding if needed
                    ),
                    suffixIcon: Padding(
                      padding: EdgeInsets.only(right: 15.0),
                      child: Icon(Icons.search, color: Colors.black54),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),
          ),

          // Floating Bottom Navigation Bar
          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(Icons.person_outline),
                  _buildNavItem(Icons.favorite_border),
                  _buildNavItem(Icons.home_outlined),
                  _buildNavItem(Icons.calendar_today_outlined),
                  _buildNavItem(Icons.settings_outlined),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon) {
    return IconButton(
      icon: Icon(icon, color: Colors.black, size: 28),
      onPressed: () {},
    );
  }
}
