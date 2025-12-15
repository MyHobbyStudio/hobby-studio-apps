import 'package:flutter/material.dart';
import 'stats_screen.dart';
import '../models/card_model.dart';

class StatsHomeScreen extends StatelessWidget {
  final List<CardModel> cards;

  const StatsHomeScreen({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('統計')),
        body: const Center(child: Text('まだ統計データがありません')),
      );
    }

    // 年ごとにグルーピング
    final Map<int, List<CardModel>> byYear = {};

    for (var c in cards) {
      final y = c.date?.year;
      if (y == null) continue;
      byYear.putIfAbsent(y, () => []);
      byYear[y]!.add(c);
    }

    final years = byYear.keys.toList()..sort();

    return DefaultTabController(
      length: years.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('統計'),
          bottom: TabBar(
            isScrollable: true,  // ←年が増えても安心✨
            tabs: years.map((y) => Tab(text: '$y')).toList(),
          ),
        ),
        body: TabBarView(
          children: years.map((year) {
            final yearCards = byYear[year]!;

            /// ここで StatsScreen に渡す形式を作る
            final monthlySums = List<int>.filled(12, 0);

            for (var c in yearCards) {
              if (c.date != null) {
                final m = c.date!.month - 1;
                monthlySums[m] += c.price ?? 0;
              }
            }

            final cumulative = <int>[];
            int running = 0;
            for (final v in monthlySums) {
              running += v;
              cumulative.add(running);
            }

            final months = List.generate(
              12,
                  (i) => '$year-${(i + 1).toString().padLeft(2, '0')}',
            );

            return StatsScreen(
              months: months,
              monthlyData: monthlySums,
              cumulative: cumulative,
            );
          }).toList(),
        ),
      ),
    );
  }
}