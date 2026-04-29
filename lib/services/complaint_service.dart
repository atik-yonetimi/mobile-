// lib/services/complaint_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // Web kontrolü için

class ComplaintService {
  final String baseUrl = kIsWeb
      ? "http://localhost:8080"
      : "http://10.0.2.2:8080";

  // Yönetici işlemleri için Token alan yardımcı fonksiyon
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  // 1. MİSAFİR: Yeni Şikayet Gönder
  Future<bool> sendComplaint(
    String guestName,
    String email,
    String subject,
    String message,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/complaints'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "guestName": guestName, // 🚨 İSİM ARTIK BACKEND'E GİDİYOR
          "guestEmail": email,
          "subject": subject,
          "message": message,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // 2. YÖNETİCİ: Tüm Şikayetleri Getir (Token Gerekir)
  Future<List<dynamic>> getComplaints() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/complaints'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 3. YÖNETİCİ: Şikayet Sil (Token Gerekir)
  Future<bool> deleteComplaint(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/complaints/$id'),
        headers: headers,
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }
}
