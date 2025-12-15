import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/card_model.dart';
import 'card_add_screen.dart';
import 'card_image_viewer_screen.dart';
import 'package:hive/hive.dart';

class CardDetailScreen extends StatelessWidget {
  final CardModel card;

  const CardDetailScreen({super.key, required this.card});

  Future<File?> _getImageFile(String? fileName) async {
    if (fileName == null) return null;
    final dir = await getApplicationDocumentsDirectory();
    final file = File(path.join(dir.path, 'images', fileName));
    return await file.exists() ? file : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(card.name),
      ),

      /// =======================
      /// メイン情報（消してはいけない）
      /// =======================
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120), // ←下ボタン分の余白
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// ===== 画像 =====
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
                            ? Image.file(file, fit: BoxFit.cover)
                            : Image.asset(
                          'assets/images/no_image.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            /// ===== 情報 =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  if (card.price != null)
                    Text(
                      '¥${card.price}',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                  const SizedBox(height: 12),

                  Text(
                    card.description,
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 16),

                  if (card.tags != null && card.tags!.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      children: card.tags!.map((tag) {
                        return Chip(label: Text(tag));
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),

      /// =======================
      /// 下固定ボタン（ここが新規）
      /// =======================
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
                  if (updated != null) {
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
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('キャンセル'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('削除'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    // ★ ここが重要
                    final box = Hive.box<CardModel>('cards');
                    await box.delete(card.id);
                    // 一覧画面に「削除された」ことを伝えて戻る
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

  /// =======================
  /// 共通ボタン（ここに置く）
  /// =======================
  Widget _bottomButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white70,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}