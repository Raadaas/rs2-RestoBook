class Table {
  final int id;
  final int restaurantId;
  final String restaurantName;
  final String tableNumber;
  final int capacity;
  final double? positionX;
  final double? positionY;
  final String? tableType;
  final bool isActive;
  final String status; // available, occupied, reserved

  Table({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.tableNumber,
    required this.capacity,
    this.positionX,
    this.positionY,
    this.tableType,
    required this.isActive,
    required this.status,
  });

  factory Table.fromJson(Map<String, dynamic> json) {
    return Table(
      id: json['id'] ?? 0,
      restaurantId: json['restaurantId'] ?? 0,
      restaurantName: json['restaurantName'] ?? '',
      tableNumber: json['tableNumber'] ?? '',
      capacity: json['capacity'] ?? 0,
      positionX: json['positionX'] != null ? (json['positionX'] as num).toDouble() : null,
      positionY: json['positionY'] != null ? (json['positionY'] as num).toDouble() : null,
      tableType: json['tableType'],
      isActive: json['isActive'] ?? true,
      status: json['status'] ?? 'available',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'tableNumber': tableNumber,
      'capacity': capacity,
      'positionX': positionX,
      'positionY': positionY,
      'tableType': tableType,
      'isActive': isActive,
      'status': status,
    };
  }
}

