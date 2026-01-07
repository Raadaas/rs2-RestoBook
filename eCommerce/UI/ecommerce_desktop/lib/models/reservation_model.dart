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
  final String duration; // Format: "HH:mm:ss"
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
    required this.duration,
    required this.numberOfGuests,
    required this.status,
    this.specialRequests,
    this.qrCode,
    required this.createdAt,
    this.confirmedAt,
    this.cancelledAt,
    this.cancellationReason,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      userName: json['userName'] ?? '',
      restaurantId: json['restaurantId'] ?? 0,
      restaurantName: json['restaurantName'] ?? '',
      tableId: json['tableId'] ?? 0,
      tableNumber: json['tableNumber'] ?? '',
      reservationDate: json['reservationDate'] != null
          ? DateTime.parse(json['reservationDate'])
          : DateTime.now(),
      reservationTime: json['reservationTime'] ?? '00:00:00',
      duration: json['duration'] ?? '02:00:00',
      numberOfGuests: json['numberOfGuests'] ?? 0,
      status: json['status'] ?? 'Pending',
      specialRequests: json['specialRequests'],
      qrCode: json['qrCode'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.parse(json['confirmedAt'])
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'])
          : null,
      cancellationReason: json['cancellationReason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'tableId': tableId,
      'tableNumber': tableNumber,
      'reservationDate': reservationDate.toIso8601String(),
      'reservationTime': reservationTime,
      'duration': duration,
      'numberOfGuests': numberOfGuests,
      'status': status,
      'specialRequests': specialRequests,
      'qrCode': qrCode,
      'createdAt': createdAt.toIso8601String(),
      'confirmedAt': confirmedAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'cancellationReason': cancellationReason,
    };
  }
}

