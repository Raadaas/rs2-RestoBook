import 'package:ecommerce_mobile/providers/product_provider.dart';
import 'package:ecommerce_mobile/providers/restaurant_provider.dart';
import 'package:ecommerce_mobile/providers/cuisine_type_provider.dart';
import 'package:ecommerce_mobile/providers/menu_item_provider.dart';
import 'package:ecommerce_mobile/providers/reservation_provider.dart';
import 'package:ecommerce_mobile/providers/favorite_provider.dart';
import 'package:ecommerce_mobile/providers/review_provider.dart';
import 'package:ecommerce_mobile/providers/restaurant_gallery_provider.dart';
import 'package:ecommerce_mobile/providers/notification_provider.dart';
import 'package:ecommerce_mobile/screens/login_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const Color _brown = Color(0xFF8B7355);

void main() {
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider<ProductProvider>(
        create: (context) => ProductProvider()),
    ChangeNotifierProvider<RestaurantProvider>(
        create: (context) => RestaurantProvider()),
    ChangeNotifierProvider<CuisineTypeProvider>(
        create: (context) => CuisineTypeProvider()),
    ChangeNotifierProvider<MenuItemProvider>(
        create: (context) => MenuItemProvider()),
    ChangeNotifierProvider<ReservationProvider>(
        create: (context) => ReservationProvider()),
    ChangeNotifierProvider<FavoriteProvider>(
        create: (context) => FavoriteProvider()),
    ChangeNotifierProvider<ReviewProvider>(
        create: (context) => ReviewProvider()),
    Provider<RestaurantGalleryProvider>(
        create: (_) => RestaurantGalleryProvider()),
    ChangeNotifierProvider<NotificationProvider>(
        create: (_) => NotificationProvider()),
  ], child: const MyLoginApp()));
}

class MyLoginApp extends StatelessWidget {
  const MyLoginApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _brown,
          primary: _brown,
          brightness: Brightness.light,
          surface: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8F8F8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade400!, width: 1),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade400!),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade400!),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _brown,
            foregroundColor: Colors.white,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _brown,
            side: BorderSide(color: _brown),
          ),
        ),
      ),
      home: LoginPage(),
    );
  }
}
