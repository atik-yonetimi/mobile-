// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/auth_models.dart';

class AuthService {
  final String baseUrl = "http://10.0.2.2:8080";

  // 1. Giriş Yapma Fonksiyonu
  Future<LoginResponse?> login(String plate) async {
    http.Response response; // Sadece bağlantı denemesi için

    try {
      // 1. AŞAMA: Sadece sunucuya gitmeyi dene
      response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"plate": plate}),
      );
    } catch (e) {
      // Sadece internet yoksa veya backend kapalıysa buraya düşer
      throw Exception('Sunucuya ulaşılamadı. Bağlantınızı kontrol edin.');
    }

    // 2. AŞAMA: Sunucudan cevap geldi, şimdi içeriğine bakalım
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return LoginResponse.fromJson(data);
    } else if (response.statusCode == 404) {
      // 404 Hatasını yakalayıp Türkçe ve anlaşılır bir mesaja çeviriyoruz
      throw Exception("Plakaya ait sürücü bulunamadı.");
    } else {
      throw Exception("Giriş başarısız! Hata Kodu: ${response.statusCode}");
    }
  }

  // 2. Profil Bilgilerini Çekme Fonksiyonu
  // (Buraya GET /me fonksiyonunu yazacağız)
}
