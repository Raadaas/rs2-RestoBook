import 'dart:convert';

import 'package:ecommerce_mobile/model/chat_models.dart';
import 'package:ecommerce_mobile/providers/auth_provider.dart';
import 'package:http/http.dart' as http;

class ChatProvider {
  static String get baseUrl {
    return const String.fromEnvironment(
      "baseUrl",
      defaultValue: "http://10.0.2.2:5121/api/",
    );
  }

  static Map<String, String> _createHeaders() {
    final username = AuthProvider.username ?? "";
    final password = AuthProvider.password ?? "";
    final basicAuth = "Basic ${base64Encode(utf8.encode('$username:$password'))}";

    return {
      "Content-Type": "application/json",
      "Authorization": basicAuth,
    };
  }

  static Future<List<ChatConversation>> getMyConversations() async {
    final url = Uri.parse("${baseUrl}chat/conversations");
    final response = await http.get(url, headers: _createHeaders());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => ChatConversation.fromJson(e)).toList();
      }
      return [];
    }

    throw Exception(
        "Failed to load conversations: ${response.statusCode} - ${response.body}");
  }

  static Future<ChatConversation?> getConversation(int restaurantId) async {
    final url = Uri.parse("${baseUrl}chat/conversations/get-or-create");
    final body = jsonEncode({'restaurantId': restaurantId});
    final response =
        await http.post(url, headers: _createHeaders(), body: body);

    // 200 or 204 both mean "no conversation exists yet" (which is valid)
    if (response.statusCode == 200 || response.statusCode == 204) {
      if (response.body.isEmpty || response.body.trim() == 'null') {
        return null; // No conversation exists yet
      }
      final data = jsonDecode(response.body);
      if (data == null) return null;
      return ChatConversation.fromJson(data);
    }

    throw Exception(
        "Failed to get conversation: ${response.statusCode} - ${response.body}");
  }

  static Future<ChatMessage> sendFirstMessage(
      int restaurantId, String messageText) async {
    final url = Uri.parse("${baseUrl}chat/restaurants/$restaurantId/messages/first");
    final body = jsonEncode({'messageText': messageText});

    final response =
        await http.post(url, headers: _createHeaders(), body: body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ChatMessage.fromJson(data);
    }

    throw Exception(
        "Failed to send first message: ${response.statusCode} - ${response.body}");
  }

  static Future<List<ChatMessage>> getMessages(
    int conversationId, {
    int? afterId,
    int page = 0,
    int pageSize = 50,
  }) async {
    final qs = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      if (afterId != null) 'afterId': afterId.toString(),
    };

    final url = Uri.parse("${baseUrl}chat/conversations/$conversationId/messages")
        .replace(queryParameters: qs);

    final response = await http.get(url, headers: _createHeaders());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => ChatMessage.fromJson(e)).toList();
      }
      return [];
    }

    throw Exception(
        "Failed to load messages: ${response.statusCode} - ${response.body}");
  }

  static Future<ChatMessage> sendMessage(
      int conversationId, String messageText) async {
    final url = Uri.parse("${baseUrl}chat/conversations/$conversationId/messages");
    final body = jsonEncode({'messageText': messageText});

    final response =
        await http.post(url, headers: _createHeaders(), body: body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ChatMessage.fromJson(data);
    }

    throw Exception(
        "Failed to send message: ${response.statusCode} - ${response.body}");
  }

  static Future<int> markRead(int conversationId) async {
    final url = Uri.parse("${baseUrl}chat/conversations/$conversationId/read");
    final response =
        await http.post(url, headers: _createHeaders(), body: "{}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['updated'] ?? 0;
    }

    throw Exception(
        "Failed to mark read: ${response.statusCode} - ${response.body}");
  }

  static Future<void> deleteConversation(int conversationId) async {
    final url = Uri.parse("${baseUrl}chat/conversations/$conversationId");
    final response = await http.delete(url, headers: _createHeaders());

    if (response.statusCode != 204) {
      throw Exception(
          "Failed to delete conversation: ${response.statusCode} - ${response.body}");
    }
  }
}

