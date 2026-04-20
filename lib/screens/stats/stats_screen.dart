import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:utangku_app/providers/debt_provider.dart';
import 'package:utangku_app/utils/formatters.dart';
import 'package:utangku_app/utils/theme.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik'),
      ),
      body: Consumer<DebtProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.totalCount == 0) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadAllData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Cards
                  _buildSummaryCards(context, provider),
                  const SizedBox(height: 24),

                  // Utang vs Piutang Pie Chart
                  Text(
                    'Perbandingan Utang & Piutang',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildTypePieChart(context, provider),
                  const SizedBox(height: 24),

                  // Monthly Bar Chart
                  Text(
                    'Trend Bulanan',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total per bulan (6 bulan terakhir)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildMonthlyBarChart(context, provider),
                  const SizedBox(height: 24),

                  // Status Pie Chart
                  Text(
                    'Status Pembayaran',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildStatusPieChart(context, provider),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Belum ada data',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tambahkan transaksi untuk melihat statistik',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, DebtProvider provider) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Total Transaksi',
                provider.totalCount.toString(),
                Icons.receipt_long,
                AppTheme.primaryOrange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                'Rata-rata Nominal',
                CurrencyFormatter.format(provider.averageAmount),
                Icons.calculate,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Tuntas',
                '${provider.paidCount} (${provider.paidPercentage.toStringAsFixed(0)}%)',
                Icons.check_circle,
                AppTheme.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                'Belum Tuntas',
                '${provider.unpaidCount} (${provider.unpaidPercentage.toStringAsFixed(0)}%)',
                Icons.pending,
                AppTheme.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypePieChart(BuildContext context, DebtProvider provider) {
    final utangAmt = provider.totalUnpaidUtang;
    final piutangAmt = provider.totalUnpaidPiutang;
    final total = utangAmt + piutangAmt;

    if (total == 0) {
      return _buildNoDataCard(context, 'Tidak ada data utang/piutang');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                  sections: [
                    PieChartSectionData(
                      color: AppTheme.utangColor,
                      value: utangAmt,
                      title: '${(utangAmt / total * 100).toStringAsFixed(0)}%',
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      radius: 60,
                    ),
                    PieChartSectionData(
                      color: AppTheme.piutangColor,
                      value: piutangAmt,
                      title: '${(piutangAmt / total * 100).toStringAsFixed(0)}%',
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      radius: 60,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Utang', AppTheme.utangColor, CurrencyFormatter.format(utangAmt)),
                const SizedBox(width: 24),
                _buildLegendItem('Piutang', AppTheme.piutangColor, CurrencyFormatter.format(piutangAmt)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyBarChart(BuildContext context, DebtProvider provider) {
    final monthlyData = provider.monthlyTotals;

    if (monthlyData.isEmpty) {
      return _buildNoDataCard(context, 'Tidak ada data bulanan');
    }

    final sortedKeys = monthlyData.keys.toList()..sort();
    final utangBars = <FlSpot>[];
    final piutangBars = <FlSpot>[];

    for (int i = 0; i < sortedKeys.length; i++) {
      final key = sortedKeys[i];
      utangBars.add(FlSpot(i.toDouble(), monthlyData[key]!['UTANG'] ?? 0.0));
      piutangBars.add(FlSpot(i.toDouble(), monthlyData[key]!['PIUTANG'] ?? 0.0));
    }

    double maxY = 0;
    for (final bar in [...utangBars, ...piutangBars]) {
      if (bar.y > maxY) maxY = bar.y;
    }
    if (maxY == 0) maxY = 1000000;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY * 1.2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.grey[800],
                      tooltipPadding: const EdgeInsets.all(8),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final label = rodIndex == 0 ? 'Utang' : 'Piutang';
                        return BarTooltipItem(
                          '$label\n${CurrencyFormatter.format(rod.toY)}',
                          const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= sortedKeys.length) {
                            return const SizedBox.shrink();
                          }
                          final parts = sortedKeys[value.toInt()].split('-');
                          final month = DateTime(int.parse(parts[0]), int.parse(parts[1]));
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('MMM').format(month),
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            _formatCompact(value),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 4,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[300]!,
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(sortedKeys.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: utangBars[i].y,
                          color: AppTheme.utangColor,
                          width: 12,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                        BarChartRodData(
                          toY: piutangBars[i].y,
                          color: AppTheme.piutangColor,
                          width: 12,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Utang', AppTheme.utangColor, null),
                const SizedBox(width: 24),
                _buildLegendItem('Piutang', AppTheme.piutangColor, null),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPieChart(BuildContext context, DebtProvider provider) {
    final paid = provider.paidCount;
    final unpaid = provider.unpaidCount;
    final total = paid + unpaid;

    if (total == 0) {
      return _buildNoDataCard(context, 'Tidak ada data status');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                  sections: [
                    PieChartSectionData(
                      color: AppTheme.success,
                      value: paid.toDouble(),
                      title: '$paid',
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      radius: 60,
                    ),
                    PieChartSectionData(
                      color: AppTheme.warning,
                      value: unpaid.toDouble(),
                      title: '$unpaid',
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      radius: 60,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Lunas', AppTheme.success, '$paid transaksi'),
                const SizedBox(width: 24),
                _buildLegendItem('Belum Lunas', AppTheme.warning, '$unpaid transaksi'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, String? value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value != null ? '$label ($value)' : label,
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildNoDataCard(BuildContext context, String message) {
    return Card(
      child: SizedBox(
        height: 150,
        child: Center(
          child: Text(message, style: TextStyle(color: Colors.grey[500])),
        ),
      ),
    );
  }

  String _formatCompact(double value) {
    if (value >= 1000000) {
      return 'Rp${(value / 1000000).toStringAsFixed(1)}jt';
    } else if (value >= 1000) {
      return 'Rp${(value / 1000).toStringAsFixed(0)}rb';
    }
    return 'Rp${value.toStringAsFixed(0)}';
  }
}
