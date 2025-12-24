import 'package:hive/hive.dart';

part 'purchase_model.g.dart';

@HiveType(typeId: 3)
class Purchase extends HiveObject {
  @HiveField(0)
  String id; // 一意のID

  @HiveField(1)
  String cardName;

  @HiveField(2)
  int price;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  String? imagePath; // カード写真のパス

  @HiveField(5)
  String listingSite;

  @HiveField(6)
  bool isSold; // 売れたかどうか

  @HiveField(7)
  String? listingDescription;

  @HiveField(8)
  String? cardId;

  Purchase({
    required this.id,
    required this.cardName,
    required this.price,
    required this.date,
    this.imagePath,
    this.listingSite = 'その他',
    this.isSold = false,
    this.listingDescription,
    this.cardId,
  });

  // =====================
  // ⭐️ JSON Export
  // =====================
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cardName': cardName,
      'price': price,
      'date': date.toIso8601String(),
      'imagePath': imagePath,
      'listingSite': listingSite,
      'isSold': isSold,
      'listingDescription': listingDescription,
      'cardId': cardId,
    };
  }

  // =====================
  // ⭐️ JSON Import
  // =====================
  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['id'],
      cardName: json['cardName'],
      price: json['price'],
      date: DateTime.parse(json['date']),
      imagePath: json['imagePath'],
      listingSite: json['listingSite'] ?? '',
      isSold: json['isSold'] ?? false,
      listingDescription: json['listingDescription'],
      cardId: json['cardId'],
    );
  }
}
