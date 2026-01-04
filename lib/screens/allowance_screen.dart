import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/allowance_model.dart';
import '../models/spend_model.dart';
import 'spend_history_screen.dart';
import 'dart:async';

class AllowanceScreen extends StatefulWidget {
  @override
  _AllowanceScreenState createState() => _AllowanceScreenState();
}

class _AllowanceScreenState extends State<AllowanceScreen> {
  late Box<Allowance> _allowanceBox;
  final _controller = TextEditingController();
  final _spendController = TextEditingController();
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    _allowanceBox = Hive.box<Allowance>('allowances');
    _scheduleMidnightReset();
  }

  @override
  void dispose() {
    _controller.dispose();
    _spendController.dispose();
    _midnightTimer?.cancel();
    super.dispose();
  }

  void _addTodayToTotal() {
    final inputAmount = int.tryParse(_controller.text) ?? 0;
    final todayKey = _todayKey();
    final totalKey = 'total';

    final currentToday = _allowanceBox.get(todayKey)?.amount ?? 0;
    _allowanceBox.put(
      todayKey,
      Allowance(date: DateTime.now(), amount: currentToday + inputAmount),
    );

    final currentTotal = _allowanceBox.get(totalKey)?.amount ?? 0;
    _allowanceBox.put(
      totalKey,
      Allowance(date: DateTime.now(), amount: currentTotal + inputAmount),
    );

    _controller.clear();
    setState(() {});
  }

  void _spendToday() async {
    final spend = int.tryParse(_spendController.text);
    if (spend == null) return;

    final todayKey = _todayKey();
    final totalKey = 'total';

    final todayAllowance = _allowanceBox.get(todayKey)?.amount ?? 0;
    final totalAllowance = _allowanceBox.get(totalKey)?.amount ?? 0;

    _allowanceBox.put(
      todayKey,
      Allowance(date: DateTime.now(), amount: todayAllowance - spend),
    );
    _allowanceBox.put(
      totalKey,
      Allowance(date: DateTime.now(), amount: totalAllowance - spend),
    );

    // ✅ 支出を Hive に追加
    final spendBox = Hive.box<Spend>('spends');
    await spendBox.add(
      Spend(date: DateTime.now(), amount: spend, description: '支出'),
    );

    _spendController.clear();
    setState(() {});
    print(spendBox.values.toList());
  }

  void _resetToday() {
    _allowanceBox.put(_todayKey(), Allowance(date: DateTime.now(), amount: 0));
    setState(() {});
  }

  String _todayKey() => DateTime.now().toIso8601String().split('T')[0];

  int getTotalAllowance() => _allowanceBox.get('total')?.amount ?? 0;
  int getTodayAllowance() => _allowanceBox.get(_todayKey())?.amount ?? 0;

  void _scheduleMidnightReset() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final duration = nextMidnight.difference(now);

    _midnightTimer = Timer(duration, () {
      _resetToday();
      _scheduleMidnightReset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final todayAllowance = getTodayAllowance();
    final totalAllowance = getTotalAllowance();

    return Scaffold(
      appBar: AppBar(title: Text('お小遣い管理')),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '今日のお小遣い: $todayAllowance 円',
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 8),
              Text(
                '累計お小遣い: $totalAllowance 円',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: '今日のお小遣いを入力',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: _addTodayToTotal,
                child: Text('今日のお小遣いを累計に追加'),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: _resetToday,
                child: Text('今日のお小遣いをリセット'),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _spendController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: '使った金額を入力',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: _spendToday,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                child: Text('支出を引く'),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SpendHistoryScreen()),
                ),
                child: Text('支出履歴を見る'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}