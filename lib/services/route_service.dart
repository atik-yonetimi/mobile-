// lib/services/route_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RouteService {
  final String baseUrl = "http://10.0.2.2:8080"; // Backend adresimiz

  // 1. AKTİF ROTAYI GETİR (Mevcut Fonksiyon)
  Future<Map<String, dynamic>?> getActiveRoute() async {
    // Kasadan (SharedPreferences) token'ı al
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    // Eğer token yoksa güvenlik için hata fırlat
    if (token == null) {
      throw Exception("Oturum bulunamadı. Lütfen tekrar giriş yapın.");
    }

    try {
      // Backend'den aktif rotayı iste (Token'ı Header'a ekleyerek)
      final response = await http.get(
        Uri.parse('$baseUrl/routes/active'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // Güvenlik Anahtarımız
        },
      );

      // Gelen cevabı kontrol et
      if (response.statusCode == 200) {
        // Rota başarıyla geldi
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        // Sürücüye atanmış aktif bir rota yoksa null döndür
        return null;
      } else {
        print("🚨 ROTA ÇEKME HATASI: ${response.statusCode}");
        print("🚨 DETAY: ${response.body}");
        throw Exception("Rota alınamadı (Hata Kodu: ${response.statusCode})");
      }
    } catch (e) {
      throw Exception("Sunucuya bağlanılamadı. İnternetinizi kontrol edin.");
    }
  }

  // 2. OTOMATİK ROTA ÜRETME FONKSİYONU (Yeni Eklenen)
  Future<bool> generateRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) throw Exception("Oturum bulunamadı.");

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/routes/generate'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "wasteType":
              "CAM", // Test için PDF'teki örneği kullanıyoruz [cite: 78]
          "generationMode": "MANUAL", // Backend'in beklediği format [cite: 80]
        }),
      );

      // 200 (OK) veya 201 (Created) dönerse başarılıdır
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print("🚨 OTOMATİK ROTA ÜRETME HATASI: ${response.statusCode}");
        print("🚨 DETAY: ${response.body}");
        return false;
      }
    } catch (e) {
      throw Exception("Rota üretilirken sunucuya ulaşılamadı.");
    }
  }

  // 3. KONTEYNERİ TOPLANDI OLARAK İŞARETLE (3 Aşamalı Kusursuz Akış)
  Future<bool> markStopAsDone(int stopId, double collectedKg) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token == null) throw Exception("Oturum bulunamadı.");

    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };

    try {
      // ADIM 1: Backend'e "Durağa Vardım" (ARRIVED) sinyalini gönder
      await http.patch(
        Uri.parse('$baseUrl/stops/$stopId/status'),
        headers: headers,
        body: jsonEncode({"status": "ARRIVED"}),
      );

      // ADIM 2: Toplanan çöpü (Collection) kaydet
      final collectionRes = await http.post(
        Uri.parse('$baseUrl/collections'),
        headers: headers,
        body: jsonEncode({
          "routeStopId": stopId,
          "collectedKg": collectedKg,
          "note": "Mobil uygulama üzerinden toplandı",
        }),
      );

      // Eğer çöp daha önce kaydedilmişse (bizim şu anki sıkıştığımız durum)
      // işlemi iptal etme, hatayı görmezden gelip 3. adıma atla!
      if (collectionRes.statusCode != 200 && collectionRes.statusCode != 201) {
        if (!collectionRes.body.contains("zaten var")) {
          print("🚨 COLLECTION HATASI: ${collectionRes.body}");
          return false;
        }
      }

      // ADIM 3: Son olarak durağı "BİTTİ" (DONE) olarak işaretle
      final statusRes = await http.patch(
        Uri.parse('$baseUrl/stops/$stopId/status'),
        headers: headers,
        body: jsonEncode({"status": "DONE"}),
      );

      return statusRes.statusCode == 200;
    } catch (e) {
      print("HATA: $e");
      return false;
    }
  }

  // 4. KONTEYNERİ ATLA (SKIPPED)
  Future<bool> markStopAsSkipped(int stopId, String reason) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token == null) throw Exception("Oturum bulunamadı.");

    try {
      // Sadece status güncelleniyor
      final response = await http.patch(
        Uri.parse('$baseUrl/stops/$stopId/status'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"status": "SKIPPED"}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("HATA: $e");
      return false;
    }
  }

  // 5. SÜRÜCÜ BİLGİLERİNİ GETİR (GET /me)
  Future<Map<String, dynamic>?> getMe() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body); // Sürücü bilgilerini döndür
      } else {
        print("🚨 /me ÇEKME HATASI: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("HATA: $e");
      return null;
    }
  }
}
