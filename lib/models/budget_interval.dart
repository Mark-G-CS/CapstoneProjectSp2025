// lib/models/budget_interval.dart
import 'package:hive/hive.dart';

part 'budget_interval.g.dart';

@HiveType(typeId: 1)
enum BudgetInterval {
  @HiveField(0)
  weekly,
  @HiveField(1)
  monthly,
}
