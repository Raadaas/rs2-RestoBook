import 'dart:convert';

import 'package:ecommerce_mobile/model/search_result.dart';
import 'package:ecommerce_mobile/providers/validation_exception.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ecommerce_mobile/providers/auth_provider.dart';
import 'package:http/http.dart';

abstract class BaseProvider<T> with ChangeNotifier {
  static String? _baseUrl;
  String _endpoint = "";

  BaseProvider(String endpoint) {
    _endpoint = endpoint;
    _baseUrl = const String.fromEnvironment("baseUrl",
        defaultValue: "http://10.0.2.2:5121/api/");
  }

  static String _jwtLog() {
    final t = AuthProvider.token;
    if (t == null || t.isEmpty) return '(none)';
    final preview = t.length > 40 ? '${t.substring(0, 40)}...' : t;
    return 'Bearer $preview (length: ${t.length})';
  }

  Future<SearchResult<T>> get({dynamic filter}) async {
    var url = "$_baseUrl$_endpoint";

    if (filter != null) {
      var queryString = getQueryString(filter);
      if (queryString.startsWith('&')) queryString = '?${queryString.substring(1)}';
      else if (queryString.isNotEmpty && !queryString.startsWith('?')) queryString = '?$queryString';
      url = "$url$queryString";
    }

    var uri = Uri.parse(url);
    var headers = createHeaders();

    print("Requesting: $url");
    print("JWT: ${_jwtLog()}");
    var response = await http.get(uri, headers: headers);
    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);

      var result = SearchResult<T>();

      result.totalCount = data['totalCount'];
      result.items = List<T>.from(data["items"].map((e) => fromJson(e)));


      return result;
    } else {
      throw new Exception("Unknown error");
    }
  }

  Future<T> insert(dynamic request) async {
    var url = "$_baseUrl$_endpoint";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    print("Requesting: $url");
    print("JWT: ${_jwtLog()}");
    var jsonRequest = jsonEncode(request);
    var response = await http.post(uri, headers: headers, body: jsonRequest);
    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 400) {
      _throwValidationException(response.body);
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      var decoded = jsonDecode(response.body);
      var data = decoded is Map && decoded['data'] != null ? decoded['data'] : decoded;
      return fromJson(data);
    }
    if (response.statusCode == 401) {
      AuthProvider.clear();
      AuthProvider.onUnauthorized?.call();
      throw Exception("Unauthorized");
    }
    throw Exception("Something went wrong. Please try again.");
  }

  Future<T> update(int id, [dynamic request]) async {
    var url = "$_baseUrl$_endpoint/$id";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    print("Requesting: $url");
    print("JWT: ${_jwtLog()}");
    var jsonRequest = jsonEncode(request);
    var response = await http.put(uri, headers: headers, body: jsonRequest);
    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 400) {
      _throwValidationException(response.body);
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      var decoded = jsonDecode(response.body);
      var data = decoded is Map && decoded['data'] != null ? decoded['data'] : decoded;
      return fromJson(data);
    }
    if (response.statusCode == 401) {
      AuthProvider.clear();
      AuthProvider.onUnauthorized?.call();
      throw Exception("Unauthorized");
    }
    throw Exception("Something went wrong. Please try again.");
  }

  void _throwValidationException(String body) {
    try {
      final err = jsonDecode(body);
      if (err is Map && err['errors'] != null && err['errors'] is Map) {
        final errors = <String, List<String>>{};
        (err['errors'] as Map).forEach((key, value) {
          if (value is List) {
            errors[key.toString()] = value.map((e) => e.toString()).toList();
          } else if (value is String) {
            errors[key.toString()] = [value];
          }
        });
        throw ValidationException(errors);
      }
    } catch (e) {
      if (e is ValidationException) rethrow;
    }
    throw Exception(body.isNotEmpty ? body : 'Please check your input.');
  }

  Future<void> delete(int id) async {
    var url = "$_baseUrl$_endpoint/$id";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    print("Requesting: $url");
    print("JWT: ${_jwtLog()}");
    var response = await http.delete(uri, headers: headers);
    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (!isValidResponse(response)) throw new Exception("Delete failed");
  }

  T fromJson(data) {
    throw Exception("Method not implemented");
  }

  bool isValidResponse(Response response) {
    if (response.statusCode < 299) {
      return true;
    } else if (response.statusCode == 401) {
      AuthProvider.clear();
      AuthProvider.onUnauthorized?.call();
      throw Exception("Unauthorized");
    } else {
      print(response.body);
      throw new Exception("Something bad happened please try again");
    }
  }

  Map<String, String> createHeaders() {
    final t = AuthProvider.token;
    final auth = t != null && t.isNotEmpty
        ? "Bearer $t"
        : (AuthProvider.username != null && AuthProvider.password != null
            ? "Basic ${base64Encode(utf8.encode('${AuthProvider.username}:${AuthProvider.password}'))}"
            : null);
    var headers = <String, String>{"Content-Type": "application/json"};
    if (auth != null) headers["Authorization"] = auth;
    return headers;
  }

  String getQueryString(Map params,
      {String prefix = '&', bool inRecursion = false}) {
    String query = '';
    params.forEach((key, value) {
      if (inRecursion) {
        if (key is int) {
          key = '[$key]';
        } else if (value is List || value is Map) {
          key = '.$key';
        } else {
          key = '.$key';
        }
      }
      if (value is String || value is int || value is double || value is bool) {
        var encoded = value;
        if (value is String) {
          encoded = Uri.encodeComponent(value);
        } else if (value is bool) {
          encoded = value.toString().toLowerCase(); // Convert bool to lowercase string for backend
        }
        query += '$prefix$key=$encoded';
      } else if (value is DateTime) {
        query += '$prefix$key=${(value as DateTime).toIso8601String()}';
      } else if (value is List || value is Map) {
        if (value is List) value = value.asMap();
        value.forEach((k, v) {
          query +=
              getQueryString({k: v}, prefix: '$prefix$key', inRecursion: true);
        });
      }
    });
    return query;
  }
}
