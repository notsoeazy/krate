import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class KrateNetworkException implements Exception {
  final String message;
  final bool isTimeout;
  final bool isNoInternet;

  KrateNetworkException(
    this.message, {
    this.isTimeout = false,
    this.isNoInternet = false,
  });

  @override
  String toString() => message;
}

class ApiService {
  final Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static const Duration _timeout = Duration(seconds: 15);

  /// Generic GET request
  Future<Map<String, dynamic>> getRequest(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: defaultHeaders)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        } else {
          throw Exception('API returned unexpected response format');
        }
      } else {
        throw Exception(
          'API Error: ${response.statusCode} ${response.reasonPhrase}',
        );
      }
    } on SocketException {
      throw KrateNetworkException(
        'No internet connection. Please check your network settings.',
        isNoInternet: true,
      );
    } on TimeoutException {
      throw KrateNetworkException(
        'Request timed out. The server took too long to respond.',
        isTimeout: true,
      );
    } catch (e) {
      if (e is KrateNetworkException) rethrow;
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Generic GET request that returns a list of items
  Future<List<Map<String, dynamic>>> getRequestList(
    String url, {
    String listKey = 'results',
  }) async {
    final data = await getRequest(url);
    if (data.containsKey(listKey) && data[listKey] is List) {
      return List<Map<String, dynamic>>.from(data[listKey]);
    } else {
      throw Exception('API returned unexpected list format for key "$listKey"');
    }
  }
}
