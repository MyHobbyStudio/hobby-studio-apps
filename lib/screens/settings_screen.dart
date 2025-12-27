import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../services/export_service.dart';
import '../services/import_exception.dart';
import '../services/import_service.dart';
import 'package:file_picker/file_picker.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<File> _getBackupFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/card_manager_backup.json');
  }

  Future<File?> _pickBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) {
      return null;
    }

    return File(result.files.single.path!);
  }

  Future<void> _confirmAndRun({
    required BuildContext context,
    required String title,
    required String message,
    required Future<void> Function() onConfirm,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('実行'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await onConfirm();

      if (!context.mounted) return;

      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('処理が完了しました')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'データ管理',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          // ===== エクスポート =====
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('データをエクスポート'),
            subtitle: const Text('JSONファイルとして保存'),
            onTap: () async {
              try {
                // ① JSONバックアップファイル生成
                final file = await ExportService.createBackupFile();

                if (!context.mounted) return;

                // ② Share Sheet を開く
                await Share.shareXFiles(
                  [XFile(file.path)],
                  text: 'カード管理アプリのバックアップデータ',
                  subject: 'card_manager_backup.json',
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('エクスポートに失敗しました: $e')),
                );
              }
            },
          ),

          const Divider(),

          // ===== インポート（全）=====
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('全データをインポート'),
            subtitle: const Text('カード・出品データをすべて復元'),
            onTap: () {
              _confirmAndRun(
                context: context,
                title: '全データを復元',
                message:
                '現在のカード・出品データはすべて削除されます。\n\n'
                    '※ 画像データは復元されません。\n'
                    '新しい端末で再度登録してください。',
                onConfirm: () async {
                  final file = await _pickBackupFile();
                  if (file == null) return;

                  try {
                    await ImportService.importAll(file);
                  } on ImportException catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.message)),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('インポートに失敗しました')),
                    );
                  }
                },
              );
            },
          ),

          // ===== インポート（カードのみ）=====
          ListTile(
            leading: const Icon(Icons.credit_card),
            title: const Text('カードのみインポート'),
            subtitle: const Text('出品データは保持'),
            onTap: () {
              _confirmAndRun(
                context: context,
                title: 'カードのみ復元',
                message:
                '現在のカード・出品データはすべて削除されます。\n\n'
                    '※ 画像データは復元されません。\n'
                    '新しい端末で再度登録してください。',
                onConfirm: () async {
                  final file = await _pickBackupFile();
                  if (file == null) return;

                  await ImportService.importPartial(
                    file: file,
                    importCards: true,
                    importPurchases: false,
                  );
                },
              );
            },
          ),

          // ===== インポート（出品のみ）=====
          ListTile(
            leading: const Icon(Icons.sell),
            title: const Text('出品データのみインポート'),
            subtitle: const Text('カードデータは保持'),
            onTap: () {
              _confirmAndRun(
                context: context,
                title: '出品データのみ復元',
                message:
                '現在のカード・出品データはすべて削除されます。\n\n'
                    '※ 画像データは復元されません。\n'
                    '新しい端末で再度登録してください。',
                onConfirm: () async {
                  final file = await _pickBackupFile();
                  if (file == null) return;

                  await ImportService.importPartial(
                    file: file,
                    importCards: false,
                    importPurchases: true,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}