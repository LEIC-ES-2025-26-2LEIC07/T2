import 'package:flutter/material.dart';
import 'login_page.dart';

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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 2;

  void _onNavItemTapped(int index) {
    setState(() => _selectedIndex = index);

    if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            color: const Color(0xFFF8F8F8),
          ),

          // Search Bar at the top
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
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
                      child: Text(''),
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
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(Icons.person_outline, 0),
                  _buildNavItem(Icons.favorite_border, 1),
                  _buildNavItem(Icons.home_outlined, 2),
                  _buildNavItem(Icons.calendar_today_outlined, 3),
                  _buildNavItem(Icons.settings_outlined, 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    return IconButton(
      icon: Icon(
        icon,
        color: isSelected ? Colors.black : Colors.black45,
        size: isSelected ? 30 : 26,
      ),
      onPressed: () => _onNavItemTapped(index),
    );
  }
}