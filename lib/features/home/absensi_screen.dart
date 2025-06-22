import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_face_api/flutter_face_api.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:apprendi/constants/api_base.dart';
import 'package:apprendi/services/api_service.dart';
import 'package:apprendi/utils/location_helper.dart';
import 'package:apprendi/services/local_storage_service.dart';

class AbsensiScreen extends StatefulWidget {
  const AbsensiScreen({super.key});

  @override
  State<AbsensiScreen> createState() => _AbsensiScreenState();
}

class _AbsensiScreenState extends State<AbsensiScreen> {
  Timer? _timer;
  String? _token;
  int? _presensiId;
  double? currentLat;
  double? currentLng;
  int _idKaryawan = 0;
  String _timeString = '';
  String? _imageProfilUrl;
  bool _isLoading = false;
  bool _isCheckedIn = false;
  Map<String, dynamic>? _lastPresensiData;
  String _lokasi = 'Membaca lokasi...';

  final String kategori = 'MASUK_KERJA';

  @override
  void initState() {
    super.initState();
    initFaceSDK();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
    _loadUserData();
    _getLokasi();
  }

  Future<void> _getLokasi() async {
    final lokasi = await LocationHelper.getCurrentAddress();
    final coords = await LocationHelper.getCurrentCoordinates();

    if (!mounted) return;

    setState(() {
      _lokasi = lokasi;
      currentLat = coords?.latitude ?? 0.0;
      currentLng = coords?.longitude ?? 0.0;
    });

    debugPrint("CHECK latitude: ${coords?.latitude}");
    debugPrint("CHECK longitude: ${coords?.longitude}");
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _timeString =
          "${now.hour.toString().padLeft(2, '0')}:"
          "${now.minute.toString().padLeft(2, '0')}:"
          "${now.second.toString().padLeft(2, '0')}";
    });
  }

  Future<void> initFaceSDK() async {
    try {
      await FaceSDK.instance.initialize();
    } catch (e) {
      debugPrint("Error initializing FaceSDK: $e");
    }
  }

  Future<void> _loadUserData() async {
    final user = await LocalStorageService.getUserData();
    final token = await LocalStorageService.getToken();
    if (user != null && token != null) {
      setState(() {
        _idKaryawan = user['id_karyawan'];
        _token = token;
        _imageProfilUrl = user['image_profil'];
      });
      await _checkLastPresensi();
    }
  }

  Future<void> _checkLastPresensi() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final response = await ApiService.get(
      "${ApiBase.presensiLast}$_idKaryawan",
      token: _token,
    );

    if (response.statusCode == 200 && response.body.isNotEmpty) {
      final data = jsonDecode(response.body);
      final dataTanggal = (data['tanggal'] ?? '').toString().trim();

      debugPrint("Tanggal dari API: $dataTanggal");
      debugPrint("Tanggal lokal: $today");

      if (dataTanggal == today) {
        setState(() {
          _isCheckedIn = data['jam_pulang'] == null;
          _presensiId = data['id_absensi'];
          _lastPresensiData = data;
        });
      } else {
        setState(() {
          _lastPresensiData = null;
        });
      }

      debugPrint("last presensi: $_lastPresensiData");
    }
  }

  Future<void> _handleAbsensi() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final cameraGranted = await Permission.camera.request();
      if (!cameraGranted.isGranted) {
        _showSnack('Izin kamera diperlukan', isError: true);
        return;
      }

      final result = await FaceSDK.instance.startFaceCapture();
      final faceImage = result.image?.image;

      if (faceImage == null) {
        _showSnack('Wajah tidak terdeteksi', isError: true);
        return;
      }

      // Validasi: pastikan ada URL referensi wajah
      if (_imageProfilUrl == null || _imageProfilUrl!.isEmpty) {
        _showSnack('Foto referensi tidak tersedia', isError: true);
        return;
      }

      // Ambil foto referensi dari URL
      final refResp = await http.get(Uri.parse(_imageProfilUrl!));
      final referenceImageBytes = refResp.bodyBytes;

      // Lakukan pencocokan wajah
      final matchRequest = MatchFacesRequest([
        MatchFacesImage(faceImage, ImageType.PRINTED),
        MatchFacesImage(referenceImageBytes, ImageType.PRINTED),
      ]);

      final matchResponse = await FaceSDK.instance.matchFaces(matchRequest);

      if (matchResponse.results.isEmpty ||
          matchResponse.results.first.similarity < 0.85) {
        _showSnack('Wajah tidak cocok, absen ditolak', isError: true);
        return;
      }

      // Simpan hasil foto
      final tempDir = await getTemporaryDirectory();
      final filePath = path.join(
        tempDir.path,
        "face_${DateTime.now().millisecondsSinceEpoch}.jpg",
      );
      final imageFile = await File(filePath).writeAsBytes(faceImage);

      final now = DateTime.now();
      final tanggal = DateFormat('yyyy-MM-dd').format(now);
      final jam = DateFormat('HH:mm:ss').format(now);

      String totalJamLembur = "0";
      if (_isCheckedIn) {
        final batasPulang = DateTime(now.year, now.month, now.day, 16, 30);
        if (now.isAfter(batasPulang)) {
          final duration = now.difference(batasPulang);
          totalJamLembur = duration.toString().split('.').first;
        }
      }

      final response = await ApiService.multipart(
        endpoint:
            _isCheckedIn ? "${ApiBase.checkin}/$_presensiId" : ApiBase.checkin,
        method: _isCheckedIn ? 'PUT' : 'POST',
        token: _token,
        fields:
            _isCheckedIn
                ? {
                  'jam_pulang': jam,
                  'lokasi_pulang': _lokasi,
                  'total_jam_lembur': totalJamLembur,
                }
                : {
                  'id_karyawan': _idKaryawan.toString(),
                  'tanggal': tanggal,
                  'jam_masuk': jam,
                  'lokasi_masuk': _lokasi,
                  'kategori': kategori,
                },
        files: [
          await http.MultipartFile.fromPath(
            _isCheckedIn ? 'foto_pulang' : 'foto_masuk',
            imageFile.path,
          ),
        ],
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnack("${_isCheckedIn ? 'Check-Out' : 'Check-In'} berhasil!");
        await _checkLastPresensi();
      } else {
        String errorMsg = 'Gagal absen: ${response.statusCode}';
        try {
          final body = jsonDecode(response.body);
          if (body is Map && body.containsKey('message')) {
            errorMsg = body['message'];
          }
        } catch (_) {}
        _showSnack(errorMsg, isError: true);
      }
    } catch (e) {
      _showSnack("Terjadi kesalahan: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String formatJam(String? jamRaw) {
      if (jamRaw == null || jamRaw.isEmpty || jamRaw == 'null') return '-';
      try {
        final jam = DateFormat('HH:mm:ss').parse(jamRaw);
        return DateFormat('HH:mm').format(jam);
      } catch (_) {
        return '-';
      }
    }

    final jamMasuk = formatJam(_lastPresensiData?['jam_masuk']);
    final jamPulang = formatJam(_lastPresensiData?['jam_pulang']);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Absensi"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 320,
            child:
                (currentLat == null ||
                        currentLng == null ||
                        (currentLat == 0.0 && currentLng == 0.0))
                    ? const Center(child: CircularProgressIndicator())
                    : Stack(
                      children: [
                        FlutterMap(
                          options: MapOptions(
                            center: LatLng(currentLat!, currentLng!),
                            zoom: 16.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                              userAgentPackageName: 'com.example.app_presensi',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(currentLat!, currentLng!),
                                  width: 80,
                                  height: 80,
                                  child: const Icon(
                                    Icons.location_pin,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Positioned(
                          top: 16,
                          left: 0,
                          right: 0,
                          child: Column(
                            children: [
                              Text(
                                _timeString,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black,
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              _lokasi,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _isLoading ? null : _handleAbsensi,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isCheckedIn ? Colors.red : Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child:
                _isLoading
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : Text(
                      _isCheckedIn ? 'Check Out' : 'Check In',
                      style: const TextStyle(fontSize: 18),
                    ),
          ),
          const SizedBox(height: 8),
          const Divider(),
          if (_lastPresensiData != null)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Riwayat Hari Ini',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  jamPulang == '-' ? Icons.login : Icons.logout,
                                  color:
                                      jamPulang == '-'
                                          ? Colors.green
                                          : Colors.red,
                                  size: 32,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  jamPulang == '-' ? 'Check In' : 'Check Out',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text("Absen Masuk: $jamMasuk"),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time_filled,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text("Absen Pulang: $jamPulang"),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 20,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Lokasi Masuk: ${_lastPresensiData?['lokasi_masuk'] ?? '-'}",
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 20,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Lokasi Pulang: ${_lastPresensiData?['lokasi_pulang'] ?? '-'}",
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                            if (_lastPresensiData!['total_jam_lembur'] !=
                                    null &&
                                _lastPresensiData!['total_jam_lembur'] != '0')
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.access_alarm,
                                      size: 20,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Lembur: ${_lastPresensiData!['total_jam_lembur']}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
