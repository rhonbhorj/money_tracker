import 'package:flutter/material.dart';

import '../models/monthly_budget_model.dart';
import '../services/budget_api_service.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final BudgetApiService _api = BudgetApiService();

  // Temporary user ID for development.
  // Replace with the logged-in user's ID later.
  final int _userId = 1;

  late DateTime _selectedMonth;
  List<MonthlyBudgetModel> _budgets = [];

  bool _isLoading = true;
  String? _error;

  double get _totalBudget => _budgets.fold(
        0,
        (total, budget) => total + budget.budgetAmount,
      );

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
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _api.getBudgets(
        userId: _userId,
        budgetMonth: _monthKey,
      );

      if (!mounted) return;

      setState(() {
        _budgets = result;
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

    final categoryController = TextEditingController(
      text: existing?.category ?? '',
    );

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
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ),
                          ),
                          if (selectedCategory != null &&
                              !categories.contains(selectedCategory))
                            DropdownMenuItem(
                              value: selectedCategory,
                              child: Text(selectedCategory!),
                            ),
                        ],
                        onChanged: existing != null
                            ? null
                            : (value) {
                                setDialogState(() {
                                  selectedCategory = value;
                                  categoryController.text = value ?? '';
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

                          if (amount == null || amount < 0) {
                            return 'Enter a valid amount';
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

                          setDialogState(() => saving = true);

                          try {
                            final amount = double.parse(
                              amountController.text.trim(),
                            );

                            final budget = MonthlyBudgetModel(
                              id: existing?.id,
                              userId: _userId,
                              category: selectedCategory!,
                              budgetAmount: amount,
                              budgetMonth: _monthKey,
                            );

                            await _api.saveBudget(budget);

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext, true);
                            }
                          } catch (e) {
                            setDialogState(() => saving = false);

                            if (!dialogContext.mounted) return;

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

    categoryController.dispose();
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
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget'),
        content: Text(
          'Delete the ${budget.category} budget for $_monthLabel?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
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
        const SnackBar(content: Text('Budget deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete budget: $e')),
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
                          onPressed: () => _changeMonth(-1),
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Text(
                          _monthLabel,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge,
                        ),
                        IconButton(
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
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
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
                              16, 0, 16, 100,
                            ),
                            itemCount: _budgets.length,
                            itemBuilder: (context, index) {
                              final budget = _budgets[index];

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Icon(
                                      _categoryIcon(budget.category),
                                    ),
                                  ),
                                  title: Text(budget.category),
                                  subtitle: const Text(
                                    'Monthly spending limit',
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '₱${budget.budgetAmount.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            _showBudgetForm(
                                              existing: budget,
                                            );
                                          } else if (value == 'delete') {
                                            _deleteBudget(budget);
                                          }
                                        },
                                        itemBuilder: (context) => const [
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