import 'package:json_annotation/json_annotation.dart';

part 'table_model.g.dart';

@JsonSerializable()
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

  factory Table.fromJson(Map<String, dynamic> json) => _$TableFromJson(json);
  Map<String, dynamic> toJson() => _$TableToJson(this);
}

