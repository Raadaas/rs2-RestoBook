import 'dart:convert';
import 'package:ecommerce_mobile/providers/auth_provider.dart';
import 'package:ecommerce_mobile/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LoginPage extends StatelessWidget {
  LoginPage({super.key});
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 400,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/background.png"),
                  fit: BoxFit.fill,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 30,
                    top: 0,
                    width: 120,
                    height: 160,
                    child: Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                            image: AssetImage("assets/images/light-1.png")),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 30,
                    top: 0,
                    width: 140,
                    height: 200,
                    child: Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                            image: AssetImage("assets/images/clock.png")),
                      ),
                    ),
                  ),
                  const Center(
                    child: Text(
                      "Login",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 45,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(color: Colors.grey[350]!)),
                    ),
                    child: TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "Username",
                        hintStyle: TextStyle(color: Colors.grey[350]),
                      ),
                    ),
                  ),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Password",
                      hintStyle: TextStyle(color: Colors.grey[350]),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromRGBO(143, 148, 251, 1),
                      Color.fromRGBO(143, 148, 251, 0.6),
                    ],
                  ),
                ),
                child: InkWell(
                  onTap: () async {
                    final username = _usernameController.text.trim();
                    final password = _passwordController.text.trim();

                    if (username.isEmpty) {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Error"),
                          content: const Text("Please enter username"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text("OK"),
                            ),
                          ],
                        ),
                      );
                      return;
                    }

                    try {
                      AuthProvider.username = username;
                      AuthProvider.password = password;

                      const baseUrl = String.fromEnvironment(
                        "baseUrl",
                        defaultValue: "http://10.0.2.2:5121/api/",
                      );
                      final url = Uri.parse("${baseUrl}users/login");
                      final requestBody =
                          jsonEncode({'username': username, 'password': password});

                      final response = await http.post(
                        url,
                        headers: {'Content-Type': 'application/json'},
                        body: requestBody,
                      );

                      if (response.statusCode == 200) {
                        final userData = jsonDecode(response.body);
                        if (userData['id'] != null) {
                          AuthProvider.userId = userData['id'] as int;
                        }
                        if (!context.mounted) return;
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (context) => const MainScreen()),
                        );
                      } else if (response.statusCode == 401) {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text("Error"),
                            content: const Text(
                                "Invalid username or password"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text("OK"),
                              ),
                            ],
                          ),
                        );
                      } else {
                        throw Exception("Login failed: ${response.statusCode}");
                      }
                    } on Exception catch (e) {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Error"),
                          content: Text(e
                              .toString()
                              .replaceAll('Exception: ', '')),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text("OK"),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  child: const Center(
                    child: Text(
                      "Login",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
