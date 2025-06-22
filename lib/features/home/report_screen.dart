import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:apprendi/constants/api_base.dart';
import 'package:apprendi/services/api_service.dart';
import 'package:apprendi/services/local_storage_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool isLoading = false;
  String periodText = '';
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;
  List<BarChartGroupData> barGroups = [];

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

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null).then((_) {
      _updatePeriodText();
      _loadReport();
    });
  }

  void _updatePeriodText() {
    final first = DateTime(selectedYear, selectedMonth, 1);
    final last = DateTime(selectedYear, selectedMonth + 1, 0);
    final fmt = DateFormat('dd MMMM yyyy', 'id_ID');
    setState(() {
      periodText = '${fmt.format(first)} – ${fmt.format(last)}';
    });
  }

  Future<void> _loadReport() async {
    setState(() => isLoading = true);

    final token = await LocalStorageService.getToken();
    if (token == null) {
      setState(() => isLoading = false);
      return;
    }

    final tahunbulan =
        '$selectedYear-${selectedMonth.toString().padLeft(2, '0')}';
    final url = '${ApiBase.reportAll}?tahunbulan=$tahunbulan';

    try {
      final resp = await ApiService.get(url, token: token);
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body);
        final chart =
            (json['data']['chart'] as List)
                .map((e) => {'label': e['label'], 'count': e['count']})
                .toList();

        setState(() {
          barGroups = List.generate(chart.length, (i) {
            final cnt = (chart[i]['count'] as num).toDouble();
            return BarChartGroupData(
              x: i,
              barRods: [BarChartRodData(toY: cnt, width: 16)],
            );
          });
        });
      } else {
        debugPrint('Gagal load report: ${resp.statusCode}');
      }
    } catch (e) {
      debugPrint('Error load report: $e');
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
                    _loadReport();
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

  Future<void> _downloadReport() async {
    setState(() => isLoading = true);

    final token = await LocalStorageService.getToken();
    if (token == null) {
      setState(() => isLoading = false);
      return;
    }

    final tahunbulan =
        '$selectedYear-${selectedMonth.toString().padLeft(2, '0')}';
    final endpoint = '${ApiBase.export}?tahunbulan=$tahunbulan';

    try {
      final resp = await ApiService.get(endpoint, token: token);
      if (resp.statusCode == 200) {
        final bytes = resp.bodyBytes;
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/Laporan-$tahunbulan.xlsx');
        await file.writeAsBytes(bytes);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Tersimpan: ${file.path}')));
        OpenFile.open(file.path);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal download: ${resp.statusCode}')),
        );
      }
    } catch (e) {
      debugPrint('Error download: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saat download laporan')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text('Report'),
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
                  onPressed: _loadReport,
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
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (barGroups.isEmpty)
              const Expanded(child: Center(child: Text('Data belum tersedia')))
            else
              Expanded(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kehadiran Bulanan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: BarChart(
                            BarChartData(
                              minY: 0,
                              maxY:
                                  barGroups
                                      .map((g) => g.barRods.first.toY)
                                      .fold(0.0, (a, b) => a > b ? a : b) +
                                  1,
                              groupsSpace: 12,
                              barGroups: barGroups,
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 1,
                                getDrawingHorizontalLine:
                                    (value) => FlLine(
                                      color: Colors.grey.shade300,
                                      dashArray: [4, 4],
                                    ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 32,
                                    getTitlesWidget: (value, meta) {
                                      final idx = value.toInt();
                                      if (idx < labels.length) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 6.0,
                                          ),
                                          child: Text(labels[idx]),
                                        );
                                      }
                                      return const SizedBox();
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 1,
                                    reservedSize: 28,
                                  ),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _downloadReport,
              icon: const Icon(Icons.download),
              label: const Text('Download Laporan'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
