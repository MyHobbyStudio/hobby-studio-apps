import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart';
import 'import_exception.dart';

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
      throw ImportException(
        'このファイルはカード管理アプリのバックアップではありません。\n'
            '正しいバックアップファイルを選択してください。',
      );
    }

    // ===== バージョン =====
    final version = data['backupVersion'];
    if (version != 1) {
      throw ImportException('未対応のバックアップバージョンです: $version');
    }

    // ===== 必須キー存在チェック =====
    if (!data.containsKey('cards') || data['cards'] is! List) {
      throw ImportException('カードデータが見つかりません');
    }

    if (!data.containsKey('purchases') || data['purchases'] is! List) {
      throw ImportException('出品データが見つかりません');
    }

    // ⭐️===== 空バックアップ防止（ここ！）=====
    final cards = data['cards'] as List;
    final purchases = data['purchases'] as List;

    if (cards.isEmpty && purchases.isEmpty) {
      throw ImportException(
        'バックアップに復元できるデータがありません',
      );
    }
  }
}
