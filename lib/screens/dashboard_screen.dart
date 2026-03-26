// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Yönetim Paneli',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors
            .orange, // Yönetici ekranı olduğunu belli etmek için turuncu tema
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Günlük Özet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Üstteki İki Ana İstatistik Kartı
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Toplanan Atık',
                    '1,240',
                    'kg',
                    Icons.scale,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Tamamlanan',
                    '%78',
                    'Rota',
                    Icons.check_circle,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Alttaki İki Alt İstatistik Kartı
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Aktif Araç',
                    '4',
                    'Sahada',
                    Icons.local_shipping,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Atlanan',
                    '2',
                    'Konteyner',
                    Icons.warning_amber_rounded,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            const Text(
              'Araç Durumları',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Araçların Listesi
            _buildVehicleListTile(
              '01 ABC 01',
              'Ahmet Yılmaz',
              'Cam Atık - Bölge 1',
              true,
            ),
            _buildVehicleListTile(
              '34 DEF 34',
              'Mehmet Demir',
              'Plastik Atık - Bölge 2',
              true,
            ),
            _buildVehicleListTile(
              '06 GHI 06',
              'Caner Kaya',
              'Kağıt Atık - Bakımda',
              false,
            ),
          ],
        ),
      ),
    );
  }

  // İstatistik Kartlarını Çizen Yardımcı Fonksiyon
  Widget _buildStatCard(
    String title,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Araç Listesi Kartlarını Çizen Yardımcı Fonksiyon
  Widget _buildVehicleListTile(
    String plate,
    String driver,
    String route,
    bool isActive,
  ) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive
              ? Colors.green.shade100
              : Colors.red.shade100,
          child: Icon(
            Icons.local_shipping,
            color: isActive ? Colors.green : Colors.red,
          ),
        ),
        title: Text(plate, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$driver • $route'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? Colors.green : Colors.red,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            isActive ? 'Aktif' : 'Pasif',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
