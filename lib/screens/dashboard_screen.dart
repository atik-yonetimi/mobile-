// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'admin_complaints_screen.dart';
import '../services/dashboard_service.dart';
import 'login_screen.dart';
import 'admin_add_vehicle_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _dashboardService = DashboardService();
  Timer? _timer;

  double _totalCollectedWaste = 0.0;
  List<dynamic> _activeVehicles = [];

  List<dynamic> _skippedAlerts = [];
  bool _isLoading = true;

  final String _baseUrl = 'http://localhost:8080/api';

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchDashboardData(showLoading: false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchDashboardData({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final weeklyData = await _dashboardService.getWeeklyWasteTotals();
      final vehiclesData = await _dashboardService.getActiveVehicles();

      final alertsResponse = await http.get(
        Uri.parse('$_baseUrl/admin/alerts'),
      );
      List<dynamic> alerts = [];
      if (alertsResponse.statusCode == 200) {
        alerts = jsonDecode(alertsResponse.body);
      }

      double calculatedTotal = 0.0;
      for (var item in weeklyData) {
        if (item['totalKg'] != null) {
          calculatedTotal += (item['totalKg'] as num).toDouble();
        }
      }

      if (mounted) {
        setState(() {
          _totalCollectedWaste = calculatedTotal;
          _activeVehicles = vehiclesData;
          _skippedAlerts = alerts;
        });
      }
    } catch (e) {
      debugPrint("Veri çekerken hata: $e");
    } finally {
      if (mounted && showLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteAlert(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/admin/alerts/$id'),
      );
      if (response.statusCode == 200) {
        _fetchDashboardData(showLoading: false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bildirim başarıyla silindi (Çözüldü).'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Silme hatası: $e");
    }
  }

  void _showSkippedAlertsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: Text(
                          'Atlanan Konteynerler',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                          overflow:
                              TextOverflow.ellipsis, // 🚨 UZUNSA 3 NOKTA KOY
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),

                  if (_skippedAlerts.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Şu an için atlanan bir konteyner kaydı bulunmuyor.',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: _skippedAlerts.length,
                        itemBuilder: (context, index) {
                          final alert = _skippedAlerts[index];

                          final String rawDate = alert['createdAt'] ?? '';
                          String formattedDate = rawDate;
                          if (rawDate.isNotEmpty) {
                            try {
                              final DateTime dt = DateTime.parse(
                                rawDate,
                              ).toLocal();
                              formattedDate =
                                  '${dt.day}/${dt.month}/${dt.year} - ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
                            } catch (_) {}
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // 🚨 DÜZELTME: ID veya tarih çok uzunsa yatayda ezilmesin diye Flexible eklendi 🚨
                                      Flexible(
                                        child: Text(
                                          'Konteyner #${alert['containerId']}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        formattedDate,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Araç Plakası: ${alert['vehiclePlate']} (Sürücü ID: ${alert['driverId']})',
                                    style: const TextStyle(
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.orange.shade200,
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.warning_amber_rounded,
                                          color: Colors.orange,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Sebep: ${alert['reason']}',
                                            style: TextStyle(
                                              color: Colors.orange.shade900,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () async {
                                        await _deleteAlert(alert['id']);
                                        setModalState(() {
                                          _skippedAlerts.removeWhere(
                                            (item) => item['id'] == alert['id'],
                                          );
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.check_circle_outline,
                                        color: Colors.green,
                                      ),
                                      label: const Text(
                                        'Çözüldü Olarak İşaretle',
                                        style: TextStyle(color: Colors.green),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Yönetim Paneli'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business, color: Colors.white),
            tooltip: 'Yeni Araç Ekle',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminAddVehicleScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.mark_email_unread_outlined,
              color: Colors.white,
            ),
            tooltip: 'Gelen Şikayetler',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminComplaintsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Çıkış Yap',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
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
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Toplanan Atık',
                          _totalCollectedWaste.toStringAsFixed(1),
                          'kg',
                          Icons.scale,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Aktif Araç',
                          _activeVehicles.length.toString(),
                          'Sahada',
                          Icons.local_shipping,
                          Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: _showSkippedAlertsModal,
                          borderRadius: BorderRadius.circular(16),
                          child: _buildStatCard(
                            'Atlanan',
                            _skippedAlerts.length.toString(),
                            'Konteyner',
                            Icons.warning_amber_rounded,
                            Colors.red,
                          ),
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
                  if (_activeVehicles.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'Şu an sahada aktif araç bulunmuyor.',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ),
                    )
                  else
                    ..._activeVehicles.map((vehicle) {
                      String plate = vehicle['plate'] ?? 'Bilinmiyor';
                      String wasteType = vehicle['wasteType'] != null
                          ? '${vehicle['wasteType']} Atık'
                          : 'Belirtilmedi';

                      int doneStops = vehicle['doneStops'] ?? 0;
                      int totalStops = vehicle['totalStops'] ?? 0;

                      String subtitleInfo =
                          '$wasteType • $doneStops/$totalStops Konteyner Alındı';
                      bool isRouteActive = vehicle['routeStatus'] == 'ACTIVE';
                      return _buildVehicleListTile(
                        plate,
                        subtitleInfo,
                        isRouteActive,
                      );
                    }).toList(),
                ],
              ),
            ),
    );
  }

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
              // 🚨 DÜZELTME: Rakam çok büyürse taşmasın diye Flexible eklendi 🚨
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
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

  Widget _buildVehicleListTile(
    String plate,
    String subtitleText,
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
        subtitle: Text(subtitleText),
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
