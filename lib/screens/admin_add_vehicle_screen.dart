// lib/screens/admin_add_vehicle_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart'; // Web kontrolü için

class AdminAddVehicleScreen extends StatefulWidget {
  const AdminAddVehicleScreen({super.key});

  @override
  State<AdminAddVehicleScreen> createState() => _AdminAddVehicleScreenState();
}

class _AdminAddVehicleScreenState extends State<AdminAddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  // Backend Adresi
  final String _baseUrl = kIsWeb
      ? "http://localhost:8080/api"
      : "http://10.0.2.2:8080/api";

  // Form Kontrolcüleri
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _latController = TextEditingController(
    text: "37.585",
  ); // Varsayılan Koordinat
  final TextEditingController _lngController = TextEditingController(
    text: "36.815",
  ); // Varsayılan Koordinat

  String _selectedWasteType = "CAM";
  final List<String> _wasteTypes = [
    "CAM",
    "PLASTIK",
    "KAGIT",
    "METAL",
    "IKINCI_EL_ESYA",
    "EVSEL",
  ];

  bool _isLoading = false;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/admin/vehicles'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "plate": _plateController.text.trim().toUpperCase(),
          "wasteType": _selectedWasteType,
          "loginPassword": _passwordController.text.trim(),
          "garageLat": double.tryParse(_latController.text) ?? 37.585,
          "garageLng": double.tryParse(_lngController.text) ?? 36.815,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Araç ve Sürücü başarıyla eklendi! 🎉'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          // Başarılı olunca formu temizle
          _plateController.clear();
          _passwordController.clear();
        }
      } else {
        throw Exception("Sunucu Hatası: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kayıt başarısız oldu. Bağlantınızı kontrol edin.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Yeni Araç Ekle'),
        backgroundColor: Colors.orange,
        elevation: 0,
      ),
      // 🚨 DÜZELTME: Center yerine LayoutBuilder kullanılarak klavye açılışına tam duyarlılık sağlandı
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48, // Padding payı düşüldü
                ),
                child: IntrinsicHeight(
                  child: Center(
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Icon(
                                Icons.fire_truck,
                                size: 64,
                                color: Colors.orange,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Filo Araç Kaydı',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Bu form hem yeni bir araç hem de o araca atanmış bir sürücü profili oluşturur.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 32),

                              // PLAKA
                              TextFormField(
                                controller: _plateController,
                                textCapitalization:
                                    TextCapitalization.characters,
                                decoration: InputDecoration(
                                  labelText: 'Araç Plakası (Örn: 01ABC123)',
                                  prefixIcon: const Icon(Icons.pin),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                validator: (value) => value!.isEmpty
                                    ? 'Plaka boş bırakılamaz'
                                    : null,
                              ),
                              const SizedBox(height: 16),

                              // ŞİFRE
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Sürücü Giriş Şifresi',
                                  prefixIcon: const Icon(Icons.lock),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                validator: (value) => value!.isEmpty
                                    ? 'Şifre boş bırakılamaz'
                                    : null,
                              ),
                              const SizedBox(height: 16),

                              // ATIK TÜRÜ (DROPDOWN)
                              DropdownButtonFormField<String>(
                                value: _selectedWasteType,
                                decoration: InputDecoration(
                                  labelText: 'Toplanacak Atık Türü',
                                  prefixIcon: const Icon(Icons.recycling),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                items: _wasteTypes.map((type) {
                                  return DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() => _selectedWasteType = value!);
                                },
                              ),
                              const SizedBox(height: 16),

                              // GARAJ KOORDİNATLARI
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _latController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Garaj Enlem (Lat)',
                                        prefixIcon: const Icon(Icons.map),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _lngController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Garaj Boylam (Lng)',
                                        prefixIcon: const Icon(Icons.map),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),

                              // KAYDET BUTONU
                              SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _submitForm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : const Text(
                                          'Aracı ve Sürücüyü Kaydet',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
