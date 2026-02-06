import 'package:ecommerce_mobile/app_styles.dart';
import 'package:flutter/material.dart';

class NotImplementedScreen extends StatelessWidget {
  final String title;

  const NotImplementedScreen({super.key, this.title = 'Not implemented'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(title, style: kScreenTitleStyle),
        backgroundColor: Colors.grey[50],
        elevation: 0,
        foregroundColor: const Color(0xFF333333),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(19),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: kScreenTitleUnderline(margin: EdgeInsets.zero),
          ),
        ),
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
