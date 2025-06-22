import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:apprendi/constants/api_base.dart';
import 'package:apprendi/services/api_service.dart';
import 'package:apprendi/services/local_storage_service.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  List<dynamic> presensiList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPresensi();
  }

  Future<void> _fetchPresensi() async {
    final user = await LocalStorageService.getUserData();
    final token = await LocalStorageService.getToken();

    if (user == null || token == null) return;

    final idKaryawan = user['id_karyawan'];
    final endpoint = '${ApiBase.riwayatAbsensi}$idKaryawan';

    try {
      final response = await ApiService.get(endpoint, token: token);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          presensiList = data['data']['presensis'];
          isLoading = false;
        });

        print('Check $data');
      } else {
        debugPrint('Gagal mengambil data presensi.');
      }
    } catch (e) {
      debugPrint('Error saat ambil presensi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text('Riwayat Absensi'),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : presensiList.isEmpty
              ? const Center(child: Text('Belum ada data presensi.'))
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: presensiList.length,
                itemBuilder: (context, index) {
                  final item = presensiList[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text('Tanggal: ${item['tanggal']}'),
                      subtitle: Text('Status: ${item['kategori']}'),
                      trailing: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
