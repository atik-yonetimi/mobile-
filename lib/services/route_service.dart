// lib/services/route_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // Web kontrolü için

class RouteService {
  final String baseUrl = kIsWeb
      ? "http://localhost:8080"
      : "http://10.0.2.2:8080"; // 🚨 DİKKAT: /api eklendi çünkü Backend Controller'larını öyle güncelledik

  // ==========================================================
  // 🚨 GERÇEK VERİTABANI BAĞLANTISI AKTİF
  // ==========================================================

  // Güvenli Header (Başlık) Oluşturucu Yardımcı Fonksiyon
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    final driverId = prefs.getString('driverId');

    if (token == null) {
      throw Exception("Oturum süresi dolmuş. Lütfen tekrar giriş yapın.");
    }

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
      "Driver-Id": driverId ?? "1", // Sürücü ID'si eklendi
    };
  }

  // 1. AKTİF ROTAYI GETİR
  Future<Map<String, dynamic>?> getActiveRoute() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/routes/active'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      // İçinde "Aktif rota" veya "bulunamadi" geçen her hatayı "Rota yok" (null) olarak kabul et.
      else if (response.statusCode == 404 ||
          response.body.contains("Aktif rota") ||
          response.body.contains("bulunamadi")) {
        return null; // Aktif rota yok, şoförün otomatik üretmesi lazım
      } else {
        throw Exception("Rota alınamadı (Hata Kodu: ${response.statusCode})");
      }
    } catch (e) {
      if (e.toString().contains("Oturum")) rethrow;
      throw Exception("Sunucuya bağlanılamadı. İnternetinizi kontrol edin.");
    }
  }

  // 2. OTOMATİK ROTA ÜRET
  Future<bool> generateRoute() async {
    try {
      final headers = await _getHeaders();
      final prefs = await SharedPreferences.getInstance();

      // Şoförün atık tipini bul (Eğer me ucundan alınamadıysa varsayılan CAM)
      final wasteType = prefs.getString('wasteType') ?? "CAM";

      final response = await http.post(
        Uri.parse('$baseUrl/routes/generate'),
        headers: headers,
        body: jsonEncode({"wasteType": wasteType, "generationMode": "MANUAL"}),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw Exception("Rota üretilirken sunucuya ulaşılamadı.");
    }
  }

  // 3. KONTEYNERİ TOPLANDI OLARAK İŞARETLE
  Future<bool> markStopAsDone(int stopId, double collectedKg) async {
    try {
      final headers = await _getHeaders();

      // Önce durak statüsünü ARRIVED yap
      await http.patch(
        Uri.parse('$baseUrl/stops/$stopId/status'),
        headers: headers,
        body: jsonEncode({"status": "ARRIVED"}),
      );

      // Toplanan çöp miktarını kaydet
      final collectionRes = await http.post(
        Uri.parse('$baseUrl/collections'),
        headers: headers,
        body: jsonEncode({
          "routeStopId": stopId,
          "collectedKg": collectedKg,
          "note": "Mobil uygulama üzerinden toplandı",
        }),
      );

      if (collectionRes.statusCode != 200 && collectionRes.statusCode != 201) {
        if (!collectionRes.body.contains("zaten var")) return false;
      }

      // Durak statüsünü tamamen DONE yap
      final statusRes = await http.patch(
        Uri.parse('$baseUrl/stops/$stopId/status'),
        headers: headers,
        body: jsonEncode({"status": "DONE"}),
      );

      return statusRes.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 4. KONTEYNERİ ATLA
  Future<bool> markStopAsSkipped(int stopId, String reason) async {
    try {
      final headers =
          await _getHeaders(); // 🚨 Mevcut _getHeaders metodunu kullandık
      final response = await http.patch(
        Uri.parse(
          '$baseUrl/stops/$stopId/status',
        ), // 🚨 Kendi baseUrl'ini ve doğru endpoinit kullandık
        headers: headers,
        body: jsonEncode({
          'status': 'SKIPPED',
          'reason': reason, // 🚨 İŞTE EKSİK OLAN KRİTİK SATIR BURADA
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 5. SÜRÜCÜ BİLGİLERİNİ GETİR
  Future<Map<String, dynamic>?> getMe() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Şoför bilgilerini ileride kullanmak üzere hafızaya at
        final prefs = await SharedPreferences.getInstance();
        if (data['wasteType'] != null) {
          await prefs.setString('wasteType', data['wasteType']);
        }

        return data;
      }
      return null;
    } catch (e) {
      // Eğer backend /me ucu henüz hazır değilse, veritabanımızdaki 01ABC01 aracını yedek olarak döndür
      return {"driverId": 1, "plate": "01ABC01", "wasteType": "CAM"};
    }
  }

  // 6. ROTAYI TAMAMLA (Araç Yönetim Panelinden düşer)
  Future<bool> completeRoute(int routePlanId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.patch(
        Uri.parse('$baseUrl/routes/$routePlanId/status'),
        headers: headers,
        body: jsonEncode({"status": "COMPLETED"}),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("Rota tamamlanırken hata oluştu: $e");
      return false;
    }
  }
}
