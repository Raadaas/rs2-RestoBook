import 'package:ecommerce_mobile/providers/product_provider.dart';
import 'package:ecommerce_mobile/providers/restaurant_provider.dart';
import 'package:ecommerce_mobile/providers/cuisine_type_provider.dart';
import 'package:ecommerce_mobile/providers/menu_item_provider.dart';
import 'package:ecommerce_mobile/providers/reservation_provider.dart';
import 'package:ecommerce_mobile/providers/favorite_provider.dart';
import 'package:ecommerce_mobile/providers/review_provider.dart';
import 'package:ecommerce_mobile/screens/login_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  ], child: const MyLoginApp()));
}

class MyLoginApp extends StatelessWidget {
  const MyLoginApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: Colors.blue, primary: Colors.red),
      ),
      home: LoginPage(),
    );
  }
}
