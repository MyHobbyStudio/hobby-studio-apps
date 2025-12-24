import 'package:hive/hive.dart';

part 'card_model.g.dart';

@HiveType(typeId: 0)
class CardModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String description;

  @HiveField(3)
  String? imagePath;

  @HiveField(4)
  int? price;

  @HiveField(5)
  bool? _isWishList;

  @HiveField(6)
  String? source; // ★ 入手先は1つに戻す

  @HiveField(7)
  DateTime? date;

  @HiveField(8)
  List<String>? tags;

  CardModel({
    required this.id,
    required this.name,
    required this.description,
    this.imagePath,
    this.price,
    bool? isWishList,
    this.source,
    this.date,
    this.tags,
  }) : _isWishList = isWishList;

  // null の場合は false として扱う
  bool get isWishList => _isWishList ?? false;

  set isWishList(bool value) {
    _isWishList = value;
  }


  // =====================
  // ⭐️ JSON Export
  // =====================
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'description': description,
      'date': date?.toIso8601String(),
      'imagePath': imagePath,
      'source': source,
      'tags': tags,
      'isWishList': isWishList,
    };
  }

  // =====================
  // ⭐️ JSON Import
  // =====================
  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      id: json['id'],
      name: json['name'],
      price: json['price'],
      description: json['description'] ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : null,
      imagePath: json['imagePath'],
      source: json['source'],
      tags: json['tags'] != null
          ? List<String>.from(json['tags'])
          : null,
      isWishList: json['isWishList'] ?? false,
    );
  }
}
