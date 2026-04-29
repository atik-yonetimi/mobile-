// lib/services/dashboard_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // Web kontrolü için

class DashboardService {
  // Yeni (Akıllı) hali:
  final String baseUrl = kIsWeb
      ? "http://localhost:8080"
      : "http://10.0.2.2:8080";

  // Yönetici yetkisi (Token) için yardımcı fonksiyon
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  // 1. TOPLANAN ATIK (Haftalık Toplam Verisini Çeker)
  Future<List<dynamic>> getWeeklyWasteTotals() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/weekly-waste-totals'),
        headers: headers,
      );

      // 🚨 GİZLİ HATAYI GÖSTEREN DEDEKTİF KODLARI 🚨
      print("--- DASHBOARD İSTEĞİ ---");
      print(
        "Giden Token Var mı?: ${headers['Authorization'] != null ? 'Evet' : 'Hayır'}",
      );
      print("Gelen Cevap Kodu: ${response.statusCode}");
      print("Gelen Cevap: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
      return [];
    } catch (e) {
      print("Dashboard Bağlantı Hatası: $e");
      return [];
    }
  }

  // 2. AKTİF ARAÇLAR (Sahadaki araçları ve şoförleri çeker)
  Future<List<dynamic>> getActiveVehicles() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/active-vehicles'),
        headers: headers,
      );

      print("--- AKTİF ARAÇLAR İSTEĞİ ---");
      print("Cevap Kodu: ${response.statusCode}");

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
      return [];
    } catch (e) {
      print("Aktif Araçlar Hatası: $e");
      return [];
    }
  }
}
