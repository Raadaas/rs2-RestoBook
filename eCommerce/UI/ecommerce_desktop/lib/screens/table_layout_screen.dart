import 'package:flutter/material.dart';

class TableLayoutScreen extends StatelessWidget {
  final int restaurantId;

  const TableLayoutScreen({
    super.key,
    required this.restaurantId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: const Center(
        child: Text(
          'Table Layout Screen',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

