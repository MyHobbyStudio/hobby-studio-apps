import 'package:hive/hive.dart';

part 'allowance_model.g.dart';

@HiveType(typeId: 1)
class Allowance extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final int amount;

  Allowance({
    required this.date,
    required this.amount,
  });
}