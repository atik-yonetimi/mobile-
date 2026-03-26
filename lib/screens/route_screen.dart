// lib/screens/route_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import '../services/route_service.dart';

class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key});

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  final MapController _mapController = MapController();
  final RouteService _routeService = RouteService();
  Map<String, dynamic>? _driverInfo; // Sürücü bilgilerini tutacak

  // YENİ STATE DEĞİŞKENLERİ
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _currentRoute; // Tüm rota bilgisi
  Map<String, dynamic>? _currentStop; // Haritada gösterilen sıradaki durak
  LatLng? _currentStopLocation; // Haritaya basılacak pin konumu

  @override
  void initState() {
    super.initState();
    _initData(); // Sayfa açılınca hem profili hem rotayı çek
  }

  Future<void> _initData() async {
    // 1. Önce profil bilgilerini çek
    final info = await _routeService.getMe();
    if (mounted) {
      setState(() {
        _driverInfo = info;
      });
    }

    // 2. Sonra rotayı çek
    await _fetchActiveRoute();
  }

  // BACKEND'DEN GERÇEK VERİYİ ÇEKEN FONKSİYON (GÜNCELLENDİ)
  Future<void> _fetchActiveRoute() async {
    try {
      // 1. Önce aktif bir rota var mı diye soruyoruz
      var routeData = await _routeService.getActiveRoute();

      // 2. OTOMATİK Zeka: Eğer rota yoksa (null döndüyse), arka planda hemen üret!
      if (routeData == null) {
        final isGenerated = await _routeService.generateRoute();

        if (isGenerated) {
          // Rota başarıyla üretildi, şimdi o yeni rotayı tekrar çek
          routeData = await _routeService.getActiveRoute();
        }
      }

      // 3. Elimizde nihayet bir rota verisi varsa, haritaya yansıt
      if (routeData != null && routeData['stops'] != null) {
        _currentRoute = routeData;
        final List<dynamic> stops = routeData['stops'];

        // PENDING (Bekleyen) durumundaki ilk durağı bul
        final pendingStops = stops
            .where((stop) => stop['status'] == 'PENDING')
            .toList();

        if (pendingStops.isNotEmpty) {
          _currentStop = pendingStops.first;
          final container = _currentStop!['container'];
          _currentStopLocation = LatLng(container['lat'], container['lng']);
        } else {
          // BUG FİX: EĞER BEKLEYEN DURAK KALMADIYSA EKRANDAKİ ESKİ VERİLERİ TEMİZLE!
          _currentStop = null;
          _currentStopLocation = null;
        }
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 1. TOPLANDI (DONE) FORMU (AYNEN KALDI)
  void _markAsDone() {
    final TextEditingController kgController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Konteyner Toplandı',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: kgController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Alınan Çöp Miktarı',
                  hintText: 'Örn: 120',
                  suffixText: 'kg',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.scale, color: Colors.green),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  // BUTONUN İÇİNDE ASENKRON İŞLEM YAPIYORUZ
                  onPressed: () async {
                    if (kgController.text.isEmpty) return; // Boş bırakılamaz

                    final double kg = double.parse(
                      kgController.text.replaceAll(',', '.'),
                    );
                    final int stopId =
                        _currentStop!['id']; // Sıradaki durağın ID'si

                    // 1. SİHİRLİ KOD: Kapatmadan önce ScaffoldMessenger'ı güvene al!
                    final scaffoldMessenger = ScaffoldMessenger.of(context);

                    // 2. Şimdi alt menüyü güvenle kapatabiliriz
                    Navigator.pop(context);

                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('Kaydediliyor...')),
                    );

                    // 3. Backend'e gönder
                    final success = await _routeService.markStopAsDone(
                      stopId,
                      kg,
                    );

                    if (success && mounted) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('$kg kg başarıyla kaydedildi!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      // BAŞARILIYSA EKRANI YENİLE (Sonraki durağa geç)
                      setState(() {
                        _isLoading = true;
                      });
                      _fetchActiveRoute();
                    } else if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('Kayıt başarısız oldu.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Kaydet ve Sonraki Durağa Geç',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // 2. ATLANDI (SKIPPED) FORMU (AYNEN KALDI)
  void _markAsSkipped() {
    final TextEditingController reasonController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Konteyneri Atla',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Atlama Sebebi',
                  hintText: 'Örn: Araç park etmiş, ulaşılamadı...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  // BUTONUN İÇİNDE ASENKRON İŞLEM YAPIYORUZ
                  onPressed: () async {
                    final int stopId = _currentStop!['id'];
                    final String reason = reasonController.text;

                    // 1. SİHİRLİ KOD: Kapatmadan önce ScaffoldMessenger'ı güvene al!
                    final scaffoldMessenger = ScaffoldMessenger.of(context);

                    // 2. Alt menüyü kapat
                    Navigator.pop(context);

                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('Konteyner atlanıyor...')),
                    );

                    // 3. Backend'e gönder
                    final success = await _routeService.markStopAsSkipped(
                      stopId,
                      reason,
                    );

                    if (success && mounted) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Konteyner atlandı olarak işaretlendi.',
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      // BAŞARILIYSA EKRANI YENİLE (Sonraki durağa geç)
                      setState(() {
                        _isLoading = true;
                      });
                      _fetchActiveRoute();
                    } else if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('İşlem başarısız oldu.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Atla ve Sonraki Durağa Geç',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // DURUMA GÖRE İÇERİĞİ ÇİZEN YARDIMCI FONKSİYON
  Widget _buildBodyContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.green),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }

    if (_currentStopLocation == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
              SizedBox(height: 24),
              Text(
                'Harika!\nŞu an size atanmış aktif bir rota yok veya tüm görevleri tamamladınız.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

    // Gerçek veri varsa haritayı çiz
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentStopLocation!,
            initialZoom: 16.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.atik_yonetimi_test',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _currentStopLocation!,
                  width: 60,
                  height: 60,
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                    size: 45,
                  ),
                ),
              ],
            ),
          ],
        ),

        // ALT BİLGİ VE AKSİYON PANELİ (Dinamik Verilerle)
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.0),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sıradaki Durak (${_currentStop!['sequenceNo']}/${_currentRoute!['stops'].length})',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_currentStop!['container']['wasteType']} Konteyneri #${_currentStop!['container']['id']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors
                            .blue
                            .shade100, // Doluluk oranı şimdilik API'de yok, mavi yaptık
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Bekliyor',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: _markAsSkipped,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.orange),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Atla',
                          style: TextStyle(color: Colors.orange, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _markAsDone,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Toplandı',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // 1. DİNAMİK PROFİL BAŞLIĞI
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.green),
              accountName: Text(
                _driverInfo != null
                    ? 'Sürücü ID: ${_driverInfo!['driverId']}'
                    : 'Yükleniyor...',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              accountEmail: Text(
                _driverInfo != null
                    ? 'Araç: ${_driverInfo!['plate']}  |  ${_driverInfo!['wasteType']} Atık'
                    : 'Bilgiler çekiliyor...',
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.green),
              ),
            ),

            // 2. MENÜ ELEMANLARI
            ListTile(
              leading: const Icon(Icons.map, color: Colors.blueAccent),
              title: const Text('Aktif Rota', style: TextStyle(fontSize: 16)),
              onTap: () => Navigator.pop(context),
            ),

            // GEÇMİŞ GÖREVLER BURADAN TAMAMEN SİLİNDİ!
            ListTile(
              leading: const Icon(Icons.dashboard, color: Colors.orange),
              title: const Text(
                'Yönetim Paneli',
                style: TextStyle(fontSize: 16),
              ),
              subtitle: const Text('İstatistikler ve Rota Yönetimi'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DashboardScreen(),
                  ),
                );
              },
            ),
            const Divider(height: 32, thickness: 1),

            // 3. ÇIKIŞ YAP
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text(
                'Çıkış Yap',
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Aktif Rota',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Sadece rota ve lokasyon varsa MyLocation butonunu göster
          if (_currentStopLocation != null)
            IconButton(
              icon: const Icon(
                Icons.my_location,
                color: Colors.blueAccent,
                size: 30,
              ),
              onPressed: () {
                _mapController.move(_currentStopLocation!, 16.0);
              },
            ),
        ],
      ),
      body: _buildBodyContent(), // Fonksiyonu çağırarak ekranı çiz
    );
  }
}
