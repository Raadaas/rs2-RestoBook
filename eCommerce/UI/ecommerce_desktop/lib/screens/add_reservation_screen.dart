import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ecommerce_desktop/providers/auth_provider.dart';
import 'package:ecommerce_desktop/providers/reservation_provider.dart';
import 'package:ecommerce_desktop/providers/validation_exception.dart';
import 'package:ecommerce_desktop/widgets/screen_title_header.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AddReservationScreen extends StatefulWidget {
  final int restaurantId;

  const AddReservationScreen({
    super.key,
    required this.restaurantId,
  });

  @override
  State<AddReservationScreen> createState() => _AddReservationScreenState();
}

class _AddReservationScreenState extends State<AddReservationScreen> {
  final _formKey = GlobalKey<FormState>();
  final ReservationProvider _reservationProvider = ReservationProvider();
  
  int? _selectedTableId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _durationHours = 2;
  int _numberOfGuests = 2;
  String _specialRequests = '';
  
  List<Map<String, dynamic>> _tables = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  Map<String, String> _fieldErrors = {};

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    try {
      final baseUrl = const String.fromEnvironment(
        "baseUrl",
        defaultValue: "http://localhost:5121/api/"
      );
      final url = Uri.parse("${baseUrl}tables?restaurantId=${widget.restaurantId}");
      final headers = _reservationProvider.createHeaders();
      
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['items'] != null) {
          setState(() {
            _tables = List<Map<String, dynamic>>.from(data['items']);
            if (_tables.isNotEmpty) {
              _selectedTableId = _tables.first['id'];
            }
          });
        }
      }
    } catch (e) {
      setState(() => _error = 'Failed to load tables: $e');
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submitReservation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final userId = AuthProvider.userId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    if (_selectedTableId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a table')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
      _fieldErrors = {};
    });

    try {
      // Combine date and time for reservationDate
      final reservationDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      
      // Format TimeSpan for reservationTime and duration (HH:mm:ss)
      final reservationTime = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}:00';
      final duration = '${_durationHours.toString().padLeft(2, '0')}:00:00';
      
      final request = {
        'userId': userId,
        'restaurantId': widget.restaurantId,
        'tableId': _selectedTableId,
        'reservationDate': reservationDateTime.toIso8601String(),
        'reservationTime': reservationTime,
        'duration': duration,
        'numberOfGuests': _numberOfGuests,
        'status': 'Pending',
        if (_specialRequests.isNotEmpty) 'specialRequests': _specialRequests,
      };

      await _reservationProvider.createReservation(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reservation has been successfully created.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (e is ValidationException) {
        final map = <String, String>{};
        e.errors.forEach((k, v) {
          if (v.isNotEmpty) map[k] = v.first;
        });
        setState(() {
          _fieldErrors = map;
          _error = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        setState(() {
          _fieldErrors = {};
          _error = e.toString().replaceFirst('Exception: ', '');
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ScreenTitleHeader(
                      title: 'Add Reservation',
                      subtitle: 'Book a table for your guests',
                      icon: Icons.calendar_today_rounded,
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF4A4A4A)),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Table Dropdown
                    DropdownButtonFormField<int>(
                      value: _selectedTableId,
                      decoration: InputDecoration(
                        labelText: 'Table',
                        errorText: _fieldErrors['tableId'],
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: _tables.map((table) {
                        return DropdownMenuItem<int>(
                          value: table['id'],
                          child: Text('Table ${table['tableNumber']} (Capacity: ${table['capacity']})'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedTableId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) return 'Please select a table.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Date Picker
                    InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Reservation Date',
                          errorText: _fieldErrors['reservationDate'],
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          DateFormat('yyyy-MM-dd').format(_selectedDate),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Time Picker
                    InkWell(
                      onTap: _selectTime,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Reservation Time',
                          errorText: _fieldErrors['reservationTime'],
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                          suffixIcon: const Icon(Icons.access_time),
                        ),
                        child: Text(
                          _selectedTime.format(context),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Duration
                    DropdownButtonFormField<int>(
                      value: _durationHours,
                      decoration: const InputDecoration(
                        labelText: 'Duration (hours)',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: [1, 2, 3, 4, 5, 6].map((hours) {
                        return DropdownMenuItem<int>(
                          value: hours,
                          child: Text('$hours hour${hours > 1 ? 's' : ''}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _durationHours = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Number of Guests
                    TextFormField(
                      initialValue: _numberOfGuests.toString(),
                      decoration: InputDecoration(
                        labelText: 'Number of Guests',
                        errorText: _fieldErrors['numberOfGuests'],
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter number of guests.';
                        final guests = int.tryParse(value);
                        if (guests == null || guests <= 0 || guests > 50) return 'Number of guests must be between 1 and 50.';
                        return null;
                      },
                      onSaved: (value) {
                        _numberOfGuests = int.parse(value ?? '2');
                      },
                      onChanged: (value) {
                        final guests = int.tryParse(value);
                        if (guests != null && guests > 0) {
                          _numberOfGuests = guests;
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Special Requests
                    TextFormField(
                      initialValue: _specialRequests,
                      decoration: InputDecoration(
                        labelText: 'Special Requests (optional)',
                        errorText: _fieldErrors['specialRequests'],
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      maxLines: 3,
                      onChanged: (value) {
                        _specialRequests = value;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Error message
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    
                    // Submit Button
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReservation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B7355),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Create Reservation',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

