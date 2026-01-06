import 'package:json_annotation/json_annotation.dart';

part 'reservation_model.g.dart';

@JsonSerializable()
class Reservation {
  final int id;
  final int userId;
  final String userName;
  final int restaurantId;
  final String restaurantName;
  final int tableId;
  final String tableNumber;
  final DateTime reservationDate;
  final String reservationTime;
  final int numberOfGuests;
  final String status;
  final String? specialRequests;
  final String? qrCode;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;

  Reservation({
    required this.id,
    required this.userId,
    required this.userName,
    required this.restaurantId,
    required this.restaurantName,
    required this.tableId,
    required this.tableNumber,
    required this.reservationDate,
    required this.reservationTime,
    required this.numberOfGuests,
    required this.status,
    this.specialRequests,
    this.qrCode,
    required this.createdAt,
    this.confirmedAt,
    this.cancelledAt,
    this.cancellationReason,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) =>
      _$ReservationFromJson(json);
  Map<String, dynamic> toJson() => _$ReservationToJson(this);
}

