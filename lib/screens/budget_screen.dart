// lib/screens/budget_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';              // for describeEnum
import '../models/budget.dart';
import '../models/budget_interval.dart';
import '../models/budgetservice.dart';
import 'package:hive/hive.dart';
import '../models/transaction.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({Key? key}) : super(key: key);
  @override
  _BudgetScreenState createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  late List<Budget> _budgets;

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  void _loadBudgets() {
    _budgets = BudgetService().getAllBudgets();
  }
  /// 1) Add this method for “are you sure?” before deleting:
  Future<void> _confirmDelete(Budget b) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Budget'),
        content: const Text('Are you sure you want to delete this budget?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      BudgetService().deleteBudgetByKey(
        category: b.category,
        interval: b.interval,
      );
      setState(_loadBudgets);
    }
  }
  Future<void> _showBudgetDialog({Budget? existing}) async {
    final _formKey = GlobalKey<FormState>();
    String? category = existing?.category;
    double? limit = existing?.limit;
    BudgetInterval interval = existing?.interval ?? BudgetInterval.monthly;



    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'New Budget' : 'Edit Budget'),
        content: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              initialValue: limit?.toString(),
              decoration: const InputDecoration(labelText: 'Limit (\$)'),
              keyboardType: TextInputType.number,
              validator: (v) => (v == null || double.tryParse(v)==null)
                  ? 'Enter a number' : null,
              onSaved: (v) => limit = double.parse(v!),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<BudgetInterval>(
              value: interval,
              decoration: const InputDecoration(labelText: 'Interval'),
              items: BudgetInterval.values.map((intv) {
                return DropdownMenuItem(
                  value: intv,
                  child: Text(describeEnum(intv)),
                );
              }).toList(),
              onChanged: (v) => interval = v!,
            ),
            const SizedBox(height: 12),
                    // ← insert this static dropdown instead
                    DropdownButtonFormField<String>(
                          value: category ?? 'All',
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                      ),
                    items: <String>[
                      'All',
                      'Food',
                      'Transportation',
                      'Entertainment',
                    ].map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(cat),
                  );
                }).toList(),
                onChanged: (v) => category = (v == 'All' ? null : v),
                onSaved:   (v) => category = (v == 'All' ? null : v),
              ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                BudgetService().createOrUpdateBudget(
                  category: category?.isEmpty == true ? null : category,
                  limit: limit!,
                  interval: interval,
                );
                setState(() => _loadBudgets());
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Budgets'),
      ),
      body: _budgets.isEmpty
          ? const Center(child: Text('No budgets set.'))
          : ListView.builder(
        itemCount: _budgets.length,
        itemBuilder: (ctx, i) {
          final b = _budgets[i];
          final title = b.category ?? 'All Categories';
          final subtitle = '${describeEnum(b.interval)} — \$${b.limit.toStringAsFixed(2)}';
          return ListTile(
            title: Text(title),
            subtitle: Text(subtitle),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showBudgetDialog(existing: b),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _confirmDelete(b),
                ),
              ],
            ),
          );

        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBudgetDialog(),
        child: const Icon(Icons.add),
        tooltip: 'Add Budget',
      ),
    );
  }
}
