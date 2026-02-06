import 'dart:convert';

import 'package:ecommerce_mobile/app_styles.dart';
import 'package:ecommerce_mobile/model/user.dart';
import 'package:ecommerce_mobile/providers/auth_provider.dart';
import 'package:ecommerce_mobile/providers/user_provider.dart';
import 'package:ecommerce_mobile/providers/validation_exception.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

const Color _brown = Color(0xFF8B7355);
const Color _brownLight = Color(0xFFB39B7A);
const Color _beige = Color(0xFFF5F0E8);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserProvider _userProvider = UserProvider();
  User? _user;
  bool _loading = true;
  String? _error;
  String? _selectedImageDataUrl;
  Map<String, String> _serverErrors = {};

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _load({bool showLoading = true}) async {
    final userId = AuthProvider.userId;
    if (userId == null) {
      setState(() {
        _loading = false;
        _error = 'Not logged in';
      });
      return;
    }
    setState(() {
      if (showLoading) _loading = true;
      _error = null;
    });
    try {
      final user = await _userProvider.getById(userId);
      if (!mounted) return;
      setState(() {
        _user = user;
        _loading = false;
        _error = user == null ? 'User not found' : null;
      });
      if (user != null) {
        _firstNameController.text = user.firstName;
        _lastNameController.text = user.lastName;
        _usernameController.text = user.username;
        _emailController.text = user.email;
        _phoneController.text = user.phoneNumber ?? '';
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _pickImage({required ImageSource source}) async {
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(source: source, imageQuality: 85);
      if (xFile == null || !mounted) return;
      final bytes = await xFile.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        if (mounted) _showSnack('Could not decode image');
        return;
      }
      img.Image resized = decoded;
      if (decoded.width > 300 || decoded.height > 300) {
        if (decoded.width > decoded.height) {
          resized = img.copyResize(decoded, width: 300);
        } else {
          resized = img.copyResize(decoded, height: 300);
        }
      }
      final compressed = img.encodeJpg(resized, quality: 60);
      final dataUrl = 'data:image/jpeg;base64,${base64Encode(compressed)}';
      setState(() => _selectedImageDataUrl = dataUrl);
      if (mounted) _showSnack('Photo updated');
    } catch (e) {
      if (mounted) _showSnack('Error: $e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(source: ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(source: ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final src = _selectedImageDataUrl ?? _user?.imageUrl;

    Widget imageWidget;
    if (src != null && src.startsWith('data:image/')) {
      try {
        final b64 = src.split(',').elementAtOrNull(1);
        if (b64 != null) {
          imageWidget = Image.memory(
            base64Decode(b64),
            fit: BoxFit.cover,
            width: 120,
            height: 120,
          );
        } else {
          imageWidget = _placeholderAvatar();
        }
      } catch (_) {
        imageWidget = _placeholderAvatar();
      }
    } else if (src != null && src.isNotEmpty) {
      imageWidget = Image.network(
        src,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
        errorBuilder: (_, __, ___) => _placeholderAvatar(),
      );
    } else {
      imageWidget = _placeholderAvatar();
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: const BoxDecoration(
            color: _beige,
            shape: BoxShape.circle,
          ),
          child: ClipOval(child: imageWidget),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _showImageSourceDialog,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _brown,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholderAvatar() {
    return SizedBox(
      width: 120,
      height: 120,
      child: Center(
        child: Icon(Icons.person, color: _brown, size: 56),
      ),
    );
  }

  Widget _input({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    String? errorText,
    TextInputType? keyboardType,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            prefixIcon: Icon(icon, size: 22, color: Colors.grey[600]),
            filled: true,
            fillColor: _beige,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final user = _user;
    if (user == null) return;
    setState(() => _serverErrors = {});

    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (first.isEmpty || last.isEmpty || username.isEmpty || email.isEmpty) {
      setState(() {
        if (first.isEmpty) _serverErrors['firstName'] = 'First name is required.';
        if (last.isEmpty) _serverErrors['lastName'] = 'Last name is required.';
        if (username.isEmpty) _serverErrors['username'] = 'Username is required.';
        if (email.isEmpty) _serverErrors['email'] = 'Email address is required.';
      });
      return;
    }

    try {
      final request = {
        'firstName': first,
        'lastName': last,
        'email': email,
        'username': username,
        'phoneNumber': phone.isEmpty ? null : phone,
        'imageUrl': _selectedImageDataUrl ?? user.imageUrl,
        'isActive': user.isActive,
        'isAdmin': false,
        'isClient': true,
      };
      await _userProvider.update(user.id, request);
      if (username != user.username) AuthProvider.username = username;
      setState(() {
        _selectedImageDataUrl = null;
        _serverErrors = {};
      });
      await _load(showLoading: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile has been successfully updated.'),
          backgroundColor: Colors.green,
        ),
      );
    } on ValidationException catch (e) {
      setState(() => _serverErrors = e.firstErrors);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showChangePasswordDialog() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final user = _user;
    if (user == null) return;

    void disposeControllers() {
      currentController.dispose();
      newController.dispose();
      confirmController.dispose();
    }

    void disposeControllersAfterRouteRemoved() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) => disposeControllers());
      });
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) {
          return AlertDialog(
            title: const Text('Change password'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _input(
                    label: 'Current password',
                    controller: currentController,
                    icon: Icons.lock_outline,
                    hint: 'Enter current password',
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  _input(
                    label: 'New password',
                    controller: newController,
                    icon: Icons.lock_outline,
                    hint: 'At least 6 characters',
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  _input(
                    label: 'Confirm new password',
                    controller: confirmController,
                    icon: Icons.lock_outline,
                    hint: 'Confirm new password',
                    obscureText: true,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  disposeControllersAfterRouteRemoved();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final current = currentController.text;
                  final newPwd = newController.text;
                  final confirm = confirmController.text;
                  if (current.isEmpty) {
                    _showSnack('Enter current password');
                    return;
                  }
                  if (newPwd.length < 6) {
                    _showSnack('New password must be at least 6 characters');
                    return;
                  }
                  if (newPwd != confirm) {
                    _showSnack('New passwords do not match');
                    return;
                  }
                  if (newPwd == current) {
                    _showSnack('New password must differ from current');
                    return;
                  }
                  try {
                    final request = {
                      'firstName': user.firstName,
                      'lastName': user.lastName,
                      'email': user.email,
                      'username': user.username,
                      'phoneNumber': user.phoneNumber,
                      'imageUrl': user.imageUrl,
                      'isActive': user.isActive,
                      'roleIds': <int>[],
                      'currentPassword': current,
                      'password': newPwd,
                    };
                    await _userProvider.update(user.id, request);
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    disposeControllersAfterRouteRemoved();
                    await _load(showLoading: false);
                    if (!mounted) return;
                    _showSnack('Password changed');
                    AuthProvider.password = newPwd;
                  } catch (e) {
                    if (mounted) _showSnack('Error: ${e.toString().replaceFirst('Exception: ', '')}');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brown,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Update password'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700])),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Back'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text('Settings', style: kScreenTitleStyle),
                      ),
                      kScreenTitleUnderline(margin: const EdgeInsets.only(bottom: 24)),
                      Center(
                        child: Column(
                          children: [
                            _buildAvatar(),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _showImageSourceDialog,
                              child: Text(
                                'Change profile photo',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      if (_serverErrors['_form'] != null) ...[
                        Text(
                          _serverErrors['_form']!,
                          style: TextStyle(fontSize: 13, color: Colors.red[700]),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _input(
                        label: 'First Name',
                        controller: _firstNameController,
                        icon: Icons.person_outline,
                        hint: 'First name',
                        errorText: _serverErrors['firstName'],
                      ),
                      const SizedBox(height: 16),
                      _input(
                        label: 'Last Name',
                        controller: _lastNameController,
                        icon: Icons.person_outline,
                        hint: 'Last name',
                        errorText: _serverErrors['lastName'],
                      ),
                      const SizedBox(height: 16),
                      _input(
                        label: 'Username',
                        controller: _usernameController,
                        icon: Icons.badge_outlined,
                        hint: 'Username',
                        errorText: _serverErrors['username'],
                      ),
                      const SizedBox(height: 16),
                      _input(
                        label: 'Email Address',
                        controller: _emailController,
                        icon: Icons.email_outlined,
                        hint: 'e.g. user@example.com',
                        keyboardType: TextInputType.emailAddress,
                        errorText: _serverErrors['email'],
                      ),
                      const SizedBox(height: 16),
                      _input(
                        label: 'Phone Number (optional)',
                        controller: _phoneController,
                        icon: Icons.phone_outlined,
                        hint: 'e.g. +1 234 567 8900',
                        keyboardType: TextInputType.phone,
                        errorText: _serverErrors['phoneNumber'],
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.save, size: 20),
                          label: const Text('Save Changes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _brown,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _showChangePasswordDialog,
                        icon: const Icon(Icons.lock_reset, size: 20),
                        label: const Text('Change password'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _brown,
                          side: const BorderSide(color: _brownLight),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }
}
