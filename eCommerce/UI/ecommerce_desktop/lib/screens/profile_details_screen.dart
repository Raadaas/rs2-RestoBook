import 'package:flutter/material.dart';
import 'package:ecommerce_desktop/model/user.dart';
import 'package:ecommerce_desktop/model/search_result.dart';
import 'package:ecommerce_desktop/models/restaurant_model.dart';
import 'package:ecommerce_desktop/models/city_model.dart';
import 'package:ecommerce_desktop/models/cuisine_type_model.dart';
import 'package:ecommerce_desktop/providers/user_provider.dart';
import 'package:ecommerce_desktop/providers/restaurant_provider.dart';
import 'package:ecommerce_desktop/providers/city_provider.dart';
import 'package:ecommerce_desktop/providers/cuisine_type_provider.dart';
import 'package:ecommerce_desktop/providers/auth_provider.dart';
import 'package:ecommerce_desktop/providers/restaurant_gallery_provider.dart';
import 'package:ecommerce_desktop/providers/validation_exception.dart';
import 'package:ecommerce_desktop/models/restaurant_gallery_model.dart';
import 'package:ecommerce_desktop/widgets/screen_title_header.dart';
import 'package:ecommerce_desktop/screens/login_screen.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';

class ProfileDetailsScreen extends StatefulWidget {
  final User user;
  final Restaurant restaurant;
  final VoidCallback? onUpdate;

  const ProfileDetailsScreen({
    super.key,
    required this.user,
    required this.restaurant,
    this.onUpdate,
  });

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  late User _currentUser;
  late Restaurant _currentRestaurant;
  bool _isEditUserMode = false;
  bool _isEditRestaurantMode = false;
  File? _selectedImageFile;
  String? _selectedImageDataUrl;
  List<RestaurantGalleryItem> _galleryImages = [];
  bool _galleryLoading = false;
  Map<String, String> _userFormErrors = {};
  Map<String, String> _restaurantFormErrors = {};

  final UserProvider _userProvider = UserProvider();
  final RestaurantProvider _restaurantProvider = RestaurantProvider();
  final CityProvider _cityProvider = CityProvider();
  final CuisineTypeProvider _cuisineTypeProvider = CuisineTypeProvider();
  final RestaurantGalleryProvider _galleryProvider = RestaurantGalleryProvider();

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _currentRestaurant = widget.restaurant;
    _loadGallery();
  }

  Future<void> _loadGallery() async {
    setState(() => _galleryLoading = true);
    try {
      final list = await _galleryProvider.getByRestaurant(_currentRestaurant.id);
      if (mounted) setState(() {
        _galleryImages = list;
        _galleryLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _galleryImages = [];
        _galleryLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    try {
      final user = await _userProvider.getById(_currentUser.id);
      final restaurant = await _restaurantProvider.getById(_currentRestaurant.id);
      if (user != null && restaurant != null) {
        setState(() {
          _currentUser = user;
          _currentRestaurant = restaurant;
        });
        widget.onUpdate?.call();
      }
    } catch (e) {
      debugPrint('Error refreshing data: $e');
    }
  }

  Future<void> _showImagePickerDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Select Image'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(dialogContext);
                  await _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () async {
                  Navigator.pop(dialogContext);
                  await _pickImage(fromCamera: true);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _getPasswordLastChangedText() {
    if (_currentUser.passwordChangedAt == null) {
      return 'Password has never been changed';
    }
    
    final now = DateTime.now();
    final changedAt = _currentUser.passwordChangedAt!;
    final difference = now.difference(changedAt);
    
    if (difference.inDays < 1) {
      return 'Last changed today';
    } else if (difference.inDays == 1) {
      return 'Last changed yesterday';
    } else if (difference.inDays < 30) {
      return 'Last changed ${difference.inDays} days ago';
    } else if (difference.inDays < 60) {
      final months = (difference.inDays / 30).floor();
      return 'Last changed $months month${months > 1 ? 's' : ''} ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return 'Last changed $months months ago';
    }
  }

  Widget _buildImageFromUrl(String imageUrl) {
    // Check if it's a base64 data URL
    if (imageUrl.startsWith('data:image/')) {
      try {
        final base64String = imageUrl.split(',')[1];
        return Image.memory(
          base64Decode(base64String),
          fit: BoxFit.cover,
          width: 80,
          height: 80,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.person,
              color: Colors.white,
              size: 48,
            );
          },
        );
      } catch (e) {
        return const Icon(
          Icons.person,
          color: Colors.white,
          size: 48,
        );
      }
    } else {
      // Regular network URL
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: 80,
        height: 80,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.person,
            color: Colors.white,
            size: 48,
          );
        },
      );
    }
  }

  Future<void> _pickImage({bool fromCamera = false}) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: false,
        withReadStream: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.single.path;
        
        if (filePath != null) {
          final file = File(filePath);
          final originalBytes = await file.readAsBytes();
          
          // Decode and compress image
          final decodedImage = img.decodeImage(originalBytes);
          if (decodedImage != null) {
            // Resize to max 300px on longest side
            img.Image resized = decodedImage;
            if (decodedImage.width > 300 || decodedImage.height > 300) {
              if (decodedImage.width > decodedImage.height) {
                resized = img.copyResize(decodedImage, width: 300);
              } else {
                resized = img.copyResize(decodedImage, height: 300);
              }
            }
            
            // Encode as JPEG with quality 60 to minimize size
            Uint8List compressedBytes = Uint8List.fromList(
              img.encodeJpg(resized, quality: 60)
            );
            String dataUrl = 'data:image/jpeg;base64,${base64Encode(compressedBytes)}';
            
            setState(() {
              _selectedImageFile = file;
              _selectedImageDataUrl = dataUrl;
            });
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Image selected successfully')),
              );
            }
          } else {
            throw Exception('Could not decode image');
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F0),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ScreenTitleHeader(
                  title: 'Profile',
                  subtitle: 'Account and restaurant settings',
                  icon: Icons.person_rounded,
                ),
                const SizedBox(height: 24),
                // Profile Information Section
                _buildProfileInformationSection(),
                const SizedBox(height: 24),
                // Security Settings Section
                _buildSecuritySettingsSection(),
                const SizedBox(height: 24),
                // Restaurant Information Section
                _buildRestaurantInformationSection(),
                const SizedBox(height: 24),
                // Restaurant Gallery Section
                _buildRestaurantGallerySection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInformationSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF8B7355).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Profile Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A4A4A),
                  ),
                ),
                if (!_isEditUserMode)
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isEditUserMode = true;
                      });
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B7355),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: _isEditUserMode
                ? _buildEditUserForm()
                : _buildUserProfileView(),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfileView() {
    final dateFormat = DateFormat('MMMM yyyy');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar and Name Section
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF8B7355),
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: _currentUser.imageUrl != null && _currentUser.imageUrl!.isNotEmpty
                    ? _buildImageFromUrl(_currentUser.imageUrl!)
                    : const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 48,
                      ),
              ),
            ),
            const SizedBox(width: 20),
            // Name and Role
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_currentUser.firstName} ${_currentUser.lastName}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A4A4A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B7355),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.restaurant_menu,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _currentUser.isAdmin ? 'Admin' : (_currentUser.isClient ? 'Client' : 'User'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Member since ${dateFormat.format(_currentUser.createdAt)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Divider(height: 40),
        // Contact Information
        _buildInfoRow(Icons.person, 'First Name', _currentUser.firstName),
        const SizedBox(height: 16),
        _buildInfoRow(Icons.person, 'Last Name', _currentUser.lastName),
        const SizedBox(height: 16),
        _buildInfoRow(Icons.person_outline, 'Username', _currentUser.username),
        const SizedBox(height: 16),
        _buildInfoRow(Icons.email, 'Email Address', _currentUser.email),
        const SizedBox(height: 16),
        _buildInfoRow(
          Icons.phone,
          'Phone Number',
          _currentUser.phoneNumber ?? 'Not provided',
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF8B7355), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF4A4A4A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditUserForm() {
    final firstNameController = TextEditingController(text: _currentUser.firstName);
    final lastNameController = TextEditingController(text: _currentUser.lastName);
    final usernameController = TextEditingController(text: _currentUser.username);
    final emailController = TextEditingController(text: _currentUser.email);
    final phoneController = TextEditingController(text: _currentUser.phoneNumber ?? '');

    return StatefulBuilder(
          builder: (context, setStateLocal) {
            return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar and Role (read-only in edit mode)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B7355),
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: _selectedImageFile != null
                        ? Image.file(
                            _selectedImageFile!,
                            fit: BoxFit.cover,
                            width: 80,
                            height: 80,
                          )
                        : _selectedImageDataUrl != null
                            ? Image.memory(
                                base64Decode(_selectedImageDataUrl!.split(',')[1]),
                                fit: BoxFit.cover,
                                width: 80,
                                height: 80,
                              )
                            : _currentUser.imageUrl != null && _currentUser.imageUrl!.isNotEmpty
                                ? _buildImageFromUrl(_currentUser.imageUrl!)
                                : const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 48,
                                  ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _showImagePickerDialog(context),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B7355),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.restaurant_menu,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _currentUser.isAdmin ? 'Admin' : (_currentUser.isClient ? 'Client' : 'User'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Member since ${DateFormat('MMMM yyyy').format(_currentUser.createdAt)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Form Fields
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'First Name',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A4A4A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: firstNameController,
                    decoration: InputDecoration(
                      hintText: 'First name',
                      errorText: _userFormErrors['firstName'],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Last Name',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A4A4A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: lastNameController,
                    decoration: InputDecoration(
                      hintText: 'Last name',
                      errorText: _userFormErrors['lastName'],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Username',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A4A4A),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                hintText: 'Username',
                errorText: _userFormErrors['username'],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
const Text(
                'Phone Number',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A4A4A),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                hintText: 'e.g. +1 234 567 8900',
                errorText: _userFormErrors['phoneNumber'],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Email Address',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A4A4A),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                hintText: 'email@example.com',
                errorText: _userFormErrors['email'],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Action Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditUserMode = false;
                  _userFormErrors = {};
                });
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF4A4A4A),
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () async {
                setState(() => _userFormErrors = {});
                try {
                  final request = {
                    'firstName': firstNameController.text.trim(),
                    'lastName': lastNameController.text.trim(),
                    'email': emailController.text.trim(),
                    'username': usernameController.text.trim(),
                    'phoneNumber': phoneController.text.trim().isEmpty
                        ? null
                        : phoneController.text.trim(),
                    'imageUrl': _selectedImageDataUrl ?? _currentUser.imageUrl,
                    'isActive': _currentUser.isActive,
                    'isAdmin': _currentUser.isAdmin,
                    'isClient': _currentUser.isClient,
                  };

                  await _userProvider.update(_currentUser.id, request);

                  setState(() {
                    _selectedImageFile = null;
                    _selectedImageDataUrl = null;
                    _userFormErrors = {};
                  });
                  await _refreshData();

                  if (mounted) {
                    setState(() => _isEditUserMode = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User details have been successfully updated.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } on ValidationException catch (e) {
                  setState(() => _userFormErrors = e.firstErrors);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating profile: ${e.toString().replaceFirst('Exception: ', '')}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Save Changes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B7355),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
            ],
          );
        },
      );
  }

  Widget _buildSecuritySettingsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF8B7355).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Security Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A4A4A),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _showChangePasswordDialog();
                  },
                  icon: const Icon(Icons.lock, size: 18),
                  label: const Text('Change Password'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B7355),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        color: Color(0xFF8B7355),
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Password',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4A4A4A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getPasswordLastChangedText(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'For your security, we recommend changing your password every 3 months.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool showCurrentPassword = false;
    bool showNewPassword = false;
    bool showConfirmPassword = false;
    Map<String, String> passwordErrors = {};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Security Settings'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Password',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A4A4A),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: currentPasswordController,
                  obscureText: !showCurrentPassword,
                  onChanged: (_) => setDialogState(() => passwordErrors = Map.from(passwordErrors)..remove('currentPassword')),
                  decoration: InputDecoration(
                    hintText: 'Enter current password',
                    errorText: passwordErrors['currentPassword'],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    suffixIcon: IconButton(
                      icon: Icon(
                        showCurrentPassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey[600],
                      ),
                      onPressed: () {
                        setDialogState(() {
                          showCurrentPassword = !showCurrentPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'New Password',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A4A4A),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: newPasswordController,
                  obscureText: !showNewPassword,
                  onChanged: (_) => setDialogState(() => passwordErrors = Map.from(passwordErrors)..remove('newPassword')..remove('confirmPassword')),
                  decoration: InputDecoration(
                    hintText: 'Enter new password',
                    errorText: passwordErrors['newPassword'],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    suffixIcon: IconButton(
                      icon: Icon(
                        showNewPassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey[600],
                      ),
                      onPressed: () {
                        setDialogState(() {
                          showNewPassword = !showNewPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Confirm New Password',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A4A4A),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: !showConfirmPassword,
                  onChanged: (_) => setDialogState(() => passwordErrors = Map.from(passwordErrors)..remove('confirmPassword')),
                  decoration: InputDecoration(
                    hintText: 'Confirm new password',
                    errorText: passwordErrors['confirmPassword'],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    suffixIcon: IconButton(
                      icon: Icon(
                        showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey[600],
                      ),
                      onPressed: () {
                        setDialogState(() {
                          showConfirmPassword = !showConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF4A4A4A),
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (currentPasswordController.text.isEmpty) {
                  setDialogState(() => passwordErrors = {'currentPassword': 'Please enter your current password'});
                  return;
                }

                if (newPasswordController.text != confirmPasswordController.text) {
                  setDialogState(() => passwordErrors = {'confirmPassword': 'New passwords do not match'});
                  return;
                }

                if (newPasswordController.text.length < 6) {
                  setDialogState(() => passwordErrors = {'newPassword': 'Password must be at least 6 characters'});
                  return;
                }

                if (newPasswordController.text == currentPasswordController.text) {
                  setDialogState(() => passwordErrors = {'newPassword': 'New password must be different from current password'});
                  return;
                }

                try {
                  // Update user with new password
                  final request = {
                    'firstName': _currentUser.firstName,
                    'lastName': _currentUser.lastName,
                    'email': _currentUser.email,
                    'username': _currentUser.username,
                    'phoneNumber': _currentUser.phoneNumber,
                    'imageUrl': _currentUser.imageUrl,
                    'currentPassword': currentPasswordController.text,
                    'password': newPasswordController.text,
                    'isActive': _currentUser.isActive,
                    'isAdmin': _currentUser.isAdmin,
                    'isClient': _currentUser.isClient,
                  };

                  await _userProvider.update(_currentUser.id, request);

                  if (mounted) {
                    Navigator.pop(context);
                    AuthProvider.clear();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  }
                } on ValidationException catch (e) {
                  if (mounted) {
                    final map = <String, String>{};
                    if (e.firstErrorFor('CurrentPassword') != null || e.firstErrorFor('currentPassword') != null) {
                      map['currentPassword'] = e.firstErrorFor('CurrentPassword') ?? e.firstErrorFor('currentPassword')!;
                    }
                    if (e.firstErrorFor('Password') != null || e.firstErrorFor('password') != null) {
                      map['newPassword'] = e.firstErrorFor('Password') ?? e.firstErrorFor('password')!;
                    }
                    if (map.isEmpty) {
                      map['currentPassword'] = e.message;
                    }
                    setDialogState(() => passwordErrors = map);
                  }
                } catch (e) {
                  if (mounted) {
                    setDialogState(() => passwordErrors = {
                      'currentPassword': 'Error changing password: ${e.toString().replaceFirst('Exception: ', '')}'
                    });
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B7355),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantInformationSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF8B7355).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Restaurant Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A4A4A),
                  ),
                ),
                if (!_isEditRestaurantMode)
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isEditRestaurantMode = true;
                      });
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit Restaurant'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B7355),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: _isEditRestaurantMode
                ? _buildEditRestaurantForm()
                : _buildRestaurantView(),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantGallerySection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF8B7355).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Restaurant Gallery',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A4A4A),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _galleryLoading ? null : _pickAndUploadGalleryImage,
                  icon: const Icon(Icons.add_photo_alternate, size: 18),
                  label: const Text('Upload Image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B7355),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: _galleryLoading && _galleryImages.isEmpty
                ? const Center(child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ))
                : _galleryImages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.photo_library_outlined, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(
                                'No images yet',
                                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Click "Upload Image" to add photos',
                                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: _galleryImages.map((item) => _buildGalleryImageCard(item)).toList(),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryImageCard(RestaurantGalleryItem item) {
    return Stack(
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[200],
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                ? (item.imageUrl!.startsWith('data:image/')
                    ? Image.memory(
                        base64Decode(item.imageUrl!.split(',')[1]),
                        fit: BoxFit.cover,
                        width: 140,
                        height: 140,
                      )
                    : Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        width: 140,
                        height: 140,
                        errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: 48, color: Colors.grey[400]),
                      ))
                : Icon(Icons.image, size: 48, color: Colors.grey[400]),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _deleteGalleryImage(item.id!),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickAndUploadGalleryImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      final filePath = result.files.single.path;
      if (filePath == null) return;

      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) throw Exception('Could not decode image');

      img.Image resized = decodedImage;
      if (decodedImage.width > 800 || decodedImage.height > 800) {
        if (decodedImage.width > decodedImage.height) {
          resized = img.copyResize(decodedImage, width: 800);
        } else {
          resized = img.copyResize(decodedImage, height: 800);
        }
      }
      final compressedBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 75));
      final dataUrl = 'data:image/jpeg;base64,${base64Encode(compressedBytes)}';

      await _galleryProvider.insert(
        restaurantId: _currentRestaurant.id,
        imageUrl: dataUrl,
        displayOrder: _galleryImages.length,
      );
      await _loadGallery();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    }
  }

  Future<void> _deleteGalleryImage(int id) async {
    try {
      await _galleryProvider.delete(id);
      await _loadGallery();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image removed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting image: $e')),
        );
      }
    }
  }

  Widget _buildRestaurantView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(Icons.restaurant, 'Name', _currentRestaurant.name),
        const SizedBox(height: 16),
        if (_currentRestaurant.description != null && _currentRestaurant.description!.isNotEmpty) ...[
          _buildInfoRow(Icons.description, 'Description', _currentRestaurant.description!),
          const SizedBox(height: 16),
        ],
        _buildInfoRow(Icons.location_on, 'Address', _currentRestaurant.address),
        const SizedBox(height: 16),
        _buildInfoRow(Icons.location_city, 'City', _currentRestaurant.cityName),
        const SizedBox(height: 16),
        if (_currentRestaurant.latitude != null && _currentRestaurant.longitude != null) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.map, color: Colors.grey[700], size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Location',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A4A4A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 300,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildMapView(
                    _currentRestaurant.latitude!,
                    _currentRestaurant.longitude!,
                    enableInteraction: false,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (_currentRestaurant.phoneNumber != null && _currentRestaurant.phoneNumber!.isNotEmpty) ...[
          _buildInfoRow(Icons.phone, 'Phone Number', _currentRestaurant.phoneNumber!),
          const SizedBox(height: 16),
        ],
        if (_currentRestaurant.email != null && _currentRestaurant.email!.isNotEmpty) ...[
          _buildInfoRow(Icons.email, 'Email', _currentRestaurant.email!),
          const SizedBox(height: 16),
        ],
        _buildInfoRow(Icons.restaurant_menu, 'Cuisine Type', _currentRestaurant.cuisineTypeName),
        const SizedBox(height: 16),
        Row(
          children: [
            if (_currentRestaurant.hasParking)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_parking, size: 16, color: Colors.green.shade700),
                    const SizedBox(width: 4),
                    Text('Parking', style: TextStyle(color: Colors.green.shade700, fontSize: 12)),
                  ],
                ),
              ),
            if (_currentRestaurant.hasTerrace)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.deck, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 4),
                    Text('Terrace', style: TextStyle(color: Colors.blue.shade700, fontSize: 12)),
                  ],
                ),
              ),
            if (_currentRestaurant.isKidFriendly)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.child_care, size: 16, color: Colors.orange.shade700),
                    const SizedBox(width: 4),
                    Text('Kid Friendly', style: TextStyle(color: Colors.orange.shade700, fontSize: 12)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          Icons.access_time,
          'Opening Hours',
          '${_currentRestaurant.openTime.substring(0, 5)} - ${_currentRestaurant.closeTime.substring(0, 5)}',
        ),
      ],
    );
  }

  Widget _buildEditRestaurantForm() {
    final nameController = TextEditingController(text: _currentRestaurant.name);
    final descriptionController = TextEditingController(text: _currentRestaurant.description ?? '');
    final addressController = TextEditingController(text: _currentRestaurant.address);
    final emailController = TextEditingController(text: _currentRestaurant.email ?? '');
    final phoneController = TextEditingController(text: _currentRestaurant.phoneNumber ?? '');

    // Parse open and close times
    TimeOfDay openTime = _parseTimeString(_currentRestaurant.openTime);
    TimeOfDay closeTime = _parseTimeString(_currentRestaurant.closeTime);

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        _cityProvider.get(filter: {'isActive': true}),
        _cuisineTypeProvider.get(filter: {'isActive': true}),
      ]),
      builder: (context, snapshot) {
        List<City> cities = [];
        List<CuisineType> cuisineTypes = [];
        
        if (snapshot.hasData) {
          cities = (snapshot.data![0] as SearchResult<City>).items ?? [];
          cuisineTypes = (snapshot.data![1] as SearchResult<CuisineType>).items ?? [];
        }

        int? selectedCityId = _currentRestaurant.cityId;
        int? selectedCuisineTypeId = _currentRestaurant.cuisineTypeId;
        bool hasParking = _currentRestaurant.hasParking;
        bool hasTerrace = _currentRestaurant.hasTerrace;
        bool isKidFriendly = _currentRestaurant.isKidFriendly;
        TimeOfDay selectedOpenTime = openTime;
        TimeOfDay selectedCloseTime = closeTime;
        double? selectedLatitude = _currentRestaurant.latitude;
        double? selectedLongitude = _currentRestaurant.longitude;

        return StatefulBuilder(
          builder: (context, setStateLocal) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  _buildTextField('Restaurant Name', nameController, errorText: _restaurantFormErrors['name']),
                  const SizedBox(height: 16),
                  
                  // Description
                  _buildTextField('Description', descriptionController, maxLines: 3, errorText: _restaurantFormErrors['description']),
                  const SizedBox(height: 16),
                  
                  // Address
                  _buildTextField('Address', addressController, errorText: _restaurantFormErrors['address']),
                  const SizedBox(height: 16),
                  
                  // City
                  _buildDropdown<int>(
                    'City',
                    selectedCityId,
                    cities.map((city) => DropdownMenuItem(
                      value: city.id,
                      child: Text(city.name),
                    )).toList(),
                    (value) {
                      setStateLocal(() {
                        selectedCityId = value;
                      });
                    },
                    errorText: _restaurantFormErrors['cityId'],
                  ),
                  const SizedBox(height: 16),
                  
                  // Google Maps for location selection
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Location',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4A4A4A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Click on the map to select location',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 300,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildMapEditor(
                            initialLatitude: selectedLatitude,
                            initialLongitude: selectedLongitude,
                            onLocationChanged: (lat, lng) {
                              setStateLocal(() {
                                selectedLatitude = lat;
                                selectedLongitude = lng;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Phone Number
                  _buildTextField('Phone Number', phoneController, errorText: _restaurantFormErrors['phoneNumber']),
                  const SizedBox(height: 16),
                  
                  // Email
                  _buildTextField('Email', emailController, errorText: _restaurantFormErrors['email']),
                  const SizedBox(height: 16),
                  
                  // Cuisine Type
                  _buildDropdown<int>(
                    'Cuisine Type',
                    selectedCuisineTypeId,
                    cuisineTypes.map((type) => DropdownMenuItem(
                      value: type.id,
                      child: Text(type.name),
                    )).toList(),
                    (value) {
                      setStateLocal(() {
                        selectedCuisineTypeId = value;
                      });
                    },
                    errorText: _restaurantFormErrors['cuisineTypeId'],
                  ),
                  const SizedBox(height: 16),
                  
                  // Checkboxes
                  CheckboxListTile(
                    title: const Text('Has Parking'),
                    value: hasParking,
                    onChanged: (value) {
                      setStateLocal(() {
                        hasParking = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: const Text('Has Terrace'),
                    value: hasTerrace,
                    onChanged: (value) {
                      setStateLocal(() {
                        hasTerrace = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: const Text('Is Kid Friendly'),
                    value: isKidFriendly,
                    onChanged: (value) {
                      setStateLocal(() {
                        isKidFriendly = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 16),
                  
                  // Open Time
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Open Time',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4A4A4A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: selectedOpenTime,
                          );
                          if (picked != null && picked != selectedOpenTime) {
                            setStateLocal(() {
                              selectedOpenTime = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.shade100,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${selectedOpenTime.hour.toString().padLeft(2, '0')}:${selectedOpenTime.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const Icon(Icons.access_time),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Close Time
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Close Time',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4A4A4A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: selectedCloseTime,
                          );
                          if (picked != null && picked != selectedCloseTime) {
                            setStateLocal(() {
                              selectedCloseTime = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.shade100,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${selectedCloseTime.hour.toString().padLeft(2, '0')}:${selectedCloseTime.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const Icon(Icons.access_time),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isEditRestaurantMode = false;
                            _restaurantFormErrors = {};
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey.shade400),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Color(0xFF4A4A4A),
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          setState(() => _restaurantFormErrors = {});
                          try {
                            final openTimeStr = '${selectedOpenTime.hour.toString().padLeft(2, '0')}:${selectedOpenTime.minute.toString().padLeft(2, '0')}:00';
                            final closeTimeStr = '${selectedCloseTime.hour.toString().padLeft(2, '0')}:${selectedCloseTime.minute.toString().padLeft(2, '0')}:00';
                            double? latitude = selectedLatitude;
                            double? longitude = selectedLongitude;

                            final request = {
                              'ownerId': _currentRestaurant.ownerId,
                              'name': nameController.text.trim(),
                              'description': descriptionController.text.trim().isEmpty
                                  ? null
                                  : descriptionController.text.trim(),
                              'address': addressController.text.trim(),
                              'cityId': selectedCityId ?? _currentRestaurant.cityId,
                              'latitude': latitude,
                              'longitude': longitude,
                              'email': emailController.text.trim().isEmpty
                                  ? null
                                  : emailController.text.trim(),
                              'phoneNumber': phoneController.text.trim().isEmpty
                                  ? null
                                  : phoneController.text.trim(),
                              'cuisineTypeId': selectedCuisineTypeId ?? _currentRestaurant.cuisineTypeId,
                              'hasParking': hasParking,
                              'hasTerrace': hasTerrace,
                              'isKidFriendly': isKidFriendly,
                              'openTime': openTimeStr,
                              'closeTime': closeTimeStr,
                              'isActive': _currentRestaurant.isActive,
                            };

                            await _restaurantProvider.update(_currentRestaurant.id, request);
                            await _refreshData();

                            if (mounted) {
                              setState(() {
                                _isEditRestaurantMode = false;
                                _restaurantFormErrors = {};
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Restaurant details have been successfully updated.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } on ValidationException catch (e) {
                            setState(() => _restaurantFormErrors = e.firstErrors);
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error updating restaurant: ${e.toString().replaceFirst('Exception: ', '')}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.save, size: 18),
                        label: const Text('Save Changes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B7355),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, String? errorText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A4A4A),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            errorText: errorText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>(
    String label,
    T? value,
    List<DropdownMenuItem<T>> items,
    ValueChanged<T?> onChanged, {
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A4A4A),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          decoration: InputDecoration(
            errorText: errorText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }

  TimeOfDay _parseTimeString(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      // If parsing fails, return default time
    }
    return const TimeOfDay(hour: 9, minute: 0);
  }

  Widget _buildMapView(double latitude, double longitude, {bool enableInteraction = false}) {
    // Show OpenStreetMap in view mode (read-only)
    final restaurantPosition = LatLng(latitude, longitude);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: restaurantPosition,
          initialZoom: 15.0,
          interactionOptions: InteractionOptions(
            flags: enableInteraction 
                ? InteractiveFlag.all 
                : InteractiveFlag.none,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.ecommerce_desktop',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: restaurantPosition,
                width: 40,
                height: 40,
                child: Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapEditor({
    double? initialLatitude,
    double? initialLongitude,
    required Function(double, double) onLocationChanged,
  }) {
    final defaultLat = 43.8563; // Default to Sarajevo
    final defaultLng = 18.4131;
    
    double initialLat = initialLatitude ?? defaultLat;
    double initialLng = initialLongitude ?? defaultLng;
    
    return _MapEditorWidget(
      initialLatitude: initialLat,
      initialLongitude: initialLng,
      onLocationChanged: onLocationChanged,
    );
  }
}

class _MapEditorWidget extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;
  final Function(double, double) onLocationChanged;

  const _MapEditorWidget({
    required this.initialLatitude,
    required this.initialLongitude,
    required this.onLocationChanged,
  });

  @override
  State<_MapEditorWidget> createState() => _MapEditorWidgetState();
}

class _MapEditorWidgetState extends State<_MapEditorWidget> {
  late LatLng pickedLocation;
  late MapController mapController;

  @override
  void initState() {
    super.initState();
    pickedLocation = LatLng(widget.initialLatitude, widget.initialLongitude);
    mapController = MapController();
  }

  @override
  void didUpdateWidget(_MapEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update location if initial values changed from outside
    if (oldWidget.initialLatitude != widget.initialLatitude ||
        oldWidget.initialLongitude != widget.initialLongitude) {
      pickedLocation = LatLng(widget.initialLatitude, widget.initialLongitude);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Interactive OpenStreetMap for location selection
        SizedBox(
          height: 400,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: pickedLocation,
                initialZoom: 15.0,
                onTap: (tapPosition, point) {
                  setState(() {
                    pickedLocation = point;
                    widget.onLocationChanged(point.latitude, point.longitude);
                  });
                },
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.ecommerce_desktop',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: pickedLocation,
                      width: 50,
                      height: 50,
                      child: Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 50,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Display current coordinates
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(Icons.location_on, color: Colors.grey[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Latitude: ${pickedLocation.latitude.toStringAsFixed(6)}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Longitude: ${pickedLocation.longitude.toStringAsFixed(6)}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Click on the map to select location',
          style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}