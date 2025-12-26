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

                  maxY: (monthlyData.reduce((a,b)=>a>b?a:b) * 1.2).toDouble(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < months.length) {
                            return Text(months[index].substring(5)); // 月だけ表示
                          }
                          return const Text('');
                        },
                        interval: 1,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 80, // ←思い切って広げる
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8), // ←追加
                            child: Text(
                              value.toInt().toString(),
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
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
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Expanded(
            //   child: ListView.builder(
            //     itemCount: months.length,
            //     itemBuilder: (context, index) {
            //       return Text(
            //         '${months[index]}: 累計 ${cumulative[index]}',
            //         style: const TextStyle(fontSize: 16),
            //       );
            //     },
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}