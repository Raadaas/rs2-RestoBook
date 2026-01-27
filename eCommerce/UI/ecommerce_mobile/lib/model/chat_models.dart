DateTime _parseDateTime(dynamic value) {
  if (value is String) {
    // If the string has 'Z' at the end, it's UTC
    if (value.endsWith('Z')) {
      return DateTime.parse(value).toLocal();
    }
    // If it has timezone offset (e.g., +01:00 or -05:00), parse as is
    if (value.contains(RegExp(r'[+-]\d{2}:\d{2}$'))) {
      return DateTime.parse(value).toLocal();
    }
    // No timezone info - assume UTC from server and add 'Z'
    return DateTime.parse(value + 'Z').toLocal();
  }
  return DateTime.now();
}

class ChatConversation {
  final int id;
  final int userId;
  final String userName;
  final int restaurantId;
  final String restaurantName;
  final DateTime startedAt;
  final DateTime lastMessageAt;
  final String status;
  final String? lastMessageText;
  final int unreadCount;

  ChatConversation({
    required this.id,
    required this.userId,
    required this.userName,
    required this.restaurantId,
    required this.restaurantName,
    required this.startedAt,
    required this.lastMessageAt,
    required this.status,
    required this.lastMessageText,
    required this.unreadCount,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      userName: (json['userName'] ?? '') as String,
      restaurantId: json['restaurantId'] ?? 0,
      restaurantName: (json['restaurantName'] ?? '') as String,
      startedAt: json['startedAt'] != null
          ? _parseDateTime(json['startedAt'])
          : DateTime.now(),
      lastMessageAt: json['lastMessageAt'] != null
          ? _parseDateTime(json['lastMessageAt'])
          : DateTime.now(),
      status: (json['status'] ?? '') as String,
      lastMessageText: json['lastMessageText'],
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}

class ChatMessage {
  final int id;
  final int conversationId;
  final int senderId;
  final String senderName;
  final String messageText;
  final DateTime sentAt;
  final bool isRead;
  final DateTime? readAt;
  final bool isFromRestaurant;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.messageText,
    required this.sentAt,
    required this.isRead,
    required this.readAt,
    required this.isFromRestaurant,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? 0,
      conversationId: json['conversationId'] ?? 0,
      senderId: json['senderId'] ?? 0,
      senderName: (json['senderName'] ?? '') as String,
      messageText: (json['messageText'] ?? '') as String,
      sentAt: json['sentAt'] != null
          ? _parseDateTime(json['sentAt'])
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
      readAt: json['readAt'] != null ? _parseDateTime(json['readAt']) : null,
      isFromRestaurant: json['isFromRestaurant'] ?? false,
    );
  }
}

