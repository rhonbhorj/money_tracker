
import 'package:flutter/material.dart';

import '../models/monthly_budget_model.dart';
import '../models/transaction_model.dart';
import '../services/api_service.dart';
import '../services/budget_api_service.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final BudgetApiService _api = BudgetApiService();
  final ApiService _transactionApi = ApiService();

  // Temporary user ID for development.
  // Replace with the logged-in user's ID later.
  final int _userId = 1;

  late DateTime _selectedMonth;

  List<MonthlyBudgetModel> _budgets = [];
  List<TransactionModel> _transactions = [];

  bool _isLoading = true;
  String? _error;

  double get _totalBudget => _budgets.fold(
        0.0,
        (total, budget) => total + budget.budgetAmount,
      );

  double get _totalSpent => _transactions
      .where(
        (transaction) =>
            transaction.type.trim().toLowerCase() == 'expense',
      )
      .fold(
        0.0,
        (total, transaction) => total + transaction.amount,
      );

  double get _remainingBudget => _totalBudget - _totalSpent;

  double _spentForCategory(String category) {
    return _transactions
        .where(
          (transaction) =>
              transaction.type.trim().toLowerCase() == 'expense' &&
              transaction.category.trim().toLowerCase() ==
                  category.trim().toLowerCase(),
        )
        .fold(
          0.0,
          (total, transaction) => total + transaction.amount,
        );
  }

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);

    _loadBudgets();
  }

  String get _monthKey =>
      '${_selectedMonth.year}-'
      '${_selectedMonth.month.toString().padLeft(2, '0')}-01';

  String get _monthLabel =>
      '${_monthNames[_selectedMonth.month - 1]} '
      '${_selectedMonth.year}';

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  Future<void> _loadBudgets() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _api.getBudgets(
          userId: _userId,
          budgetMonth: _monthKey,
        ),
        _transactionApi.getTransactions(),
      ]);

      final budgets = results[0] as List<MonthlyBudgetModel>;
      final transactions = results[1] as List<TransactionModel>;

      final monthStart = DateTime(
        _selectedMonth.year,
        _selectedMonth.month,
      );

      final nextMonthStart = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
      );

      final monthTransactions = transactions.where((transaction) {
        final date = DateTime.tryParse(transaction.transactionDate);

        if (date == null) return false;

        return !date.isBefore(monthStart) &&
            date.isBefore(nextMonthStart);
      }).toList();

      if (!mounted) return;

      setState(() {
        _budgets = budgets;
        _transactions = monthTransactions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + offset,
      );
    });

    _loadBudgets();
  }

  Future<void> _showBudgetForm({
    MonthlyBudgetModel? existing,
  }) async {
    final formKey = GlobalKey<FormState>();

    final amountController = TextEditingController(
      text: existing == null
          ? ''
          : existing.budgetAmount.toStringAsFixed(2),
    );

    final categories = [
      'Food',
      'Transportation',
      'Shopping',
      'Bills',
      'Entertainment',
      'Health',
      'Education',
      'Other',
    ];

    String? selectedCategory = existing?.category;
    bool saving = false;

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                existing == null
                    ? 'Add Monthly Budget'
                    : 'Edit Monthly Budget',
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          ...categories.map(
                            (category) => DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            ),
                          ),
                          if (selectedCategory != null &&
                              !categories.contains(selectedCategory))
                            DropdownMenuItem<String>(
                              value: selectedCategory,
                              child: Text(selectedCategory!),
                            ),
                        ],
                        onChanged: existing != null
                            ? null
                            : (value) {
                                setDialogState(() {
                                  selectedCategory = value;
                                });
                              },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Select a category';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: amountController,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Monthly budget',
                          prefixText: '₱ ',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final amount = double.tryParse(
                            (value ?? '').trim(),
                          );

                          if (amount == null ||
                              !amount.isFinite ||
                              amount <= 0) {
                            return 'Enter an amount greater than zero';
                          }

                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          setDialogState(() {
                            saving = true;
                          });

                          try {
                            final budget = MonthlyBudgetModel(
                              id: existing?.id,
                              userId: _userId,
                              category: selectedCategory!,
                              budgetAmount: double.parse(
                                amountController.text.trim(),
                              ),
                              budgetMonth: _monthKey,
                            );

                            await _api.saveBudget(budget);

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext, true);
                            }
                          } catch (e) {
                            if (!dialogContext.mounted) return;

                            setDialogState(() {
                              saving = false;
                            });

                            ScaffoldMessenger.of(dialogContext)
                                .showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Could not save budget: $e',
                                ),
                              ),
                            );
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Save Budget'),
                ),
              ],
            );
          },
        );
      },
    );

    amountController.dispose();

    if (saved == true && mounted) {
      await _loadBudgets();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Budget saved successfully'),
        ),
      );
    }
  }

  Future<void> _deleteBudget(
    MonthlyBudgetModel budget,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Budget'),
        content: Text(
          'Delete the ${budget.category} budget for $_monthLabel?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || budget.id == null) return;

    try {
      await _api.deleteBudget(
        budgetId: budget.id!,
        userId: _userId,
      );

      if (!mounted) return;

      await _loadBudgets();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Budget deleted successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete budget: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Budgets'),
        actions: [
          IconButton(
            tooltip: 'Refresh budgets',
            onPressed: _loadBudgets,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBudgetForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Budget'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          tooltip: 'Previous month',
                          onPressed: () => _changeMonth(-1),
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Text(
                          _monthLabel,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        IconButton(
                          tooltip: 'Next month',
                          onPressed: () => _changeMonth(1),
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Total Monthly Budget'),
                    const SizedBox(height: 6),
                    Text(
                      '₱${_totalBudget.toStringAsFixed(2)}',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text('${_budgets.length} budget categories'),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Spent'),
                        Text(
                          '₱${_totalSpent.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Remaining Budget'),
                        Text(
                          '₱${_remainingBudget.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: _remainingBudget < 0
                                ? Colors.red
                                : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: _loadBudgets,
                                child: const Text('Try Again'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _budgets.isEmpty
                        ? const Center(
                            child: Text(
                              'No budgets for this month.\n'
                              'Tap Add Budget to get started.',
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              16,
                              0,
                              16,
                              100,
                            ),
                            itemCount: _budgets.length,
                            itemBuilder: (context, index) {
                              final budget = _budgets[index];
                              final spent =
                                  _spentForCategory(budget.category);
                              final limit = budget.budgetAmount;

                              final progress = limit > 0
                                  ? (spent / limit)
                                      .clamp(0.0, 1.0)
                                      .toDouble()
                                  : 0.0;

                              final remaining = limit - spent;
                              final overBudget = spent > limit;

                              return Card(
                                margin: const EdgeInsets.only(
                                  bottom: 10,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            child: Icon(
                                              _categoryIcon(
                                                budget.category,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              budget.category,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          PopupMenuButton<String>(
                                            onSelected: (value) {
                                              if (value == 'edit') {
                                                _showBudgetForm(
                                                  existing: budget,
                                                );
                                              } else if (value ==
                                                  'delete') {
                                                _deleteBudget(budget);
                                              }
                                            },
                                            itemBuilder: (context) =>
                                                const [
                                              PopupMenuItem(
                                                value: 'edit',
                                                child: Text('Edit'),
                                              ),
                                              PopupMenuItem(
                                                value: 'delete',
                                                child: Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Spent: ₱'
                                            '${spent.toStringAsFixed(2)}',
                                          ),
                                          Text(
                                            'Limit: ₱'
                                            '${limit.toStringAsFixed(2)}',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      LinearProgressIndicator(
                                        value: progress,
                                        minHeight: 8,
                                        color: overBudget
                                            ? Colors.red
                                            : Colors.blue,
                                        backgroundColor:
                                            Colors.grey.shade300,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        overBudget
                                            ? 'Over budget by ₱'
                                                '${(spent - limit).toStringAsFixed(2)}'
                                            : 'Remaining: ₱'
                                                '${remaining.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: overBudget
                                              ? Colors.red
                                              : Colors.green,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (limit > 0 &&
                                          spent / limit >= 0.8 &&
                                          !overBudget)
                                        const Padding(
                                          padding: EdgeInsets.only(top: 6),
                                          child: Text(
                                            'Warning: You have used at '
                                            'least 80% of this budget.',
                                            style: TextStyle(
                                              color: Colors.orange,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transportation':
        return Icons.directions_bus;
      case 'shopping':
        return Icons.shopping_bag;
      case 'bills':
        return Icons.receipt_long;
      case 'entertainment':
        return Icons.movie;
      case 'health':
        return Icons.health_and_safety;
      case 'education':
        return Icons.school;
      default:
        return Icons.account_balance_wallet;
    }
  }
}
