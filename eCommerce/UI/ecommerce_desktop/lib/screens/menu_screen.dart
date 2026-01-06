import 'package:flutter/material.dart';

class MenuScreen extends StatelessWidget {
  final int restaurantId;

  const MenuScreen({
    super.key,
    required this.restaurantId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: const Center(
        child: Text(
          'Menu Screen',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

