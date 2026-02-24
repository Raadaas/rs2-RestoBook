import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_desktop/models/table_model.dart' as table_model;
import 'package:ecommerce_desktop/providers/table_provider.dart';
import 'package:ecommerce_desktop/widgets/screen_title_header.dart';

class TableLayoutScreen extends StatefulWidget {
  final int restaurantId;

  const TableLayoutScreen({
    super.key,
    required this.restaurantId,
  });

  @override
  State<TableLayoutScreen> createState() => _TableLayoutScreenState();
}

class _TableLayoutScreenState extends State<TableLayoutScreen> {
  table_model.Table? _selectedTable;
  bool _isLoading = true;
  List<table_model.Table> _tables = [];
  final TableProvider _tableProvider = TableProvider();
  
  // Form controllers
  final TextEditingController _tableNumberController = TextEditingController();
  int _selectedCapacity = 4;
  String? _selectedTableType;
  int? _selectedPositionX;
  int? _selectedPositionY;
  bool _isSaving = false;
  bool _isAdding = false;
  Map<String, String> _fieldErrors = {};

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  @override
  void dispose() {
    _tableNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadTables() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final result = await _tableProvider.get(
        filter: {
          'restaurantId': widget.restaurantId, 
          'isActive': true,
          'RetrieveAll': true, // CRITICAL: Retrieve all tables, not just first 10 (PascalCase for C# binding)
        },
      );
      setState(() {
        _tables = result.items ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load tables: $e')),
        );
      }
    }
  }

  void _selectTable(table_model.Table table) {
    setState(() {
      _selectedTable = table;
      _tableNumberController.text = table.tableNumber;
      _selectedCapacity = table.capacity;
      _selectedTableType = table.tableType;
      _selectedPositionX = table.positionX?.round();
      _selectedPositionY = table.positionY?.round();
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedTable = null;
      _tableNumberController.clear();
      _selectedCapacity = 4;
      _selectedTableType = null;
      _selectedPositionX = null;
      _selectedPositionY = null;
    });
  }

  Future<void> _saveTable() async {
    if (_selectedTable == null) return;
    if (_tableNumberController.text.isEmpty) {
      setState(() => _fieldErrors = {'tableNumber': 'Please enter a table number'});
      return;
    }
    if (_selectedTableType == null) {
      setState(() => _fieldErrors = {'tableType': 'Please select a table type'});
      return;
    }
    if (_selectedPositionX == null || _selectedPositionY == null) {
      setState(() => _fieldErrors = {'position': 'Please select X and Y positions'});
      return;
    }

    // Validate position range (1-8)
    if (_selectedPositionX! < 1 || _selectedPositionX! > 8 || 
        _selectedPositionY! < 1 || _selectedPositionY! > 8) {
      setState(() => _fieldErrors = {'position': 'Position X and Y must be between 1 and 8'});
      return;
    }

    // Check if position is already occupied by another table
    final existingTable = _getTableAtPosition(_selectedPositionY! - 1, _selectedPositionX! - 1);
    if (existingTable != null && existingTable.id != _selectedTable!.id) {
      setState(() => _fieldErrors = {'position': 'This position is already occupied by another table'});
      return;
    }

    setState(() {
      _fieldErrors = {};
      _isSaving = true;
    });

    try {
      final request = {
        'restaurantId': widget.restaurantId,
        'tableNumber': _tableNumberController.text,
        'capacity': _selectedCapacity,
        'tableType': _selectedTableType,
        'positionX': _selectedPositionX!.toDouble(),
        'positionY': _selectedPositionY!.toDouble(),
        'isActive': true,
      };

      await _tableProvider.update(_selectedTable!.id, request);
      await _loadTables();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Table updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update table: $e')),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _addTable() async {
    if (_tableNumberController.text.isEmpty) {
      setState(() => _fieldErrors = {'tableNumber': 'Please enter a table number'});
      return;
    }
    if (_selectedTableType == null) {
      setState(() => _fieldErrors = {'tableType': 'Please select a table type'});
      return;
    }
    if (_selectedPositionX == null || _selectedPositionY == null) {
      setState(() => _fieldErrors = {'position': 'Please select X and Y positions'});
      return;
    }

    // Validate position range (1-8)
    if (_selectedPositionX! < 1 || _selectedPositionX! > 8 || 
        _selectedPositionY! < 1 || _selectedPositionY! > 8) {
      setState(() => _fieldErrors = {'position': 'Position X and Y must be between 1 and 8'});
      return;
    }

    // Check if position is already occupied
    final existingTable = _getTableAtPosition(_selectedPositionY! - 1, _selectedPositionX! - 1);
    if (existingTable != null) {
      setState(() => _fieldErrors = {'position': 'This position is already occupied'});
      return;
    }

    setState(() {
      _fieldErrors = {};
      _isAdding = true;
    });

    try {
      final request = {
        'restaurantId': widget.restaurantId,
        'tableNumber': _tableNumberController.text,
        'capacity': _selectedCapacity,
        'tableType': _selectedTableType,
        'positionX': _selectedPositionX!.toDouble(),
        'positionY': _selectedPositionY!.toDouble(),
        'isActive': true,
      };

      // Insert returns the created table directly
      final newTable = await _tableProvider.insert(request);
      
      // Reload tables to get the updated list
      await _loadTables();
      
      // Select the newly added table
      setState(() {
        _selectedTable = newTable;
        _tableNumberController.text = newTable.tableNumber;
        _selectedCapacity = newTable.capacity;
        _selectedTableType = newTable.tableType;
        _selectedPositionX = newTable.positionX?.round();
        _selectedPositionY = newTable.positionY?.round();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Table added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add table: $e')),
        );
      }
    } finally {
      setState(() {
        _isAdding = false;
      });
    }
  }

  Future<void> _deleteTable() async {
    if (_selectedTable == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Table'),
        content: Text('Are you sure you want to delete table ${_selectedTable!.tableNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _tableProvider.delete(_selectedTable!.id);
      await _loadTables();
      
      setState(() {
        _selectedTable = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Table deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete table: $e')),
        );
      }
    }
  }


  void _onCellTap(int row, int col) {
    // row and col are 0-indexed in matrix, but positions are 1-indexed
    final existingTable = _getTableAtPosition(row, col);
    if (existingTable != null) {
      // Select existing table
      _selectTable(existingTable);
    } else {
      // Set position for new table (convert 0-indexed to 1-indexed)
      setState(() {
        _selectedPositionX = col + 1;
        _selectedPositionY = row + 1;
        if (_selectedTable == null) {
          // Clear form for new table
          _tableNumberController.clear();
          _selectedCapacity = 4;
          _selectedTableType = null;
        }
      });
    }
  }

  table_model.Table? _getTableAtPosition(int row, int col) {
    try {
      // Note: row and col are 0-indexed in the matrix (0-7), positions in DB are 1-indexed (1-8)
      // So if position in DB is (1,1), it should be at matrix position (0,0)
      // We need to convert: matrix (row, col) -> DB position (row+1, col+1)
      final dbX = col + 1;
      final dbY = row + 1;
      return _tables.firstWhere(
        (t) => t.isActive &&
              t.positionX != null && 
              t.positionY != null &&
              t.positionX!.round() == dbX && 
              t.positionY!.round() == dbY,
      );
    } catch (e) {
      return null;
    }
  }

  Color _getTableColor(String? tableType) {
    switch (tableType) {
      case 'Circle':
        return const Color(0xFF2E7D32); // Dark green
      case 'Square':
        return const Color(0xFF8B4513); // Brown
      case 'Rectangle':
        return const Color(0xFF6A1B9A); // Purple
      default:
        return const Color(0xFF757575); // Grey
    }
  }

  Widget _buildTableWidget(table_model.Table table) {
    final isSelected = _selectedTable?.id == table.id;
    // Use selected table type if this is the selected table and type was changed
    final tableType = (isSelected && _selectedTableType != null) 
        ? _selectedTableType! 
        : (table.tableType ?? 'Square');
    final color = _getTableColor(tableType);

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.all(tableType == 'Rectangle' ? 2 : 4),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: tableType == 'Circle' ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: tableType == 'Circle' 
              ? null 
              : BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? const Color(0xFFD4A574) : Colors.transparent,
            width: isSelected ? 3 : 0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              table.tableNumber,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people, color: Colors.white, size: 10),
                const SizedBox(width: 2),
                Text(
                  '${table.capacity}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloorPlan() {
    const int rows = 8;
    const int cols = 8;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: List.generate(rows, (row) {
            return Expanded(
              child: Row(
                children: List.generate(cols, (col) {
                  final table = _getTableAtPosition(row, col);
                  final isOccupied = table != null;
                  
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _onCellTap(row, col),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isOccupied 
                              ? Colors.transparent 
                              : const Color(0xFFF9F9F9),
                          border: Border.all(
                            color: const Color(0xFFE0E0E0),
                            width: 0.5,
                          ),
                        ),
                        child: isOccupied ? _buildTableWidget(table!) : null,
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildPropertiesPanel() {
    return Container(
      width: 350,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedTable == null ? 'Add New Table' : 'Table Properties',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A4A4A),
                ),
              ),
              if (_selectedTable != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _clearSelection,
                  tooltip: 'Clear selection',
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Table Number
          TextField(
            controller: _tableNumberController,
            onChanged: (_) => setState(() => _fieldErrors = Map.from(_fieldErrors)..remove('tableNumber')),
            decoration: InputDecoration(
              labelText: 'Table Number',
              errorText: _fieldErrors['tableNumber'],
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          // Capacity Dropdown
          DropdownButtonFormField<int>(
            value: _selectedCapacity,
            decoration: const InputDecoration(
              labelText: 'Capacity',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            items: [2, 4, 6, 8, 10].map((capacity) {
              return DropdownMenuItem(
                value: capacity,
                child: Text('$capacity guests'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCapacity = value ?? 4;
              });
            },
          ),
          const SizedBox(height: 16),
          // Table Type Dropdown
          DropdownButtonFormField<String>(
            value: _selectedTableType,
            decoration: InputDecoration(
              labelText: 'Table Type',
              errorText: _fieldErrors['tableType'],
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            items: ['Circle', 'Square', 'Rectangle'].map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedTableType = value;
                _fieldErrors = Map.from(_fieldErrors)..remove('tableType');
              });
            },
          ),
          const SizedBox(height: 16),
          // Position X and Y (8x8 matrix)
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedPositionX,
                  decoration: InputDecoration(
                    labelText: 'Position X (1-8)',
                    errorText: _fieldErrors['position'],
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: List.generate(8, (index) => index + 1).map((x) {
                    return DropdownMenuItem(
                      value: x,
                      child: Text('$x'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null && value >= 1 && value <= 8) {
                      setState(() {
                        _selectedPositionX = value;
                        _fieldErrors = Map.from(_fieldErrors)..remove('position');
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedPositionY,
                  decoration: InputDecoration(
                    labelText: 'Position Y (1-8)',
                    errorText: _fieldErrors['position'],
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: List.generate(8, (index) => index + 1).map((y) {
                    return DropdownMenuItem(
                      value: y,
                      child: Text('$y'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null && value >= 1 && value <= 8) {
                      setState(() {
                        _selectedPositionY = value;
                        _fieldErrors = Map.from(_fieldErrors)..remove('position');
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const Spacer(),
          // Action Buttons
          if (_selectedTable == null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isAdding || _isSaving) ? null : _addTable,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isAdding
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Add Table',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
              ),
            )
          else
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_isSaving || _isAdding) ? null : _saveTable,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B7355),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Save Changes',
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_isSaving || _isAdding) ? null : _deleteTable,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB71C1C),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Delete Table',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F0),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            // Left: Floor Plan
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ScreenTitleHeader(
                    title: 'Restaurant Floor Plan',
                    subtitle: 'Manage tables and layout',
                    icon: Icons.table_restaurant_rounded,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _buildFloorPlan(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Right: Properties Panel
            _buildPropertiesPanel(),
          ],
        ),
      ),
    );
  }
}
