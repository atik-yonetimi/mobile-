// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'route_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _plateController = TextEditingController();
  bool _isLoading = false;

  void _handleLogin() async {
    // 1. Plaka boş mu kontrolü
    if (_plateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lütfen bir plaka girin')));
      return;
    }

    // 2. Yükleniyor animasyonunu başlat
    setState(() {
      _isLoading = true;
    });

    try {
      // 3. Backend'e isteği at
      final authService = AuthService();
      final response = await authService.login(_plateController.text.trim());

      // EĞER BURAYA GEÇEBİLDİYSEK GİRİŞ BAŞARILIDIR!
      if (response != null) {
        // 4. SharedPreferences kasasını aç ve verileri kaydet
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', response.accessToken);
        await prefs.setInt('driverId', response.driverId);
        await prefs.setInt('vehicleId', response.vehicleId);
        await prefs.setString('plate', response.plate);

        if (mounted) {
          // 5. Başarılı mesajı göster
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Giriş Başarılı! Rota sayfasına yönlendiriliyor...',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );

          // 6. Login ekranını kapatıp Rota ekranını aç
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const RouteScreen()),
          );
        }
      }
    } catch (e) {
      // 7. Backend'den hata dönerse (yanlış plaka vs.) ekranda göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // 8. İşlem bitince yükleniyor animasyonunu durdur
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo veya İkon
              const Icon(
                Icons.local_shipping,
                size: 100,
                color: Colors.green, // Atık yönetimi teması
              ),
              const SizedBox(height: 48),

              // Başlık
              const Text(
                'Sürücü Girişi',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Plaka Giriş Alanı
              TextField(
                controller: _plateController,
                textCapitalization:
                    TextCapitalization.characters, // Plakalar büyük harftir
                decoration: InputDecoration(
                  labelText: 'Araç Plakası (Örn: 01ABC01)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.pin),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // Giriş Yap Butonu
              SizedBox(
                height: 56, // Sürücülerin rahat tıklaması için büyük buton
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Sisteme Gir',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _plateController.dispose();
    super.dispose();
  }
}
