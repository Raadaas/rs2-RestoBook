import 'dart:convert';
import 'dart:typed_data';

import 'package:ecommerce_mobile/providers/auth_provider.dart';
import 'package:ecommerce_mobile/screens/main_screen.dart';
import 'package:ecommerce_mobile/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

const Color _brown = Color(0xFF8B7355);
const Color _brownDark = Color(0xFF6B5344);

const String _baseUrl = String.fromEnvironment(
  "baseUrl",
  defaultValue: "http://10.0.2.2:5121/api/",
);

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _selectedImageDataUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 300,
        maxHeight: 300,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final decodedImage = img.decodeImage(bytes);
        if (decodedImage != null) {
          img.Image resized = decodedImage;
          if (decodedImage.width > 300 || decodedImage.height > 300) {
            if (decodedImage.width > decodedImage.height) {
              resized = img.copyResize(decodedImage, width: 300);
            } else {
              resized = img.copyResize(decodedImage, height: 300);
            }
          }
          final compressedBytes =
              Uint8List.fromList(img.encodeJpg(resized, quality: 60));
          final dataUrl =
              'data:image/jpeg;base64,${base64Encode(compressedBytes)}';
          setState(() => _selectedImageDataUrl = dataUrl);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image selected successfully')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting image: $e')),
        );
      }
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final password = _passwordController.text;
    if (password != _confirmPasswordController.text) {
      _showError("Passwords do not match");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final url = Uri.parse("${_baseUrl}users");
      final body = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'username': _usernameController.text.trim(),
        'password': password,
        'phoneNumber': _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        'imageUrl': _selectedImageDataUrl,
        'isActive': true,
        'isAdmin': false,
        'isClient': true,
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final userData = jsonDecode(response.body);
        if (userData['id'] != null) {
          AuthProvider.userId = userData['id'] as int;
        }
        AuthProvider.username = _usernameController.text.trim();
        AuthProvider.password = password;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        final bodyStr = response.body;
        String message = "Registration failed";
        try {
          final err = jsonDecode(bodyStr);
          if (err['message'] != null) message = err['message'] as String;
        } catch (_) {
          if (bodyStr.isNotEmpty) message = bodyStr;
        }
        _showError(message);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showError("An error occurred: ${e.toString()}");
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey.withOpacity(0.35),
        fontSize: 14,
      ),
      filled: true,
      fillColor: const Color(0xFFF8F8F8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Create Account", style: kScreenTitleStyle),
        backgroundColor: Colors.grey[50],
        elevation: 0,
        foregroundColor: const Color(0xFF333333),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(19),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: kScreenTitleUnderline(margin: EdgeInsets.zero),
          ),
        ),
      ),
      body: Container(
        color: Colors.grey[50],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Register as client",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                Text("First Name", style: _labelStyle()),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _firstNameController,
                  decoration: _inputDecoration("First name"),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 20),
                Text("Last Name", style: _labelStyle()),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _lastNameController,
                  decoration: _inputDecoration("Last name"),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 20),
                Text("Email", style: _labelStyle()),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  decoration: _inputDecoration("Email"),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 20),
                Text("Username", style: _labelStyle()),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _usernameController,
                  decoration: _inputDecoration("Username"),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 20),
                Text("Password", style: _labelStyle()),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: _inputDecoration("Password").copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.grey[600],
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if ((v ?? '').isEmpty) return "Required";
                    if ((v ?? '').length < 6) return "At least 6 characters";
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text("Confirm Password", style: _labelStyle()),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: _inputDecoration("Confirm password").copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.grey[600],
                      ),
                      onPressed: () => setState(() =>
                          _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                  validator: (v) => (v ?? '').isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 20),
                Text("Phone Number", style: _labelStyle()),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  decoration: _inputDecoration("Phone number"),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),
                Text("Profile Image", style: _labelStyle()),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F8F8),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: _selectedImageDataUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.memory(
                                  base64Decode(
                                      _selectedImageDataUrl!.split(',')[1]),
                                  fit: BoxFit.cover,
                                  width: 80,
                                  height: 80,
                                ),
                              )
                            : Icon(
                                Icons.add_a_photo,
                                color: Colors.grey[600],
                                size: 32,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Tap to add image",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brown,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Register",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Already have an account? Sign in",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _brown,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextStyle _labelStyle() {
    return const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Color(0xFF2D2D2D),
    );
  }
}
