import 'dart:convert';
import 'package:ecommerce_mobile/providers/auth_provider.dart';
import 'package:ecommerce_mobile/providers/product_provider.dart';
import 'package:ecommerce_mobile/providers/restaurant_provider.dart';
import 'package:ecommerce_mobile/providers/cuisine_type_provider.dart';
import 'package:ecommerce_mobile/providers/menu_item_provider.dart';
import 'package:ecommerce_mobile/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

class LoginPage extends StatelessWidget {
  LoginPage({super.key});
  final TextEditingController _usernameController = new TextEditingController();
  final TextEditingController _passwordController = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: 400,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/background.png"),
                    fit: BoxFit.fill
                  )
                ),
                child: Stack(
                  children: [
                    Positioned(
                        left: 30,
                        top: 0,
                        width: 120,
                        height: 160,
                        child: Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(image: AssetImage("assets/images/light-1.png"))
                          ),
                        ),
                      ),
                      Positioned(
                        right: 30,
                        top: 0,
                        width: 140,
                        height: 200,
                        child: Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(image: AssetImage("assets/images/clock.png"))
                           
                          ),
                        ),
                      ),
                      Container(
                        child: Center(
                          child: Text("Login", style: TextStyle(color: Colors.white, fontSize: 45, fontWeight: FontWeight.bold),),
                        ),
                      )
                  ],
                ),
              ),
              Container(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[350]!))),
                        child: TextField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            
                            hintText: "Username",
                            hintStyle: TextStyle(color: Colors.grey[350])
                          ),
                        ),
                      ),
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Password",
                          hintStyle: TextStyle(color: Colors.grey[350])
                        ),
                      )
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: [
                        Color.fromRGBO(143, 148, 251, 1),
                      Color.fromRGBO(143, 148, 251, .6)
                      ]
                    )
                  ),
                  child: InkWell(
                    onTap: () async {
                      final username = _usernameController.text.trim();
                      final password = _passwordController.text.trim();
                    
                      if (username.isEmpty) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Error"),
                            content: const Text("Please enter username"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("OK")
                              )
                            ],
                          ),
                        );
                        return;
                      }

                      try {
                        // Store credentials for future API calls
                        AuthProvider.username = username;
                        AuthProvider.password = password;

                        // Call login endpoint
                        const baseUrl = String.fromEnvironment(
                          "baseUrl",
                          defaultValue: "http://10.0.2.2:5121/api/",
                        );
                        final url = Uri.parse("${baseUrl}users/login");
                        
                        final requestBody = jsonEncode({
                          'username': username,
                          'password': password,
                        });

                        final response = await http.post(
                          url,
                          headers: {
                            'Content-Type': 'application/json',
                          },
                          body: requestBody,
                        );

                        if (response.statusCode == 200) {
                          // Login successful
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) => const MainScreen())
                          );
                        } else if (response.statusCode == 401) {
                          // Invalid credentials
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Error"),
                              content: const Text("Invalid username or password"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("OK")
                                )
                              ],
                            ),
                          );
                        } else {
                          // Other error
                          throw Exception("Login failed: ${response.statusCode}");
                        }

                      } on Exception catch (e) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Error"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("OK")
                              )
                            ],
                            content: Text(e.toString().replaceAll('Exception: ', '')),
                          ),
                        );
                      }
                    },
                    child: Center(child: Text("Login", style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold),),),
                  ),
                ),
              )
            ],
          ),
      ),
    );
  }
}
