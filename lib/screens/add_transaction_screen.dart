//add_transcation_screen.dart

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import 'package:flutter/foundation.dart';
import '../models/budgetservice.dart';


class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}



class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>(); // form key for validation
  String _category = 'Food'; // default category
  double _amount = 0.0;
  bool _isIncome = false;
  DateTime _selectedDate = DateTime.now(); //default date as current date

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // form with validation
          child: ListView(
            children: [
              // input for transaction amount
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                  icon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                onSaved: (value) => _amount = double.parse(value!),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount'; // validate amount
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // dropdown for selecting category
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  icon: Icon(Icons.category),
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    _category = newValue!;
                  });
                },
                items: <String>['Food', 'Transportation', 'Entertainment']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Switch for Income/Expense selection
              SwitchListTile(
                title: const Text('Income'),
                value: _isIncome,
                onChanged: (bool value) {
                  setState(() {
                    _isIncome = value;
                  });
                },
                secondary: Icon(
                  _isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                  color: _isIncome ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 16),

              // Date picker for transaction date
              ListTile(
                title: Text(
                  'Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context), // Opens date picker
              ),
              const SizedBox(height: 16),

              // Button to add the transaction
              ElevatedButton.icon(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save(); // Save form data

                    // Create and save transaction
                    final transaction = Transaction(
                      category: _category,
                      amount: _amount,
                      isIncome: _isIncome,
                      date: _selectedDate,
                    );
                    Hive.box<Transaction>('transactions').add(transaction);

                    // Reset form after submission
                    _category = 'Food';
                    _amount = 0.0;
                    _isIncome = false;
                    _selectedDate = DateTime.now();
                    setState(() {});
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Transaction'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // date picker
  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked; // Update selected date
      });
    }
  }
  @override
  void initState() {
    super.initState();
    BudgetService().alertStream.listen((alert) {
      final msg = alert.type == BudgetAlertType.nearingLimit
          ? '⚠️ You’ve spent \$${alert.spent.toStringAsFixed(2)} of your '
          '${alert. budget.category ?? 'all'} '
          '${describeEnum(alert.budget.interval)} budget.'
          : '🚨 You’ve exceeded your '
          '${alert.budget.category ?? 'all'} '
          '${describeEnum(alert.budget.interval)} budget!';
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg))
      );
    });
  }

}