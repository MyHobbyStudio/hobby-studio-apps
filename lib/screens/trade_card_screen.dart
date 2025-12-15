import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/purchase_model.dart';
import 'TradeCardAddScreen.dart';
import 'dart:io';

class TradeCardScreen extends StatefulWidget {
  @override
  _TradeCardScreenState createState() => _TradeCardScreenState();
}

class _TradeCardScreenState extends State<TradeCardScreen> {
  late Box<Purchase> _purchaseBox;
  List<Purchase> _purchases = [];
  Purchase? _pendingDeleted;
  int? _pendingDeletedIndex;

  @override
  void initState() {
    super.initState();
    _openBox();
  }

  Future<void> _openBox() async {
    _purchaseBox = await Hive.openBox<Purchase>('purchases');
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _purchases = _purchaseBox.values.toList();
    });
  }

  void _deleteWithUndo(Purchase p) {
    _pendingDeleted = p;
    _pendingDeletedIndex = _purchases.indexOf(p);

    setState(() {
      _purchases.remove(p);
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('出品カードを削除しました'),
        action: SnackBarAction(
          label: '元に戻す',
          onPressed: () {
            setState(() {
              _purchases.insert(_pendingDeletedIndex!, _pendingDeleted!);
            });
            _pendingDeleted = null;
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    ).closed.then((_) async {
      if (_pendingDeleted != null) {
        await _purchaseBox.delete(_pendingDeleted!.id);
        _pendingDeleted = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('フリマ管理')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView.builder(
          itemCount: _purchases.length,
          itemBuilder: (context, index) {
            final p = _purchases[index];
            return Dismissible(
              key: ValueKey(p.id),

              // 👉 右スワイプ：編集
              background: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 20),
                color: Colors.blueGrey,
                child: const Icon(Icons.edit, color: Colors.white),
              ),

              // 👈 左スワイプ：削除
              secondaryBackground: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: Colors.redAccent,
                child: const Icon(Icons.delete, color: Colors.white),
              ),

              confirmDismiss: (direction) async {
                if (direction == DismissDirection.startToEnd) {
                  // 編集
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TradeCardAddScreen(purchase: p),
                    ),
                  ).then((_) => _refresh());
                  return false;
                }
                return true;
              },

              onDismissed: (_) => _deleteWithUndo(p),

              child: _buildPurchaseCard(p),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TradeCardAddScreen()),
          );
          if (result != null) {
            _refresh();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // =======================
// 出品カードUI（STEP1-④）
// =======================
  Widget _buildPurchaseCard(Purchase p) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD4AF37), // ゴールド枠
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),

        // ===== 画像 =====
        leading: p.imagePath != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(p.imagePath!),
            width: 56,
            height: 56,
            fit: BoxFit.cover,
          ),
        )
            : Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.image_not_supported, color: Colors.white70),
        ),

        // ===== タイトル =====
        title: Text(
          p.cardName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),

        // ===== サブ情報 =====
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('仕入れ: ¥${p.price}'),
              Text('出品先: ${p.listingSite}'),
              Text(
                p.isSold ? '売却済み' : '出品中',
                style: TextStyle(
                  color: p.isSold ? Colors.greenAccent : Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
