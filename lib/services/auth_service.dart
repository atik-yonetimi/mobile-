// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // Web kontrolü için

class AuthService {
  // Yeni (Akıllı) hali:
  final String baseUrl = kIsWeb
      ? "http://localhost:8080"
      : "http://10.0.2.2:8080";

  // 1. SÜRÜCÜ GİRİŞİ (Plaka + Şifre)
  Future<bool> loginDriver(String plate, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"plate": plate, "password": password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();

        final token = data['accessToken'];
        if (token == null) throw Exception("Sunucudan token alınamadı!");

        await prefs.setString('accessToken', token);
        await prefs.setString('role', 'DRIVER');

        if (data['driverId'] != null) {
          await prefs.setString('driverId', data['driverId'].toString());
        } else {
          await prefs.setString('driverId', "1");
        }

        return true;
      } else if (response.statusCode == 401 || response.statusCode == 404) {
        throw Exception("Hatalı plaka veya şifre.");
      } else {
        // 🚨 BACKEND'DEN GELEN ÖZEL HATA MESAJINI YAKALAMA BÖLÜMÜ 🚨
        String backendMessage =
            "Giriş başarısız! Hata Kodu: ${response.statusCode}";
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            backendMessage =
                errorData['message']; // Spring Boot'un gönderdiği mesajı al
          }
        } catch (_) {
          // Eğer JSON değilse ve düz metinse onu al
          if (response.body.isNotEmpty) {
            backendMessage = response.body;
          }
        }
        throw Exception(backendMessage);
      }
    } catch (e) {
      String errorMessage = e.toString().replaceAll('Exception: ', '');

      // Gerçek bir bağlantı kopması (İnternet yok, sunucu kapalı vb.) durumlarını yakala
      if (errorMessage.contains("Connection") ||
          errorMessage.contains("Failed host lookup") ||
          errorMessage.contains("SocketException")) {
        throw Exception('Sunucuya ulaşılamadı. Bağlantınızı kontrol edin.');
      }

      // Backend'in gönderdiği mesajları (sahada araç var, hatalı şifre vb.) olduğu gibi UI'a ilet
      throw Exception(errorMessage);
    }
  }

  // 2. YÖNETİCİ GİRİŞİ (Kullanıcı Adı + Şifre)
  Future<bool> loginAdmin(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/admin-login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();

        final token = data['accessToken'];
        if (token == null) throw Exception("Sunucudan token alınamadı!");

        await prefs.setString('accessToken', token);
        await prefs.setString('role', 'ADMIN');
        return true;
      } else if (response.statusCode == 401 || response.statusCode == 404) {
        throw Exception("Hatalı kullanıcı adı veya şifre.");
      } else {
        // 🚨 BACKEND'DEN GELEN ÖZEL HATA MESAJINI YAKALAMA BÖLÜMÜ 🚨
        String backendMessage =
            "Giriş başarısız! Hata Kodu: ${response.statusCode}";
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            backendMessage = errorData['message'];
          }
        } catch (_) {
          if (response.body.isNotEmpty) {
            backendMessage = response.body;
          }
        }
        throw Exception(backendMessage);
      }
    } catch (e) {
      String errorMessage = e.toString().replaceAll('Exception: ', '');

      if (errorMessage.contains("Connection") ||
          errorMessage.contains("Failed host lookup") ||
          errorMessage.contains("SocketException")) {
        throw Exception('Sunucuya ulaşılamadı. Bağlantınızı kontrol edin.');
      }

      throw Exception(errorMessage);
    }
  }

  // 3. ÇIKIŞ YAP (Oturumu Kapat)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
