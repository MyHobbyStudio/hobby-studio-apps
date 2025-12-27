import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class StatsScreen extends StatelessWidget {
  final List<String> months; // "2025-01" の形式
  final List<int> monthlyData;
  final List<int> cumulative;

  const StatsScreen({
    required this.months,
    required this.monthlyData,
    required this.cumulative,
    super.key,
  });

  @override
  Widget build(BuildContext context) {

    final maxValue = monthlyData.reduce((a, b) => a > b ? a : b);
    final step = _calcStep(maxValue);

// step刻みでmaxYを切り上げ
    final maxYInt = ((maxValue * 1.2) / step).ceil() * step;
    final double maxY = maxYInt.toDouble();

    if (monthlyData.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('統計')),
        body: const Center(child: Text("まだ統計データがありません")),
      );
    }
    return Scaffold(
      // appBar: AppBar(title: const Text('統計')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY,

                    // ✅ ① グリッド（普通の補助線）
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxY / 6, // だいたい6本くらいにする（好みで調整）
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.white.withOpacity(0.14),
                        strokeWidth: 1.2,
                        dashArray: [6, 6],
                      ),
                    ),

                    // ✅ ② MAXライン（必ず表示される）
                    extraLinesData: ExtraLinesData(
                      horizontalLines: [
                        HorizontalLine(
                          y: maxY,
                          color: const Color(0xFFD4AF37).withOpacity(0.35),
                          strokeWidth: 1.4,
                          dashArray: [8, 6],
                        ),
                      ],
                    ),

                    titlesData: FlTitlesData(
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // ←余計な上の数字を消す
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),

                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < months.length) {
                              return Text(months[index].substring(5)); // 01-12
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),

                      // ※ leftTitles は「金額」を出す場所（今の君のコードは月を出してておかしいので注意）
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 56,
                          getTitlesWidget: (value, meta) {
                            // 例：0 / maxY/2 / maxY だけ表示
                            if (value == 0 ||
                                value == (maxY / 2).roundToDouble() ||
                                value == maxY.roundToDouble()) {
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),

                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(monthlyData.length, (i) {
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: monthlyData[i].toDouble(),
                            color: Colors.blueAccent,
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }),
                  )
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
  int _calcStep(int maxValue) {
    if (maxValue <= 10000) return 2500;
    if (maxValue <= 50000) return 5000;
    return 10000;
  }
}