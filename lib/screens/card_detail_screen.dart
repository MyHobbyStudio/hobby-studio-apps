// screens/card_detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:hive/hive.dart';
import '../models/purchase_model.dart';

import '../models/card_model.dart';
import 'card_add_screen.dart';
import 'card_image_viewer_screen.dart';
import 'TradeCardAddScreen.dart';
import 'trade_card_screen.dart';

class CardDetailScreen extends StatefulWidget {
  final CardModel card;
  const CardDetailScreen({super.key, required this.card});

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}


class _CardDetailScreenState extends State<CardDetailScreen> {
  late CardModel _card;
  bool _isListed = false;
  @override
  void initState() {
    super.initState();
    _card = widget.card;
    _checkListed();
  }

  Future<void> _checkListed() async {
    final box = await Hive.openBox<Purchase>('purchases');
    final listed = box.values.any(
          (p) => p.cardId == _card.id && p.isSold == false,
    );

    if (!mounted) return;
    setState(() {
      _isListed = listed;
    });
  }

  // =====================
  // Image
  // =====================
  Future<File?> _getImageFile(String? fileName) async {
    if (fileName == null) return null;
    final dir = await getApplicationDocumentsDirectory();
    final file = File(path.join(dir.path, 'images', fileName));
    return await file.exists() ? file : null;
  }

  // =====================
  // Utils
  // =====================
  String _formatDate(DateTime? date) {
    if (date == null) return '未設定';
    return '${date.year}/${date.month}/${date.day}';
  }

  Widget _labelValue(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // =====================
  // Bottom Button
  // =====================
  Widget _bottomButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap, // ⭐️修正：nullで無効化できるように
    bool disabled = false,        // ⭐️追加：見た目も無効っぽく
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: disabled ? 0.4 : 1.0, // ⭐️追加
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white70),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =====================
  // UI
  // =====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(_card.name)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== 画像 =====
              FutureBuilder<File?>(
                future: _getImageFile(_card.imagePath),
                builder: (context, snapshot) {
                  final file = snapshot.data;

                  return GestureDetector(
                    onTap: file == null
                        ? null
                        : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CardImageViewerScreen(
                            imageFile: file,
                            heroTag: 'card-image-${_card.id}',
                          ),
                        ),
                      );
                    },
                    child: Hero(
                      tag: 'card-image-${_card.id}',
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        height: 240,
                        width: double.infinity,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: file != null
                              ? Image.file(file, fit: BoxFit.contain)
                              : Image.asset(
                            'assets/images/no_image.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // ===== 情報 =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _labelValue('カード名', _card.name),
                    if (_card.price != null)
                      _labelValue('価格', '¥${_card.price}'),
                    _labelValue('説明', _card.description),
                    _labelValue('取得日', _formatDate(_card.date)),
                    if (_card.source != null && _card.source!.isNotEmpty)
                      _labelValue('入手先', _card.source!),

                    if (_card.tags != null && _card.tags!.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'タグ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _card.tags!
                                .map((tag) => Chip(label: Text(tag)))
                                .toList(),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ===== 下固定ボタン =====
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _bottomButton(
                  label: '戻る',
                  icon: Icons.arrow_back,
                  onTap: () {
                    Navigator.pop(context, true);
                  },
                ),
                const SizedBox(width: 8),
                _bottomButton(
                  label: '編集',
                  icon: Icons.edit,
                  onTap: () async {
                    final updated = await Navigator.push<CardModel>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CardAddScreen(card: _card),
                      ),
                    );
                    if (updated != null) {
                      await Hive.box<CardModel>('cards')
                          .put(updated.id, updated);

                      if (!mounted) return;

                      Navigator.pop(context, true);
                    }
                  },
                ),
                const SizedBox(width: 8),

                _bottomButton(
                  label: _isListed ? '出品済み' : '出品',
                  icon: Icons.sell,
                  disabled: _isListed,
                  onTap: _isListed
                      ? null
                      : () async {
                    final dir = await getApplicationDocumentsDirectory();
                    final String? initialImagePath = _card.imagePath != null
                        ? path.join(dir.path, 'images', _card.imagePath!)
                        : null;

                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TradeCardAddScreen(
                          initialCardName: _card.name,
                          initialPrice: _card.price,
                          initialImagePath: initialImagePath,
                          initialCardId: _card.id,
                        ),
                      ),
                    );

                    if (!mounted) return;

                    if (result != null) {
                      Navigator.pop(context, true);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => TradeCardScreen()),
                      );
                    }
                  },
                ),
                const SizedBox(width: 8),

                _bottomButton(
                  label: '削除',
                  icon: Icons.delete_outline,
                  onTap: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('削除確認'),
                        content: const Text('このカードを削除しますか？'),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, false),
                            child: const Text('キャンセル'),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, true),
                            child: const Text('削除'),
                          ),
                        ],
                      ),
                    );

                    if (ok == true) {
                      await Hive.box<CardModel>('cards').delete(_card.id);
                      if (!mounted) return;
                      Navigator.pop(context, true);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
    );
  }
}