import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Survives Android process death when camera/gallery opens.
class IllegalReportDraft {
  static const _storage = FlutterSecureStorage();
  static const _draftKey = 'illegal_report_draft_v1';
  static const _resumeKey = 'illegal_report_resume_v1';

  static Future<void> markResumePending() async {
    await _storage.write(key: _resumeKey, value: '1');
  }

  static Future<void> clearResumePending() async {
    await _storage.delete(key: _resumeKey);
  }

  static Future<bool> consumeResumePending() async {
    final value = await _storage.read(key: _resumeKey);
    if (value == '1') {
      await _storage.delete(key: _resumeKey);
      return true;
    }
    return false;
  }

  static Future<void> save({
    required String title,
    required String description,
    required String name,
    required String email,
    required String phone,
    double? latitude,
    double? longitude,
    List<String> imagePaths = const [],
  }) async {
    await _storage.write(
      key: _draftKey,
      value: jsonEncode({
        'title': title,
        'description': description,
        'name': name,
        'email': email,
        'phone': phone,
        'latitude': latitude,
        'longitude': longitude,
        'images': imagePaths,
        'savedAt': DateTime.now().toIso8601String(),
      }),
    );
  }

  static Future<Map<String, dynamic>?> load() async {
    final raw = await _storage.read(key: _draftKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    await _storage.delete(key: _draftKey);
    await _storage.delete(key: _resumeKey);
  }
}
