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

  Purchase({
    required this.id,
    required this.cardName,
    required this.price,
    required this.date,
    this.imagePath,
    this.listingSite = 'その他',
    this.isSold = false,
  });
}
