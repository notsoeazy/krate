import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Generic GET request
  Future<Map<String, dynamic>> getRequest(String url) async {
    try {
      final response = await http.get(Uri.parse(url), headers: defaultHeaders);

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
    } catch (e) {
      // You can add logging or retries here
      rethrow;
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
