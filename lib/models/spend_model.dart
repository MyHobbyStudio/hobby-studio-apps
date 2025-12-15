
import 'package:hive/hive.dart';

part 'spend_model.g.dart';

@HiveType(typeId: 2)
class Spend extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final int amount;

  @HiveField(2)
  final String description;

  Spend({required this.date, required this.amount, this.description = ''});
}
