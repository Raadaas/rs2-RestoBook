import 'package:flutter/material.dart';
import 'package:ecommerce_desktop/model/user.dart';
import 'package:ecommerce_desktop/models/restaurant_model.dart';
import 'package:ecommerce_desktop/models/city_model.dart';
import 'package:ecommerce_desktop/models/cuisine_type_model.dart';
import 'package:ecommerce_desktop/providers/restaurant_provider.dart';
import 'package:ecommerce_desktop/providers/city_provider.dart';
import 'package:ecommerce_desktop/providers/cuisine_type_provider.dart';
import 'package:ecommerce_desktop/model/search_result.dart';
import 'package:ecommerce_desktop/widgets/screen_title_header.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

const Color _brownLight = Color(0xFFB39B7A);

class AddRestaurantScreen extends StatefulWidget {
  final User user;

  const AddRestaurantScreen({super.key, required this.user});

  @override
  State<AddRestaurantScreen> createState() => _AddRestaurantScreenState();
}

class _AddRestaurantScreenState extends State<AddRestaurantScreen> {
  final RestaurantProvider _restaurantProvider = RestaurantProvider();
  final CityProvider _cityProvider = CityProvider();
  final CuisineTypeProvider _cuisineTypeProvider = CuisineTypeProvider();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  int? _selectedCityId;
  int? _selectedCuisineTypeId;
  double? _latitude;
  double? _longitude;
  TimeOfDay _openTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _closeTime = const TimeOfDay(hour: 22, minute: 0);
  bool _hasParking = false;
  bool _hasTerrace = false;
  bool _isKidFriendly = false;
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter restaurant name');
      return;
    }
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      setState(() => _error = 'Please enter address');
      return;
    }
    if (_selectedCityId == null) {
      setState(() => _error = 'Please select a city');
      return;
    }
    if (_selectedCuisineTypeId == null) {
      setState(() => _error = 'Please select a cuisine type');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final openTimeStr =
          '${_openTime.hour.toString().padLeft(2, '0')}:${_openTime.minute.toString().padLeft(2, '0')}:00';
      final closeTimeStr =
          '${_closeTime.hour.toString().padLeft(2, '0')}:${_closeTime.minute.toString().padLeft(2, '0')}:00';

      final request = {
        'ownerId': widget.user.id,
        'name': name,
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'address': address,
        'cityId': _selectedCityId,
        'latitude': _latitude,
        'longitude': _longitude,
        'email': _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        'phoneNumber': _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        'cuisineTypeId': _selectedCuisineTypeId,
        'hasParking': _hasParking,
        'hasTerrace': _hasTerrace,
        'isKidFriendly': _isKidFriendly,
        'openTime': openTimeStr,
        'closeTime': closeTimeStr,
        'isActive': true,
      };

      final created = await _restaurantProvider.insert(request) as Restaurant;

      if (mounted) {
        Navigator.pop(context, created);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([
          _cityProvider.get(filter: {'isActive': true}),
          _cuisineTypeProvider.get(filter: {'isActive': true}),
        ]),
        builder: (context, snapshot) {
          List<City> cities = [];
          List<CuisineType> cuisineTypes = [];

          if (snapshot.hasData) {
            cities = (snapshot.data![0] as SearchResult<City>).items ?? [];
            cuisineTypes =
                (snapshot.data![1] as SearchResult<CuisineType>).items ?? [];
            if (_selectedCityId == null && cities.isNotEmpty) {
              _selectedCityId = cities.first.id;
            }
            if (_selectedCuisineTypeId == null && cuisineTypes.isNotEmpty) {
              _selectedCuisineTypeId = cuisineTypes.first.id;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ScreenTitleHeader(
                      title: 'Add Restaurant',
                      subtitle: 'Register a new restaurant',
                      icon: Icons.restaurant_rounded,
                    ),
                    const SizedBox(height: 24),
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildTextField('Name', _nameController),
                    const SizedBox(height: 16),
                    _buildTextField('Description', _descriptionController,
                        maxLines: 3),
                    const SizedBox(height: 16),
                    _buildTextField('Address', _addressController),
                    const SizedBox(height: 16),
                    _buildDropdown<int>(
                      'City',
                      _selectedCityId,
                      cities
                          .map((c) => DropdownMenuItem(
                              value: c.id, child: Text(c.name)))
                          .toList(),
                      (v) => setState(() => _selectedCityId = v),
                    ),
                    const SizedBox(height: 16),
                    _buildMapSection(),
                    const SizedBox(height: 16),
                    _buildTextField('Phone Number', _phoneController),
                    const SizedBox(height: 16),
                    _buildTextField('Email', _emailController),
                    const SizedBox(height: 16),
                    _buildDropdown<int>(
                      'Cuisine Type',
                      _selectedCuisineTypeId,
                      cuisineTypes
                          .map((t) => DropdownMenuItem(
                              value: t.id, child: Text(t.name)))
                          .toList(),
                      (v) => setState(() => _selectedCuisineTypeId = v),
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Has Parking'),
                      value: _hasParking,
                      onChanged: (v) =>
                          setState(() => _hasParking = v ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      title: const Text('Has Terrace'),
                      value: _hasTerrace,
                      onChanged: (v) =>
                          setState(() => _hasTerrace = v ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      title: const Text('Is Kid Friendly'),
                      value: _isKidFriendly,
                      onChanged: (v) =>
                          setState(() => _isKidFriendly = v ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 16),
                    _buildTimeField('Open Time', _openTime,
                        (t) => setState(() => _openTime = t)),
                    const SizedBox(height: 16),
                    _buildTimeField('Close Time', _closeTime,
                        (t) => setState(() => _closeTime = t)),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isSaving ? null : () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B7355),
                            foregroundColor: Colors.white,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Create Restaurant'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1}) {
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>(String label, T? value,
      List<DropdownMenuItem<T>> items, ValueChanged<T?> onChanged) {
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTimeField(
      String label, TimeOfDay time, ValueChanged<TimeOfDay> onChanged) {
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
        InkWell(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: time,
            );
            if (picked != null) onChanged(picked);
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
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 16),
                ),
                const Icon(Icons.access_time),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapSection() {
    final defaultLat = 43.8563;
    final defaultLng = 18.4131;
    final lat = _latitude ?? defaultLat;
    final lng = _longitude ?? defaultLng;
    var location = LatLng(lat, lng);

    return Column(
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
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 300,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: location,
                initialZoom: 15.0,
                onTap: (tapPosition, point) {
                  setState(() {
                    _latitude = point.latitude;
                    _longitude = point.longitude;
                  });
                },
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.ecommerce_desktop',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: location,
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
      ],
    );
  }
}
