import 'package:flutter/material.dart';

/// Title style matching Help & Support screen - use for all screen titles
const TextStyle kScreenTitleStyle = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.bold,
  color: Color(0xFF333333),
);

const Color kBrownLight = Color(0xFFB39B7A);

/// Underline bar shown below screen titles - spans full width of screen
Widget kScreenTitleUnderline({EdgeInsetsGeometry? margin}) =>
    Container(
      height: 3,
      width: double.infinity,
      margin: margin ?? const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: kBrownLight,
        borderRadius: BorderRadius.circular(2),
      ),
    );
