// screens/card_detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:hive/hive.dart';

import '../models/card_model.dart';
import 'card_add_screen.dart';
import 'card_image_viewer_screen.dart';

class CardDetailScreen extends StatelessWidget {
  final CardModel card;
  const CardDetailScreen({super.key, required this.card});

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
  // UI
  // =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(card.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== 画像 =====
            FutureBuilder<File?>(
              future: _getImageFile(card.imagePath),
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
                          heroTag: 'card-image-${card.id}',
                        ),
                      ),
                    );
                  },
                  child: Hero(
                    tag: 'card-image-${card.id}',
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      height: 240,
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: file != null
                            ? Image.file(
                          file,
                          fit: BoxFit.contain, // ★ 全体表示
                        )
                            : Image.asset(
                          'assets/images/no_image.png',
                          fit: BoxFit.contain, // ★ 全体表示
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
                  _labelValue('カード名', card.name),

                  if (card.price != null)
                    _labelValue('価格', '¥${card.price}'),

                  _labelValue('説明', card.description),

                  _labelValue('取得日', _formatDate(card.date)),

                  if (card.source != null && card.source!.isNotEmpty)
                    _labelValue('入手先', card.source!),

                  if (card.tags != null && card.tags!.isNotEmpty)
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
                          children: card.tags!
                              .map(
                                (tag) => Chip(
                              label: Text(tag),
                            ),
                          )
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
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              _bottomButton(
                label: '編集',
                icon: Icons.edit,
                onTap: () async {
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CardAddScreen(card: card),
                    ),
                  );
                  if (updated is CardModel) {
                    Navigator.pop(context, true);
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
                    Hive.box<CardModel>('cards').delete(card.id);
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

  // =====================
  // Bottom Button
  // =====================
  Widget _bottomButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
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
                style: const TextStyle(
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