
import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/api_service.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _api = ApiService();

  String _type = 'expense';
  String _category = 'Food';
  DateTime _date = DateTime.now();
  bool _saving = false;

  final Map<String, List<String>> _categories = {
    'expense': [
      'Food',
      'Transportation',
      'Shopping',
      'Bills',
      'Health',
      'Education',
      'Entertainment',
      'Other',
    ],
    'income': [
      'Salary',
      'Business',
      'Freelance',
      'Investment',
      'Gift',
      'Other',
    ],
  };

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selected != null && mounted) {
      setState(() => _date = selected);
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final transaction = TransactionModel(
        id: 0,
        type: _type,
        category: _category,
        amount: double.parse(_amountController.text.trim()),
        transactionDate:
            '${_date.year.toString().padLeft(4, '0')}-'
            '${_date.month.toString().padLeft(2, '0')}-'
            '${_date.day.toString().padLeft(2, '0')}',
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      await _api.addTransaction(transaction);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save transaction: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Transaction Type',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'expense',
                  label: Text('Expense'),
                  icon: Icon(Icons.arrow_upward),
                ),
                ButtonSegment(
                  value: 'income',
                  label: Text('Income'),
                  icon: Icon(Icons.arrow_downward),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (selection) {
                setState(() {
                  _type = selection.first;
                  _category = _categories[_type]!.first;
                });
              },
            ),
            const SizedBox(height: 24),

            const Text(
              'Amount (₱)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                prefixText: '₱ ',
                hintText: '0.00',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final amount = double.tryParse(value?.trim() ?? '');

                if (amount == null ||
                    !amount.isFinite ||
                    amount <= 0 ||
                    amount > 9999999999.99) {
                  return 'Enter a valid positive amount';
                }

                return null;
              },
            ),
            const SizedBox(height: 20),

            const Text(
              'Category',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
   
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: _categories[_type]!
                      .map(
                        (category) => DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _category = value;
                      });
                    }
                  },
                ),

            const SizedBox(height: 20),

            const Text(
              'Transaction Date',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _selectDate,
              icon: const Icon(Icons.calendar_month),
              label: Text(
                '${_date.year}-'
                '${_date.month.toString().padLeft(2, '0')}-'
                '${_date.day.toString().padLeft(2, '0')}',
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Note (Optional)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _noteController,
              maxLength: 255,
              decoration: const InputDecoration(
                hintText: 'e.g. Lunch, monthly salary',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _saving ? null : _saveTransaction,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _saving ? 'Saving...' : 'Save Transaction',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
