import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/budget.dart';
import '../models/budget_interval.dart';
import '../models/transaction.dart';

/// Types of budget alerts emitted by the service.
enum BudgetAlertType {
  nearingLimit,
  exceededLimit,
}

/// Represents an alert when a budget threshold is reached.
class BudgetAlert {
  final Budget budget;
  final double spent;
  final BudgetAlertType type;

  BudgetAlert({
    required this.budget,
    required this.spent,
    required this.type,
  });
}

/// Service for managing budgets and emitting alerts.
class BudgetService {
  static const String _budgetBoxName = 'budgets';
  static const String _txBoxName = 'transactions';

  late final Box<Budget> _budgetBox;
  late final Box<Transaction> _txBox;

  final StreamController<BudgetAlert> _alertController =
  StreamController<BudgetAlert>.broadcast();

  /// Singleton
  BudgetService._();
  static final BudgetService _instance = BudgetService._();
  factory BudgetService() => _instance;

  /// Initialize budgets box and subscribe to transactions.
  Future<void> init() async {
    // Open or reuse budgets box
    if (Hive.isBoxOpen(_budgetBoxName)) {
      _budgetBox = Hive.box<Budget>(_budgetBoxName);
    } else {
      _budgetBox = await Hive.openBox<Budget>(_budgetBoxName);
    }

    // Transactions box must already be opened in main.dart
    _txBox = Hive.box<Transaction>(_txBoxName);

    // Watch for new/updated transactions
    _txBox.watch().listen((event) {
      if (!event.deleted && event.value is Transaction) {
        _processTransaction(event.value as Transaction);
      }
    });
  }

  /// Stream of budget alerts.
  Stream<BudgetAlert> get alertStream => _alertController.stream;

  void _processTransaction(Transaction tx) {
    final now = DateTime.now();

    for (final budget in _budgetBox.values) {
      if (budget.category != null && budget.category != tx.category) continue;

      final DateTime periodStart = budget.interval == BudgetInterval.weekly
          ? now.subtract(Duration(days: 7))
          : DateTime(now.year, now.month, 1);

      final spent = _txBox.values
          .where((t) =>
      !t.isIncome &&
          t.date.isAfter(periodStart) &&
          (budget.category == null || t.category == budget.category))
          .fold<double>(0, (sum, t) => sum + t.amount);

      if (spent >= budget.limit) {
        _alertController.add(
          BudgetAlert(budget: budget, spent: spent, type: BudgetAlertType.exceededLimit),
        );
      } else if (spent >= 0.9 * budget.limit) {
        _alertController.add(
          BudgetAlert(budget: budget, spent: spent, type: BudgetAlertType.nearingLimit),
        );
      }
    }
  }

  /// Retrieve all budgets.
  List<Budget> getAllBudgets() => _budgetBox.values.toList();

  /// Get a budget by category and interval.
  Budget? getBudget({String? category, required BudgetInterval interval}) {
    final key = _keyFor(category, interval);
    return _budgetBox.get(key);
  }

  /// Create or update a budget.
  Future<void> createOrUpdateBudget({
    String? category,
    required double limit,
    required BudgetInterval interval,
  }) async {
    final key = _keyFor(category, interval);
    final budget = Budget(category: category, limit: limit, interval: interval);
    await _budgetBox.put(key, budget);
  }

  /// Delete a budget.
  Future<void> deleteBudgetByKey({String? category, required BudgetInterval interval}) async {
    final key = _keyFor(category, interval);
    await _budgetBox.delete(key);
  }

  String _keyFor(String? category, BudgetInterval interval) {
    final cat = (category == null || category.isEmpty) ? 'all' : category;
    return '\${cat}_\${describeEnum(interval)}';
  }

  /// Clean up resources.
  Future<void> dispose() async {
    await _alertController.close();
  }
}
