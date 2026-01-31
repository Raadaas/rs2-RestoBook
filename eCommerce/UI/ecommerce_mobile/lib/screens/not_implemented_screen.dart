import 'package:flutter/material.dart';

class NotImplementedScreen extends StatelessWidget {
  final String title;

  const NotImplementedScreen({super.key, this.title = 'Not implemented'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF8B7355),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text(
          'Not implemented yet',
          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
        ),
      ),
    );
  }
}
