import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  const CustomSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
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
    );
  }
}
