// lib/models/budget.dart
import 'package:hive/hive.dart';
import 'budget_interval.dart';

part 'budget.g.dart';

@HiveType(typeId: 2)
class Budget extends HiveObject {
  /// null = universal; otherwise ties to that category name
  @HiveField(0)
  final String? category;

  @HiveField(1)
  final double limit;

  @HiveField(2)
  final BudgetInterval interval;

  Budget({
    this.category,
    required this.limit,
    required this.interval,
  });
}
