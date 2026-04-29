// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'route_screen.dart';
import 'dashboard_screen.dart';
import 'complaint_screen.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();

  // Yükleme Animasyonları İçin Durum Değişkenleri
  bool _isDriverLoading = false;
  bool _isAdminLoading = false;

  // Sürücü Kontrolleri
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _driverPassController = TextEditingController();

  // Yönetici Kontrolleri
  final TextEditingController _adminUsernameController =
      TextEditingController();
  final TextEditingController _adminPassController = TextEditingController();

  // Misafir Kontrolleri
  final TextEditingController _guestNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- GERÇEK SÜRÜCÜ GİRİŞİ ---
  void _loginAsDriver() async {
    if (_plateController.text.isEmpty || _driverPassController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plaka ve şifre boş bırakılamaz!')),
      );
      return;
    }

    setState(() => _isDriverLoading = true);

    try {
      final success = await _authService.loginDriver(
        _plateController.text.trim(),
        _driverPassController.text.trim(),
      );

      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RouteScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDriverLoading = false);
    }
  }

  // --- GERÇEK YÖNETİCİ GİRİŞİ ---
  void _loginAsAdmin() async {
    if (_adminUsernameController.text.isEmpty ||
        _adminPassController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kullanıcı adı ve şifre boş bırakılamaz!'),
        ),
      );
      return;
    }

    setState(() => _isAdminLoading = true);

    try {
      final success = await _authService.loginAdmin(
        _adminUsernameController.text.trim(),
        _adminPassController.text.trim(),
      );

      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAdminLoading = false);
    }
  }

  // --- MİSAFİR GİRİŞİ ---
  void _loginAsGuest() {
    if (_guestNameController.text.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ComplaintScreen(guestName: _guestNameController.text),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lütfen adınızı girin.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🚨 1. DÜZELTME: SafeArea'dan sonraki en dış Column'u LayoutBuilder ve SingleChildScrollView ile sardık.
    // Bu sayede klavye açıldığında tüm ekran kaydırılabilir olacak.
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: ConstrainedBox(
                // 🚨 2. DÜZELTME: İçeriğin en az ekran boyu kadar yer kaplamasını sağladık.
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // LOGO VE BAŞLIK
                      const Icon(
                        Icons.recycling,
                        size: 80,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Temiz Rotacılar',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 3'LÜ TAB MENÜ
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicatorColor: Colors.green,
                          labelColor: Colors.green,
                          unselectedLabelColor: Colors.grey,
                          indicatorWeight: 3,
                          tabs: const [
                            Tab(
                              icon: Icon(Icons.local_shipping),
                              text: 'Sürücü',
                            ),
                            Tab(
                              icon: Icon(Icons.admin_panel_settings),
                              text: 'Yönetici',
                            ),
                            Tab(
                              icon: Icon(Icons.person_outline),
                              text: 'Misafir',
                            ),
                          ],
                        ),
                      ),

                      // TAB İÇERİKLERİ
                      // 🚨 3. DÜZELTME: Expanded, SingleChildScrollView içinde sorun yaratır.
                      // Bu yüzden TabBarView'u sabit bir yükseklikle kısıtladık.
                      SizedBox(
                        height: 400, // Giriş formu için yeterli bir yükseklik
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildDriverTab(),
                            _buildAdminTab(),
                            _buildGuestTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDriverTab() {
    // 🚨 4. DÜZELTME: TabBarView içindeki Column sığmayabilir.
    // Bu yüzden formu Column yerine SingleChildScrollView ve Column ile sardık.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _plateController,
            decoration: InputDecoration(
              labelText: 'Araç Plakası',
              prefixIcon: const Icon(Icons.directions_car),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _driverPassController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Şifre',
              prefixIcon: const Icon(Icons.lock),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isDriverLoading ? null : _loginAsDriver,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isDriverLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Sürücü Girişi',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminTab() {
    // 🚨 5. DÜZELTME: Yönetici sekmesi için SingleChildScrollView eklendi.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _adminUsernameController,
            decoration: InputDecoration(
              labelText: 'Kullanıcı Adı',
              prefixIcon: const Icon(Icons.shield),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _adminPassController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Şifre',
              prefixIcon: const Icon(Icons.lock),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isAdminLoading ? null : _loginAsAdmin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isAdminLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Yönetim Paneline Gir',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestTab() {
    // 🚨 6. DÜZELTME: Misafir sekmesi için SingleChildScrollView eklendi.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.volunteer_activism,
            size: 64,
            color: Colors.blueAccent,
          ),
          const SizedBox(height: 16),
          const Text(
            'Şehrimizi birlikte temiz tutalım.\nŞikayet ve önerileriniz bizim için değerli.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _guestNameController,
            decoration: InputDecoration(
              labelText: 'Adınız Soyadınız',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            width: double.infinity, // Buton tam genişlik kaplasın
            child: ElevatedButton(
              onPressed: _loginAsGuest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Misafir Olarak Devam Et',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
