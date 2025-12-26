import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../models/card_model.dart';
import '../models/purchase_model.dart';

class ImportService {

  /// JSONファイルから全データを復元
  static Future<void> importAll(File file) async {
    final jsonString = await file.readAsString();
    final Map<String, dynamic> data = jsonDecode(jsonString);

    _validateBackupFormat(data);

    final cardBox = Hive.box<CardModel>('cards');
    final purchaseBox = Hive.box<Purchase>('purchases');

    await cardBox.clear();
    await purchaseBox.clear();

    await _importCards(data);
    await _importPurchases(data);
  }
  
  /// JSONファイルから全データを復元（既存データは削除）
  static Future<void> importPartial({
    required File file,
    required bool importCards,
    required bool importPurchases,
  }) async {
    final jsonString = await file.readAsString();
    final Map<String, dynamic> data = jsonDecode(jsonString);

    _validateBackupFormat(data);

    final cardBox = Hive.box<CardModel>('cards');
    final purchaseBox = Hive.box<Purchase>('purchases');

    if (importCards) {
      await cardBox.clear();
      await _importCards(data);
    }

    if (importPurchases) {
      await purchaseBox.clear();
      await _importPurchases(data);
    }
  }

  static void _validateVersion(Map<String, dynamic> data) {
    final int version = data['version'] ?? 1;
    if (version != 1) {
      throw Exception('未対応のバックアップバージョンです: $version');
    }
  }

  static Future<void> _importCards(Map<String, dynamic> data) async {
    final cardBox = Hive.box<CardModel>('cards');
    final List cardsJson = data['cards'] ?? [];

    for (final c in cardsJson) {
      final card = CardModel.fromJson(Map<String, dynamic>.from(c));
      await cardBox.put(card.id, card);
    }
  }

  static Future<void> _importPurchases(Map<String, dynamic> data) async {
    final purchaseBox = Hive.box<Purchase>('purchases');
    final List purchasesJson = data['purchases'] ?? [];

    for (final p in purchasesJson) {
      final purchase =
      Purchase.fromJson(Map<String, dynamic>.from(p));
      await purchaseBox.put(purchase.id, purchase);
    }
  }

  static void _validateBackupFormat(Map<String, dynamic> data) {
    // ===== アプリ識別 =====
    if (data['app'] != 'trading_card_manager') {
      throw Exception('このアプリ用のバックアップではありません');
    }

    // ===== バージョン =====
    final version = data['backupVersion'];
    if (version != 1) {
      throw Exception('未対応のバックアップバージョンです: $version');
    }

    // ⭐️===== 必須キー存在チェック =====
    if (!data.containsKey('cards') || data['cards'] is! List) {
      throw Exception('カードデータが見つかりません');
    }

    if (!data.containsKey('purchases') || data['purchases'] is! List) {
      throw Exception('出品データが見つかりません');
    }
  }
}
