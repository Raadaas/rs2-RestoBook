import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ecommerce_mobile/providers/reservation_provider.dart';
import 'package:ecommerce_mobile/providers/auth_provider.dart';
import 'package:ecommerce_mobile/providers/validation_exception.dart';
import 'package:http/http.dart' as http;
import 'package:ecommerce_mobile/app_styles.dart';

const Color _brown = Color(0xFF8B7355);

class BookReservationScreen extends StatefulWidget {
  final int restaurantId;
  final String restaurantName;

  const BookReservationScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<BookReservationScreen> createState() => _BookReservationScreenState();
}

/// Maps backend validation field names to UI field keys.
const Map<String, String> _backendFieldToUi = {
  'TableId': 'table',
  'tableId': 'table',
  'ReservationDate': 'date',
  'reservationDate': 'date',
  'ReservationTime': 'time',
  'reservationTime': 'time',
  'Duration': 'duration',
  'duration': 'duration',
  'NumberOfGuests': 'guests',
  'numberOfGuests': 'guests',
  'SpecialRequests': 'specialRequests',
  'specialRequests': 'specialRequests',
};

class _BookReservationScreenState extends State<BookReservationScreen> {
  List<Map<String, dynamic>> _tables = [];
  int? _selectedTableId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay(hour: 19, minute: 0);
  int _numberOfGuests = 2;
  String _selectedDuration = '02:00:00';
  String _specialRequests = '';
  bool _loading = true;
  Map<String, String> _fieldErrors = {};
  String? _generalError;
  final ScrollController _scrollController = ScrollController();

  static const Map<String, String> _durationOptions = {
    '1 minute': '00:01:00',
    '1 hour': '01:00:00',
    '2 hours': '02:00:00',
    '3 hours': '03:00:00',
    '6 hours': '06:00:00',
  };
  bool _submitting = false;

  static String get _baseUrl =>
      const String.fromEnvironment("baseUrl", defaultValue: "http://10.0.2.2:5121/api/");

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTables() async {
    setState(() => _loading = true);
    try {
      final provider = context.read<ReservationProvider>();
      final url = Uri.parse("${_baseUrl}tables?restaurantId=${widget.restaurantId}");
      final response = await http.get(url, headers: provider.createHeaders());
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] as List<dynamic>?;
        final tables = items?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
        if (mounted) {
          setState(() {
            _tables = tables;
            _loading = false;
          });
        }
      } else {
        setState(() {
          _tables = [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _tables = [];
          _loading = false;
        });
      }
    }
  }

  void _clearErrors() {
    setState(() {
      _fieldErrors = {};
      _generalError = null;
    });
  }

  void _setFieldError(String key, String message) {
    setState(() {
      _fieldErrors = {..._fieldErrors, key: message};
      _generalError = null;
    });
    _scrollToFirstError();
  }

  void _setErrorsFromValidation(ValidationException e) {
    final fieldErrors = <String, String>{};
    for (final entry in e.errors.entries) {
      final uiKey = _backendFieldToUi[entry.key] ?? entry.key;
      if (entry.value.isNotEmpty) {
        fieldErrors[uiKey] = entry.value.first;
      }
    }
    setState(() {
      _fieldErrors = fieldErrors;
      _generalError = fieldErrors.isEmpty ? e.message : null;
    });
    _scrollToFirstError();
  }

  void _scrollToFirstError() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _submit() async {
    _clearErrors();
    final userId = AuthProvider.userId;
    if (userId == null) {
      setState(() => _generalError = 'Please log in to make a reservation');
      _scrollToFirstError();
      return;
    }
    if (_selectedTableId == null) {
      _setFieldError('table', 'Please select a table');
      return;
    }
    setState(() => _submitting = true);
    try {
      final reservationTime =
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}:00';
      final reservationDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      final request = {
        'userId': userId,
        'restaurantId': widget.restaurantId,
        'tableId': _selectedTableId,
        'reservationDate': reservationDateTime.toIso8601String(),
        'reservationTime': reservationTime,
        'duration': _selectedDuration,
        'numberOfGuests': _numberOfGuests,
        if (_specialRequests.isNotEmpty) 'specialRequests': _specialRequests,
      };
      await context.read<ReservationProvider>().createReservation(request);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reservation requested successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } on ValidationException catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        _setErrorsFromValidation(e);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _generalError = 'Something went wrong. Please try again.';
        });
        _scrollToFirstError();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        foregroundColor: const Color(0xFF333333),
        title: const Text('Book a Table', style: kScreenTitleStyle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(19),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: kScreenTitleUnderline(margin: EdgeInsets.zero),
          ),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: _brown))
          : SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _brown.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _brown.withOpacity(0.2)),
                    ),
                    child: Text(
                      widget.restaurantName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _brown,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_tables.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No tables available for this restaurant.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  else ...[
                    _buildSection('Select table', _buildTableMatrix(), errorKey: 'table'),
                    const SizedBox(height: 20),
                    _buildSection('Date', _buildDateField(), errorKey: 'date'),
                    const SizedBox(height: 20),
                    _buildSection('Time', _buildTimeField(), errorKey: 'time'),
                    const SizedBox(height: 20),
                    _buildSection('Duration', _buildDurationDropdown(), errorKey: 'duration'),
                    const SizedBox(height: 20),
                    _buildSection('Guests', _buildGuestsSelector(), errorKey: 'guests'),
                    const SizedBox(height: 20),
                    _buildSection('Special requests (optional)', _buildSpecialRequestsField(), errorKey: 'specialRequests'),
                    if (_generalError != null || _fieldErrors.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade400, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red.shade800, size: 22),
                                const SizedBox(width: 8),
                                Text(
                                  'Validation errors:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.red.shade900,
                                  ),
                                ),
                              ],
                            ),
                            if (_generalError != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                _generalError!,
                                style: TextStyle(fontSize: 13, color: Colors.red.shade900),
                              ),
                            ],
                            ..._fieldErrors.entries.map((e) => Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '• ${e.value}',
                                    style: TextStyle(fontSize: 13, color: Colors.red.shade900),
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _brown,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Confirm Reservation'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String label, Widget child, {String? errorKey}) {
    final error = errorKey != null ? _fieldErrors[errorKey] : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _brown.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 8),
        InputDecorator(
          decoration: InputDecoration(
            errorText: error,
            errorStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.error,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
          child: child,
        ),
      ],
    );
  }

  Map<String, dynamic>? _getTableAtPosition(int row, int col) {
    final dbX = col + 1;
    final dbY = row + 1;
    try {
      return _tables.firstWhere((t) {
        final px = t['positionX'];
        final py = t['positionY'];
        if (px == null || py == null) return false;
        return (px is num ? px.toDouble() : double.tryParse(px.toString()) ?? 0).round() == dbX &&
            (py is num ? py.toDouble() : double.tryParse(py.toString()) ?? 0).round() == dbY;
      });
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> _getTablesWithoutPosition() {
    return _tables.where((t) {
      final px = t['positionX'];
      final py = t['positionY'];
      return px == null || py == null;
    }).toList();
  }

  Widget _buildTableMatrix() {
    const int rows = 8;
    const int cols = 8;
    final tablesWithoutPos = _getTablesWithoutPosition();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 340,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _brown.withOpacity(0.2)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: List.generate(rows, (row) {
                return Expanded(
                  child: Row(
                    children: List.generate(cols, (col) {
                      final table = _getTableAtPosition(row, col);
                      final id = table?['id'] as int?;
                      final isSelected = _selectedTableId == id;
                      final number = table?['tableNumber'] ?? '?';
                      final capacity = table?['capacity'] ?? 0;

                      return Expanded(
                        child: GestureDetector(
                          onTap: table != null
                              ? () => setState(() {
                                    _selectedTableId = id;
                                    _fieldErrors = Map.from(_fieldErrors)..remove('table');
                                  })
                              : null,
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: table != null
                                  ? (isSelected ? _brown : _brown.withOpacity(0.6))
                                  : _brown.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected ? _brown : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: table != null
                                ? Center(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            number,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.people, color: Colors.white, size: 9),
                                              const SizedBox(width: 2),
                                              Text(
                                                '$capacity',
                                                style: const TextStyle(color: Colors.white, fontSize: 9),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
        ),
        if (tablesWithoutPos.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Other tables',
            style: TextStyle(fontSize: 12, color: _brown.withOpacity(0.7), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tablesWithoutPos.map((t) {
              final id = t['id'] as int?;
              final isSelected = _selectedTableId == id;
              final number = t['tableNumber'] ?? '?';
              final capacity = t['capacity'] ?? 0;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedTableId = id;
                  _fieldErrors = Map.from(_fieldErrors)..remove('table');
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? _brown : _brown.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? _brown : _brown.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    'Table $number ($capacity)',
                    style: TextStyle(
                      color: isSelected ? Colors.white : _brown,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        if (_selectedTableId != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              "Selected: Table ${_tables.where((t) => t['id'] == _selectedTableId).map((t) => t['tableNumber'] ?? '?').firstOrNull ?? '?'}",
              style: TextStyle(fontSize: 13, color: _brown.withOpacity(0.9)),
            ),
          ),
      ],
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) setState(() {
          _selectedDate = picked;
          _fieldErrors = Map.from(_fieldErrors)..remove('date');
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _brown.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: _brown.withOpacity(0.7), size: 22),
            const SizedBox(width: 12),
            Text(
              DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
              style: TextStyle(fontSize: 16, color: _brown.withOpacity(0.9)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeField() {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: _selectedTime,
        );
        if (picked != null) setState(() {
          _selectedTime = picked;
          _fieldErrors = Map.from(_fieldErrors)..remove('time');
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _brown.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: _brown.withOpacity(0.7), size: 22),
            const SizedBox(width: 12),
            Text(
              _selectedTime.format(context),
              style: TextStyle(fontSize: 16, color: _brown.withOpacity(0.9)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _brown.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedDuration,
          isExpanded: true,
          items: _durationOptions.entries.map((e) {
            return DropdownMenuItem<String>(
              value: e.value,
              child: Text(e.key),
            );
          }).toList(),
          onChanged: (v) => setState(() {
            _selectedDuration = v ?? '02:00:00';
            _fieldErrors = Map.from(_fieldErrors)..remove('duration');
          }),
        ),
      ),
    );
  }

  Widget _buildGuestsSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _brown.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _numberOfGuests > 1 ? () => setState(() {
              _numberOfGuests--;
              _fieldErrors = Map.from(_fieldErrors)..remove('guests');
            }) : null,
            icon: Icon(Icons.remove_circle_outline, color: _brown.withOpacity(0.8)),
          ),
          Text(
            '$_numberOfGuests',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _brown),
          ),
          IconButton(
            onPressed: () => setState(() {
              _numberOfGuests++;
              _fieldErrors = Map.from(_fieldErrors)..remove('guests');
            }),
            icon: Icon(Icons.add_circle_outline, color: _brown.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialRequestsField() {
    return TextField(
      onChanged: (v) => setState(() {
        _specialRequests = v;
        _fieldErrors = Map.from(_fieldErrors)..remove('specialRequests');
      }),
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Allergies, preferences, etc.',
        hintStyle: TextStyle(color: _brown.withOpacity(0.4)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _brown.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _brown.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _brown, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
