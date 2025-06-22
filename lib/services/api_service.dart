import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:apprendi/constants/api_base.dart';

class ApiService {
  static final String _baseUrl = ApiBase.baseUrl;

  static Map<String, String> _buildHeaders(String? token) => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  static Future<http.Response> get(String endpoint, {String? token}) {
    return http.get(
      Uri.parse('$_baseUrl$endpoint'),
      headers: _buildHeaders(token),
    );
  }

  static Future<http.Response> post(
    String endpoint, {
    required Map<String, dynamic> body,
    String? token,
  }) {
    return http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: _buildHeaders(token),
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> put(
    String endpoint, {
    required Map<String, dynamic> body,
    String? token,
  }) {
    return http.put(
      Uri.parse('$_baseUrl$endpoint'),
      headers: _buildHeaders(token),
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> patch(
    String endpoint, {
    required Map<String, dynamic> body,
    String? token,
  }) {
    return http.patch(
      Uri.parse('$_baseUrl$endpoint'),
      headers: _buildHeaders(token),
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> delete(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) {
    return http.delete(
      Uri.parse('$_baseUrl$endpoint'),
      headers: _buildHeaders(token),
      body: body != null ? jsonEncode(body) : null,
    );
  }

  static Future<http.Response> multipart({
    required String endpoint,
    required Map<String, String> fields,
    required List<http.MultipartFile> files,
    String method = 'POST',
    String? token,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final request = http.MultipartRequest(method, uri);

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields.addAll(fields);
    request.files.addAll(files);

    final streamed = await request.send();
    return await http.Response.fromStream(streamed);
  }
}
