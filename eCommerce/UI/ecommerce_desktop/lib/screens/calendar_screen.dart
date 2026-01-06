import 'package:flutter/material.dart';

class CalendarScreen extends StatelessWidget {
  final int restaurantId;

  const CalendarScreen({
    super.key,
    required this.restaurantId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: const Center(
        child: Text(
          'Calendar Screen',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

