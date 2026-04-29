// lib/screens/route_screen.dart
import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'login_screen.dart';
import '../services/route_service.dart';
import '../services/auth_service.dart';

class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key});

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final RouteService _routeService = RouteService();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _currentRoute;
  Map<String, dynamic>? _currentStop;
  LatLng? _currentStopLocation;
  Map<String, dynamic>? _driverInfo;

  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  bool _isFollowingUser = false;

  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _initData();
    _initLocationTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    try {
      final latTween = Tween<double>(
        begin: _mapController.camera.center.latitude,
        end: destLocation.latitude,
      );
      final lngTween = Tween<double>(
        begin: _mapController.camera.center.longitude,
        end: destLocation.longitude,
      );
      final zoomTween = Tween<double>(
        begin: _mapController.camera.zoom,
        end: destZoom,
      );

      final controller = AnimationController(
        duration: const Duration(milliseconds: 1200),
        vsync: this,
      );
      final Animation<double> animation = CurvedAnimation(
        parent: controller,
        curve: Curves.fastOutSlowIn,
      );

      controller.addListener(() {
        _mapController.move(
          LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
          zoomTween.evaluate(animation),
        );
      });

      animation.addStatusListener((status) {
        if (status == AnimationStatus.completed ||
            status == AnimationStatus.dismissed) {
          controller.dispose();
        }
      });

      controller.forward();
    } catch (e) {}
  }

  Future<void> _fetchRoutePath() async {
    if (_currentPosition == null || _currentStopLocation == null) return;

    final startLat = _currentPosition!.latitude;
    final startLng = _currentPosition!.longitude;
    final endLat = _currentStopLocation!.latitude;
    final endLng = _currentStopLocation!.longitude;

    final url =
        'https://router.project-osrm.org/route/v1/driving/$startLng,$startLat;$endLng,$endLat?geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List coords = data['routes'][0]['geometry']['coordinates'];
        if (mounted) {
          setState(() {
            _routePoints = coords.map((c) => LatLng(c[1], c[0])).toList();
          });
        }
      } else {
        if (mounted) setState(() => _routePoints = []);
      }
    } catch (e) {
      if (mounted) setState(() => _routePoints = []);
    }
  }

  Future<void> _initLocationTracking() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _useMockLocation();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _useMockLocation();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _useMockLocation();
        return;
      }

      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );

      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen((Position position) {
            if (mounted) {
              setState(() {
                _currentPosition = position;

                if (_currentStopLocation != null) {
                  _fetchRoutePath();
                }
              });

              if (_isFollowingUser) {
                try {
                  _mapController.moveAndRotate(
                    LatLng(position.latitude, position.longitude),
                    17.0,
                    position.heading,
                  );
                } catch (e) {}
              }
            }
          });
    } catch (e) {
      _useMockLocation();
    }
  }

  void _useMockLocation() {
    if (mounted) {
      setState(() {
        _currentPosition = Position(
          longitude: 36.814000,
          latitude: 37.584000,
          timestamp: DateTime.now(),
          accuracy: 10,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );

        if (_currentStopLocation != null) {
          _fetchRoutePath();
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gerçek GPS alınamadı, test konumu kullanılıyor.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _initData() async {
    final info = await _routeService.getMe();
    if (mounted) {
      setState(() {
        _driverInfo = info;
      });
    }
    await _fetchActiveRoute();
  }

  Future<void> _fetchActiveRoute() async {
    try {
      var routeData = await _routeService.getActiveRoute();

      if (routeData == null) {
        final isGenerated = await _routeService.generateRoute();
        if (isGenerated) {
          routeData = await _routeService.getActiveRoute();
        }
      }

      if (routeData != null && routeData['stops'] != null) {
        _currentRoute = routeData;
        final List<dynamic> stops = routeData['stops'];

        final pendingStops = stops
            .where((stop) => stop['status'] == 'PENDING')
            .toList();

        if (pendingStops.isNotEmpty) {
          _currentStop = pendingStops.first;
          final container = _currentStop!['container'];
          _currentStopLocation = LatLng(container['lat'], container['lng']);

          _fetchRoutePath();

          if (!_isFollowingUser) {
            _animatedMapMove(_currentStopLocation!, 16.0);
          }
        } else {
          _currentStop = null;
          _routePoints = [];
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

  void _markAsDone() {
    if (_currentPosition == null || _currentStopLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konumunuz belirleniyor, lütfen bekleyin...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final double distanceInMeters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _currentStopLocation!.latitude,
      _currentStopLocation!.longitude,
    );

    final int maxMesafe = 50;

    if (distanceInMeters > maxMesafe) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Konteynere çok uzaksınız! (Mesafe: ${distanceInMeters.toInt()}m)',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Konteyner Toplandı',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Bu konteynerdeki atıklar araca aktarıldı olarak kaydedilecek.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    final int stopId = _currentStop!['id'];
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    Navigator.pop(context);

                    final dynamic rawFill =
                        _currentStop!['container']['fillPercent'];
                    final double fillPercent = rawFill != null
                        ? (rawFill as num).toDouble()
                        : 80.0;

                    final double maxKapasiteKg = 50.0;
                    double hesaplananKg = (fillPercent / 100) * maxKapasiteKg;

                    if (hesaplananKg <= 0) hesaplananKg = 1.5;
                    hesaplananKg = double.parse(
                      hesaplananKg.toStringAsFixed(2),
                    );

                    final success = await _routeService.markStopAsDone(
                      stopId,
                      hesaplananKg,
                    );

                    if (success && mounted) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            'Konteyner başarıyla toplandı! ($hesaplananKg kg eklendi)',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );

                      final isLastStop =
                          _currentStop!['sequenceNo'] ==
                          _currentRoute!['stops'].length;

                      if (isLastStop && _currentRoute != null) {
                        final int routePlanId = _currentRoute!['id'];
                        await _routeService.completeRoute(routePlanId);

                        setState(() {
                          _currentStop = null;
                          _routePoints = [];
                        });
                      } else {
                        _fetchActiveRoute();
                      }
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
                    'Onayla ve Sonraki Durağa Geç',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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
          // 🚨 1. DÜZELTME: Klavye açıldığında taşmayı engellemek için SingleChildScrollView eklendi 🚨
          child: SingleChildScrollView(
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
                    hintText: 'Örn: Araç park etmiş...',
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
                    onPressed: () async {
                      final int stopId = _currentStop!['id'];
                      final String reason = reasonController.text;
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      Navigator.pop(context);

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

                        final isLastStop =
                            _currentStop!['sequenceNo'] ==
                            _currentRoute!['stops'].length;

                        if (isLastStop && _currentRoute != null) {
                          final int routePlanId = _currentRoute!['id'];
                          await _routeService.completeRoute(routePlanId);

                          setState(() {
                            _currentStop = null;
                            _routePoints = [];
                          });
                        } else {
                          _fetchActiveRoute();
                        }
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
          ),
        );
      },
    );
  }

  Widget _buildSuccessPanel() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(24.0),
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
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 64),
          const SizedBox(height: 16),
          const Text(
            'Harika İş Çıkardınız!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Şu anki rotadaki tüm görevleri başarıyla tamamladınız. Dinlenebilirsiniz.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _fetchActiveRoute();
              },
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'Yeni Görev Ara',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionPanel() {
    return Container(
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 🚨 2. DÜZELTME: Uzun metinlerin sağdaki rozeti ezmesini engellemek için Expanded eklendi 🚨
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sıradaki Durak (${_currentStop!['sequenceNo']}/${_currentRoute!['stops'].length})',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_currentStop!['container']['wasteType']} Konteyneri #${_currentStop!['container']['id']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis, // Uzunsa ... koy
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Builder(
                builder: (context) {
                  final dynamic rawFill =
                      _currentStop!['container']['fillPercent'];
                  final int fillPercent = rawFill != null
                      ? (rawFill as num).toInt()
                      : 0;

                  final isCritical = fillPercent >= 80;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isCritical
                          ? Colors.red.shade100
                          : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      fillPercent == 0 ? '? Dolu' : '%$fillPercent Dolu',
                      style: TextStyle(
                        color: isCritical ? Colors.red : Colors.orange.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
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
    );
  }

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

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentStopLocation ?? const LatLng(37.585, 36.815),
            initialZoom: 16.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.atik_yonetimi_test',
            ),
            PolylineLayer(
              polylines: [
                if (_currentPosition != null && _currentStopLocation != null)
                  Polyline(
                    points: _routePoints.isNotEmpty
                        ? _routePoints
                        : [
                            LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
                            _currentStopLocation!,
                          ],
                    strokeWidth: 5.0,
                    color: Colors.blueAccent.withOpacity(0.8),
                  ),
              ],
            ),
            MarkerLayer(
              markers: [
                if (_currentStopLocation != null && _currentStop != null)
                  Marker(
                    point: _currentStopLocation!,
                    width: 60,
                    height: 60,
                    alignment: Alignment.topCenter,
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                      size: 45,
                    ),
                  ),
                if (_currentPosition != null)
                  Marker(
                    point: LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                    width: 60,
                    height: 60,
                    child: Transform.rotate(
                      angle: _currentPosition!.heading * (math.pi / 180),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.4),
                              blurRadius: 10,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.navigation,
                          color: Colors.blueAccent,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),

        Positioned(
          top: 120,
          right: 16,
          child: FloatingActionButton(
            heroTag: "nav_fab",
            backgroundColor: _isFollowingUser
                ? Colors.blueAccent
                : Colors.white,
            onPressed: () {
              setState(() {
                _isFollowingUser = !_isFollowingUser;
              });
              if (_isFollowingUser && _currentPosition != null) {
                try {
                  _animatedMapMove(
                    LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                    18.0,
                  );
                } catch (e) {}
              } else {
                try {
                  _mapController.rotate(0.0);
                  if (_currentStopLocation != null) {
                    _animatedMapMove(_currentStopLocation!, 16.0);
                  }
                } catch (e) {}
              }
            },
            child: Icon(
              Icons.my_location,
              color: _isFollowingUser ? Colors.white : Colors.blueAccent,
            ),
          ),
        ),

        Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: _currentStop != null
                ? _buildActionPanel()
                : _buildSuccessPanel(),
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
            ListTile(
              leading: const Icon(Icons.map, color: Colors.blueAccent),
              title: const Text('Aktif Rota', style: TextStyle(fontSize: 16)),
              onTap: () => Navigator.pop(context),
            ),
            const Divider(height: 32, thickness: 1),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text(
                'Çıkış Yap',
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
              onTap: () async {
                await _authService.logout();

                if (mounted) {
                  Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (Route<dynamic> route) => false,
                  );
                }
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
      ),
      body: _buildBodyContent(),
    );
  }
}
