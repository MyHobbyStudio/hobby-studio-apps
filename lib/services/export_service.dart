// services/export_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../models/card_model.dart';
import '../models/purchase_model.dart';

class ExportService {
  /// 🔑 バックアップ用JSONファイルを生成して返す
  static Future<File> createBackupFile() async {
    final cardBox = Hive.box<CardModel>('cards');
    final purchaseBox = Hive.box<Purchase>('purchases');

    final data = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'cards': cardBox.values.map((c) => c.toJson()).toList(),
      'purchases': purchaseBox.values.map((p) => p.toJson()).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(data);

    // 🔥 一時ディレクトリ（ユーザーが保存先を選ぶ前提）
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/card_manager_backup.json');

    await file.writeAsString(jsonString);

    return file;
  }
}