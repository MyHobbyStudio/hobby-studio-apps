// services/export_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../models/card_model.dart';
import '../models/purchase_model.dart';

class ExportService {
  static String _buildBackupFileName() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');

    return 'card_manager_backup_'
        '${now.year}-${two(now.month)}-${two(now.day)}_'
        '${two(now.hour)}-${two(now.minute)}.json';
  }

  static Future<File> createBackupFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = _buildBackupFileName();
    final file = File('${dir.path}/$fileName');

    final cardBox = Hive.box<CardModel>('cards');
    final purchaseBox = Hive.box<Purchase>('purchases');

    final cards = cardBox.values.toList();
    final purchases = purchaseBox.values.toList();

    final data = {
      // ⭐️ アプリ識別子
      'app': 'trading_card_manager',

      // ⭐️ バックアップ仕様バージョン
      'backupVersion': 1,

      // ⭐️ 出力日時
      'exportedAt': DateTime.now().toIso8601String(),

      // ⭐️ 件数サマリー（UIで使える）
      'summary': {
        'cards': cards.length,
        'purchases': purchases.length,
      },

      // ⭐️ 実データ
      'cards': cards.map((c) => c.toJson()).toList(),
      'purchases': purchases.map((p) => p.toJson()).toList(),
    };

    await file.writeAsString(
      jsonEncode(data),
      flush: true,
    );

    return file;
  }
}