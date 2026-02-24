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
        _fieldErrors = Map.from(_fieldErrors)..remove('reservationDate');
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
        _fieldErrors = Map.from(_fieldErrors)..remove('reservationTime');
      });
    }
  }

  Future<void> _submitReservation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final userId = AuthProvider.userId;
    if (userId == null) {
      setState(() {
        _error = 'User not logged in';
        _fieldErrors = {};
      });
      return;
    }

    if (_selectedTableId == null) {
      setState(() {
        _error = null;
        _fieldErrors = {'tableId': 'Please select a table'};
      });
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
        const keyMap = {
          'TableId': 'tableId', 'tableId': 'tableId',
          'ReservationDate': 'reservationDate', 'reservationDate': 'reservationDate',
          'ReservationTime': 'reservationTime', 'reservationTime': 'reservationTime',
          'NumberOfGuests': 'numberOfGuests', 'numberOfGuests': 'numberOfGuests',
          'SpecialRequests': 'specialRequests', 'specialRequests': 'specialRequests',
        };
        final map = <String, String>{};
        String? generalError;
        e.errors.forEach((k, v) {
          if (v.isNotEmpty) {
            if (k == 'userError') {
              generalError = v.first;
            } else {
              map[keyMap[k] ?? k] = v.first;
            }
          }
        });
        if (mounted) {
          setState(() {
            _fieldErrors = map;
            _error = generalError;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _fieldErrors = {};
            _error = e.toString().replaceFirst('Exception: ', '');
          });
        }
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  static InputDecoration _inputDecoration(String label, String? errorText) {
    return InputDecoration(
      labelText: label,
      errorText: errorText,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF8B7355), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red[400]!, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
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
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B7355).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.table_restaurant_rounded,
                                  color: Color(0xFF8B7355),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Text(
                                'Reservation Details',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4A4A4A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                    DropdownButtonFormField<int>(
                      value: _selectedTableId,
                      decoration: _inputDecoration('Table', _fieldErrors['tableId']).copyWith(
                        prefixIcon: Icon(Icons.table_restaurant_rounded, color: Colors.grey[500], size: 22),
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
                          _fieldErrors = Map.from(_fieldErrors)..remove('tableId');
                        });
                      },
                      validator: (value) {
                        if (value == null) return 'Please select a table.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: _inputDecoration('Reservation Date', _fieldErrors['reservationDate']).copyWith(
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          DateFormat('yyyy-MM-dd').format(_selectedDate),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    InkWell(
                      onTap: _selectTime,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: _inputDecoration('Reservation Time', _fieldErrors['reservationTime']).copyWith(
                          suffixIcon: const Icon(Icons.access_time),
                        ),
                        child: Text(
                          _selectedTime.format(context),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<int>(
                      value: _durationHours,
                      decoration: _inputDecoration('Duration (hours)', null).copyWith(
                        prefixIcon: Icon(Icons.schedule_rounded, color: Colors.grey[500], size: 22),
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
                    const SizedBox(height: 20),
                    TextFormField(
                      initialValue: _numberOfGuests.toString(),
                      decoration: _inputDecoration('Number of Guests', _fieldErrors['numberOfGuests']).copyWith(
                        prefixIcon: Icon(Icons.people_rounded, color: Colors.grey[500], size: 22),
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
                          setState(() {
                            _numberOfGuests = guests;
                            _fieldErrors = Map.from(_fieldErrors)..remove('numberOfGuests');
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      initialValue: _specialRequests,
                      decoration: _inputDecoration('Special Requests (optional)', _fieldErrors['specialRequests']).copyWith(
                        prefixIcon: Icon(Icons.note_rounded, color: Colors.grey[500], size: 22),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                      onChanged: (value) {
                        setState(() {
                          _specialRequests = value;
                          _fieldErrors = Map.from(_fieldErrors)..remove('specialRequests');
                        });
                      },
                    ),
                        ],
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red[700], fontSize: 14),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          ),
                          child: Text('Cancel', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500)),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitReservation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B7355),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add_rounded, size: 20),
                                    SizedBox(width: 10),
                                    Text('Create Reservation'),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

