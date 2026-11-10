// ignore_for_file: file_names
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

String getUrl() {
  return "https://api.nyamiraedams.dat.co.ke/api/";
  // return "http://192.168.1.136:3003/api/";
}

Color getColor(String color) {
  switch (color) {
    case "primary":
      return const Color(0xFF2E7D32); // EDAMS Green
    case "secondary":
      return const Color(0xFF4CAF50); // EDAMS Light Green
    case "accent":
      return const Color(0xFF2196F3); // Blue
    case "warning":
      return const Color(0xFFFF9800); // Orange
    case "error":
      return const Color(0xFFF44336); // Red
    default:
      return const Color(0xFF2E7D32); // Default to primary
  }
}

// JWT Token parsing utility
Map<String, dynamic> parseJwt(String token) {
  final parts = token.split('.');
  if (parts.length != 3) {
    return <String, dynamic>{"error": "Invalid token"};
  }
  final payload = _decodeBase64(parts[1]);
  final payloadMap = json.decode(payload);
  if (payloadMap is! Map<String, dynamic>) {
    return <String, dynamic>{"error": "Invalid token"};
  }

  return payloadMap;
}

String _decodeBase64(String str) {
  String output = str.replaceAll('-', '+').replaceAll('_', '/');

  switch (output.length % 4) {
    case 0:
      break;
    case 2:
      output += '==';
      break;
    case 3:
      output += '=';
      break;
    default:
      throw Exception('Illegal base64url string!"');
  }

  return utf8.decode(base64Url.decode(output));
}

// Generic HTTP GET request
Future<Map<String, dynamic>> httpGet(String endpoint,
    {Map<String, String>? headers}) async {
  try {
    final url = getUrl() + endpoint;
    final response = await http.get(
      Uri.parse(url),
      headers: await _getAuthHeaders(headers),
    );

    return _handleResponse(response);
  } catch (e) {
    return {'success': false, 'message': 'Network error: $e'};
  }
}

// Generic HTTP POST request
Future<Map<String, dynamic>> httpPost(
    String endpoint, Map<String, dynamic> data,
    {Map<String, String>? headers}) async {
  try {
    final url = getUrl() + endpoint;
    final response = await http.post(
      Uri.parse(url),
      headers: await _getAuthHeaders(headers),
      body: json.encode(data),
    );

    return _handleResponse(response);
  } catch (e) {
    return {'success': false, 'message': 'Network error: $e'};
  }
}

// Generic HTTP PUT request
Future<Map<String, dynamic>> httpPut(String endpoint, Map<String, dynamic> data,
    {Map<String, String>? headers}) async {
  try {
    final url = getUrl() + endpoint;
    final response = await http.put(
      Uri.parse(url),
      headers: await _getAuthHeaders(headers),
      body: json.encode(data),
    );

    return _handleResponse(response);
  } catch (e) {
    return {'success': false, 'message': 'Network error: $e'};
  }
}

// Generic HTTP DELETE request
Future<Map<String, dynamic>> httpDelete(String endpoint,
    {Map<String, String>? headers}) async {
  try {
    final url = getUrl() + endpoint;
    final response = await http.delete(
      Uri.parse(url),
      headers: await _getAuthHeaders(headers),
    );

    return _handleResponse(response);
  } catch (e) {
    return {'success': false, 'message': 'Network error: $e'};
  }
}

// File upload utility
Future<Map<String, dynamic>> uploadFile(String endpoint, String filePath,
    String fieldName, Map<String, dynamic> additionalData) async {
  try {
    final url = getUrl() + endpoint;
    final uri = Uri.parse(url);

    var request = http.MultipartRequest('POST', uri);

    // Add auth headers
    final authHeaders = await _getAuthHeaders();
    request.headers.addAll(authHeaders);

    // Add file
    request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));

    // Add additional data
    additionalData.forEach((key, value) {
      request.fields[key] = value.toString();
    });

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    return _handleResponse(http.Response(responseData, response.statusCode));
  } catch (e) {
    return {'success': false, 'message': 'Upload error: $e'};
  }
}

// Helper method to get authentication headers
Future<Map<String, String>> _getAuthHeaders(
    [Map<String, String>? additionalHeaders]) async {
  const secureStorage = FlutterSecureStorage();
  final token = await secureStorage.read(key: 'edams_jwt');

  final headers = <String, String>{
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  if (token != null && token.isNotEmpty) {
    headers['Authorization'] = 'Bearer $token';
  }

  if (additionalHeaders != null) {
    headers.addAll(additionalHeaders);
  }

  return headers;
}

// Helper method to handle HTTP responses
Map<String, dynamic> _handleResponse(http.Response response) {
  try {
    final data = json.decode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': data, 'statusCode': response.statusCode};
    } else if (response.statusCode == 401) {
      return {
        'success': false,
        'message': 'Unauthorized',
        'statusCode': response.statusCode
      };
    } else if (response.statusCode == 403) {
      return {
        'success': false,
        'message': 'Forbidden',
        'statusCode': response.statusCode
      };
    } else if (response.statusCode == 404) {
      return {
        'success': false,
        'message': 'Not found',
        'statusCode': response.statusCode
      };
    } else if (response.statusCode >= 500) {
      return {
        'success': false,
        'message': 'Server error',
        'statusCode': response.statusCode
      };
    } else {
      return {
        'success': false,
        'message': data['message'] ?? 'Request failed',
        'statusCode': response.statusCode
      };
    }
  } catch (e) {
    return {
      'success': false,
      'message': 'Invalid response format: $e',
      'statusCode': response.statusCode
    };
  }
}

// Date formatting utility
String formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}

// API Service class for user profile operations
class ApiService {
  // Get user profile based on user type
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await httpGet('admin-users/me/profile');

      if (response['success'] == true) {
        return response['data'];
      } else {
        throw Exception(response['message'] ?? 'Failed to load profile');
      }
    } catch (e) {
      throw Exception('Error loading profile: $e');
    }
  }

  // Get public user profile
  static Future<Map<String, dynamic>> getPublicUserProfile() async {
    try {
      final response = await httpGet('admin-users/me/profile');

      if (response['success'] == true) {
        // The httpGet function wraps the API response in success/data structure
        return response['data'];
      } else {
        throw Exception(response['message'] ?? 'Failed to load profile');
      }
    } catch (e) {
      throw Exception('Error loading profile: $e');
    }
  }

  // Get unified profile (works for both admin and public users)
  static Future<Map<String, dynamic>> getUnifiedProfile() async {
    try {
      final response = await httpGet('admin-users/profile/unified');

      if (response['success'] == true) {
        return response['data'];
      } else {
        throw Exception(response['message'] ?? 'Failed to load profile');
      }
    } catch (e) {
      throw Exception('Error loading profile: $e');
    }
  }

  // Update user profile
  static Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> profileData) async {
    try {
      final userId = profileData['basicInfo']?['ID'];
      if (userId == null) {
        throw Exception('User ID is required');
      }

      final response = await httpPut('admin-users/$userId', profileData);

      if (response['success'] == true) {
        return response['data'];
      } else {
        throw Exception(response['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  // Change password
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await httpPost('admin-users/change-password', {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });

      if (response['success'] == true) {
        return response['data'];
      } else {
        throw Exception(response['message'] ?? 'Failed to change password');
      }
    } catch (e) {
      throw Exception('Error changing password: $e');
    }
  }

  // Get pending profession approvals (for admin users)
  static Future<Map<String, dynamic>> getPendingProfessionApprovals({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await httpGet(
          'admin-users/pending-profession-approvals?page=$page&limit=$limit');

      if (response['success'] == true) {
        return response['data'];
      } else {
        throw Exception(
            response['message'] ?? 'Failed to load pending approvals');
      }
    } catch (e) {
      throw Exception('Error loading pending approvals: $e');
    }
  }

  // Approve profession (for admin users)
  static Future<Map<String, dynamic>> approveProfession(String userId) async {
    try {
      final response =
          await httpPost('admin-users/$userId/approve-profession', {});

      if (response['success'] == true) {
        return response['data'];
      } else {
        throw Exception(response['message'] ?? 'Failed to approve profession');
      }
    } catch (e) {
      throw Exception('Error approving profession: $e');
    }
  }
}
