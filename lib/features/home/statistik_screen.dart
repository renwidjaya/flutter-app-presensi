import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

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

  String periodText = '';

  final monthNames = <int, String>{
    1: 'Januari',
    2: 'Februari',
    3: 'Maret',
    4: 'April',
    5: 'Mei',
    6: 'Juni',
    7: 'Juli',
    8: 'Agustus',
    9: 'September',
    10: 'Oktober',
    11: 'November',
    12: 'Desember',
  };

  void _updatePeriodText() {
    final first = DateTime(selectedYear, selectedMonth, 1);
    final last = DateTime(selectedYear, selectedMonth + 1, 0);
    final fmt = DateFormat('dd MMMM yyyy', 'id_ID');
    setState(() {
      periodText = '${fmt.format(first)} – ${fmt.format(last)}';
    });
  }

  Future<void> _fetchStatistik() async {
    setState(() => isLoading = true);
    try {
      final user = await LocalStorageService.getUserData();
      final token = await LocalStorageService.getToken();
      if (user == null || token == null) return;

      final bulanStr = selectedMonth.toString().padLeft(2, '0');
      final payload = {
        "id_karyawan": user['id_karyawan'],
        "tahunbulan": '$selectedYear-$bulanStr',
      };

      final resp = await ApiService.post(
        ApiBase.statistik,
        body: payload,
        token: token,
      );
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body);
        setState(() => statistikData = json['data']);
      }
    } catch (e) {
      debugPrint('Error statistik: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickMonthYear() async {
    int tempMonth = selectedMonth;
    int tempYear = selectedYear;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setState) {
            return AlertDialog(
              title: const Text('Pilih Bulan & Tahun'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        flex: 2,
                        child: Text(
                          'Bulan',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: tempMonth,
                          items:
                              monthNames.entries
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e.key,
                                      child: Text(e.value),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (m) {
                            if (m != null) setState(() => tempMonth = m);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(
                        flex: 2,
                        child: Text(
                          'Tahun',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: tempYear,
                          items:
                              List.generate(5, (i) => DateTime.now().year - i)
                                  .map(
                                    (y) => DropdownMenuItem(
                                      value: y,
                                      child: Text('$y'),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (y) {
                            if (y != null) setState(() => tempYear = y);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    selectedMonth = tempMonth;
                    selectedYear = tempYear;
                    _updatePeriodText();
                    _fetchStatistik();
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null).then((_) {
      _updatePeriodText();
      _fetchStatistik();
    });
  }

  @override
  Widget build(BuildContext context) {
    final kategori =
        statistikData?['per_kategori'] as Map<String, dynamic>? ?? {};

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
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickMonthYear,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Periode',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(periodText),
                          const Icon(Icons.calendar_month, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _fetchStatistik,
                  icon: const Icon(Icons.filter_alt),
                  label: const Text('Filter'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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
                              'Total Hari: ${statistikData!['total_hari_dalam_bulan'] ?? 0}',
                            ),
                            Text(
                              'Total Presensi: ${statistikData!['total_presensi'] ?? 0}',
                            ),
                            Text(
                              'Hadir: ${statistikData!['total_hadir'] ?? 0}',
                            ),
                            Text(
                              'Tidak Hadir: ${statistikData!['total_tidak_hadir'] ?? 0}',
                            ),
                            Text(
                              'Persentase: ${statistikData!['persentase_kehadiran'] ?? 0}',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ...[
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
                                getTitlesWidget: (val, _) {
                                  switch (val.toInt()) {
                                    case 0:
                                      return const Text('Hadir');
                                    case 1:
                                      return const Text('Absen');
                                    default:
                                      return const SizedBox();
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
