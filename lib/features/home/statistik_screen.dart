import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:apprendi/constants/api_base.dart';
import 'package:apprendi/services/api_service.dart';
import 'package:apprendi/services/local_storage_service.dart';

class StatistikScreen extends StatefulWidget {
  const StatistikScreen({super.key});

  @override
  State<StatistikScreen> createState() => _StatistikScreenState();
}

class _StatistikScreenState extends State<StatistikScreen> {
  bool isLoading = false;
  Map<String, dynamic>? statistikData;

  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;

  final List<String> months = [
    '01',
    '02',
    '03',
    '04',
    '05',
    '06',
    '07',
    '08',
    '09',
    '10',
    '11',
    '12',
  ];
  late final List<int> years = List.generate(5, (i) => DateTime.now().year - i);

  Future<void> _fetchStatistik() async {
    setState(() => isLoading = true);
    final user = await LocalStorageService.getUserData();
    final token = await LocalStorageService.getToken();
    if (user == null || token == null) return;

    final payload = {
      "id_karyawan": user['id_karyawan'],
      "tahunbulan": '$selectedYear-${months[selectedMonth - 1]}',
    };

    try {
      final resp = await ApiService.post(
        ApiBase.statistik,
        body: payload,
        token: token,
      );
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body);
        setState(() => statistikData = json['data']);
      }
    } catch (_) {}
    setState(() => isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    _fetchStatistik();
  }

  @override
  Widget build(BuildContext context) {
    final kategori = statistikData?['per_kategori'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text('Statistik Absensi'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Picker Bulan & Tahun
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DropdownButton<int>(
                  value: selectedMonth,
                  items:
                      List.generate(12, (i) => i + 1)
                          .map(
                            (m) => DropdownMenuItem(
                              value: m,
                              child: Text(months[m - 1]),
                            ),
                          )
                          .toList(),
                  onChanged: (m) {
                    if (m == null) return;
                    setState(() => selectedMonth = m);
                    _fetchStatistik();
                  },
                ),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: selectedYear,
                  items:
                      years
                          .map(
                            (y) =>
                                DropdownMenuItem(value: y, child: Text('$y')),
                          )
                          .toList(),
                  onChanged: (y) {
                    if (y == null) return;
                    setState(() => selectedYear = y);
                    _fetchStatistik();
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (statistikData == null)
              const Text('Data belum tersedia')
            else
              Expanded(
                child: ListView(
                  children: [
                    // Ringkasan Card
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ringkasan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Total Hari: ${statistikData!['total_hari_dalam_bulan']}',
                            ),
                            Text(
                              'Total Presensi: ${statistikData!['total_presensi']}',
                            ),
                            Text('Hadir: ${statistikData!['total_hadir']}'),
                            Text(
                              'Tidak Hadir: ${statistikData!['total_tidak_hadir']}',
                            ),
                            Text(
                              'Persentase: ${statistikData!['persentase_kehadiran']}',
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Pie Chart Per Kategori
                    if (kategori != null) ...[
                      const Text(
                        'Distribusi Per Kategori',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections:
                                kategori.entries.map((e) {
                                  final value = (e.value as num).toDouble();
                                  return PieChartSectionData(
                                    value: value,
                                    title: '${e.key}\n${value.toInt()}',
                                    radius: 60,
                                    titleStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                }).toList(),
                            sectionsSpace: 2,
                            centerSpaceRadius: 30,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Bar Chart: Presensi vs Tidak Hadir
                    const Text(
                      'Presensi vs Tidak Hadir',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY:
                              (statistikData!['total_presensi'] as int)
                                  .toDouble() +
                              1,
                          barGroups: [
                            BarChartGroupData(
                              x: 0,
                              barRods: [
                                BarChartRodData(
                                  toY:
                                      (statistikData!['total_presensi'] as int)
                                          .toDouble(),
                                  width: 20,
                                ),
                              ],
                              showingTooltipIndicators: [0],
                            ),
                            BarChartGroupData(
                              x: 1,
                              barRods: [
                                BarChartRodData(
                                  toY:
                                      (statistikData!['total_tidak_hadir']
                                              as int)
                                          .toDouble(),
                                  width: 20,
                                ),
                              ],
                              showingTooltipIndicators: [0],
                            ),
                          ],
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (val, meta) {
                                  switch (val.toInt()) {
                                    case 0:
                                      return const Text('Hadir');
                                    case 1:
                                      return const Text('Absen');
                                    default:
                                      return const Text('');
                                  }
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
