import 'package:flutter/material.dart';

class FavoritesView extends StatelessWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 100), // Push the search bar down mimicking mockup
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'O que precisas?',
                  hintStyle: TextStyle(
                    color: Color(0xFFB0B0B0), 
                    fontSize: 16,
                  ),
                  prefixIcon: null,
                  suffixIcon: Icon(Icons.search, color: Colors.black, size: 26),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
