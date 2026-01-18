import 'package:flutter/material.dart';

class RestaurantInfoScreen extends StatelessWidget {
  final int restaurantId;

  const RestaurantInfoScreen({
    super.key,
    required this.restaurantId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Info'),
      ),
      body: const Center(
        child: Text(
          'Not implemented yet',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
  }
}
