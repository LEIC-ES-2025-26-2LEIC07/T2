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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: SizedBox.expand(),
      ),
    );
  }
}
