import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/spend_model.dart';

class SpendHistoryScreen extends StatelessWidget {
  const SpendHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Hive.openBox<Spend>('spends'),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: Text('支出履歴')),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final spendBox = Hive.box<Spend>('spends');

        // 🔹 デバッグ用：Box 内のデータを全部出力
        print('💰 Spend Box の件数: ${spendBox.length}');
        for (int i = 0; i < spendBox.length; i++) {
          final spend = spendBox.getAt(i);
          print(
            '[$i] ${spend?.date} | ${spend?.amount}円 | ${spend?.description}',
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text('支出履歴')),
          body: ValueListenableBuilder(
            valueListenable: spendBox.listenable(),
            builder: (context, Box<Spend> box, _) {
              if (box.isEmpty) {
                return Center(child: Text('履歴はまだありません'));
              }

              final spends = box.values.toList().reversed.toList();
              return ListView.builder(
                itemCount: spends.length,
                itemBuilder: (context, index) {
                  final spend = spends[index];
                  return ListTile(
                    title: Text(
                      '${spend.amount} 円',
                      style: TextStyle(color: Colors.white), // ここで文字色指定
                    ),
                    subtitle: Text(
                      '${spend.description} | ${_formatDate(spend.date)}',
                      style: TextStyle(color: Colors.white70), // 少し薄め
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}