import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF7FAF9),
      body: SafeArea(
        child: Center(
          child: Text(
            'Learning Path',
            style: TextStyle(
              color: Color(0xFF08100E),
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

