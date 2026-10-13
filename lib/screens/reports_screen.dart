
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/transaction_model.dart';
import '../services/api_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ApiService _apiService = ApiService();

  late Future<List<TransactionModel>> _transactionsFuture;

  // Default reporting period.
  String _selectedPeriod = 'this_month';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void _loadTransactions() {
    _transactionsFuture = _apiService.getTransactions();
  }

  Future<void> _refresh() async {
    setState(_loadTransactions);
    await _transactionsFuture;
  }

  DateTime get _periodStart {
    final now = DateTime.now();

    if (_selectedPeriod == 'last_month') {
      return DateTime(now.year, now.month - 1, 1);
    }

    return DateTime(now.year, now.month, 1);
  }

  DateTime get _nextPeriodStart {
    final start = _periodStart;
    return DateTime(start.year, start.month + 1, 1);
  }

  String get _periodLabel {
    final date = _periodStart;
    const months = [
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

    final monthName = months[date.month - 1];

    if (_selectedPeriod == 'last_month') {
      return 'Last Month ($monthName ${date.year})';
    }

    return 'This Month ($monthName ${date.year})';
  }

  String _money(double amount) {
    return '₱${amount.toStringAsFixed(2)}';
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  List<TransactionModel> _filterByPeriod(
    List<TransactionModel> transactions,
  ) {
    final start = _periodStart;
    final end = _nextPeriodStart;

    return transactions.where((transaction) {
      final date = DateTime.tryParse(transaction.transactionDate);

      if (date == null) {
        return false;
      }

      final transactionDay = DateTime(date.year, date.month, date.day);

      return !transactionDay.isBefore(start) &&
          transactionDay.isBefore(end);
    }).toList();
  }

  List<PieChartSectionData> _buildPieSections(
    List<MapEntry<String, double>> categories,
    double totalExpenses,
  ) {
    if (totalExpenses <= 0) {
      return [];
    }

    return List.generate(categories.length, (index) {
      final entry = categories[index];
      final percentage = entry.value / totalExpenses * 100;

      return PieChartSectionData(
        color: _categoryColor(index),
        value: entry.value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 75,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
    });
  }

  Color _categoryColor(int index) {
    const colors = [
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.red,
      Colors.amber,
      Colors.indigo,
      Colors.pink,
      Colors.brown,
      Colors.cyan,
    ];

    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Reports'),
        actions: [
          IconButton(
            tooltip: 'Refresh reports',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<TransactionModel>>(
        future: _transactionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
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
                    Text('Failed to load reports: ${snapshot.error}'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        setState(_loadTransactions);
                      },
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final allTransactions =
              snapshot.data ?? <TransactionModel>[];

          final transactions = _filterByPeriod(allTransactions);

          final incomeTransactions = transactions
              .where((t) => t.type.toLowerCase() == 'income')
              .toList();

          final expenseTransactions = transactions
              .where((t) => t.type.toLowerCase() == 'expense')
              .toList();

          final totalIncome = incomeTransactions.fold<double>(
            0,
            (sum, t) => sum + t.amount,
          );

          final totalExpenses = expenseTransactions.fold<double>(
            0,
            (sum, t) => sum + t.amount,
          );

          final balance = totalIncome - totalExpenses;

          final Map<String, double> expensesByCategory = {};

          for (final transaction in expenseTransactions) {
            expensesByCategory.update(
              transaction.category,
              (amount) => amount + transaction.amount,
              ifAbsent: () => transaction.amount,
            );
          }

          final sortedCategories = expensesByCategory.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Reporting Period',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  initialValue: _selectedPeriod,
                  decoration: const InputDecoration(
                    labelText: 'Select Month',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_month),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'this_month',
                      child: Text('This Month'),
                    ),
                    DropdownMenuItem(
                      value: 'last_month',
                      child: Text('Last Month'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPeriod = value;
                      });
                    }
                  },
                ),

                const SizedBox(height: 12),
                Text(
                  _periodLabel,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${_formatDate(_periodStart)} to '
                  '${_formatDate(_nextPeriodStart.subtract(
                    const Duration(days: 1),
                  ))}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  'Financial Overview',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Income',
                        amount: _money(totalIncome),
                        color: Colors.green,
                        icon: Icons.trending_up,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Expenses',
                        amount: _money(totalExpenses),
                        color: Colors.red,
                        icon: Icons.trending_down,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _SummaryCard(
                  title: 'Monthly Balance',
                  amount: _money(balance),
                  color: balance < 0 ? Colors.red : Colors.blue,
                  icon: Icons.account_balance_wallet,
                  fullWidth: true,
                ),

                const SizedBox(height: 28),
                const Text(
                  'Income vs. Expenses',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 20, 20, 16),
                    child: SizedBox(
                      height: 260,
                      child: _IncomeExpenseChart(
                        income: totalIncome,
                        expenses: totalExpenses,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),
                const Text(
                  'Expenses by Category',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: sortedCategories.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 36),
                            child: Center(
                              child: Text(
                                'No expenses for this period.',
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              SizedBox(
                                height: 220,
                                child: PieChart(
                                  PieChartData(
                                    sectionsSpace: 3,
                                    centerSpaceRadius: 35,
                                    sections: _buildPieSections(
                                      sortedCategories,
                                      totalExpenses,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              ...List.generate(
                                sortedCategories.length,
                                (index) {
                                  final entry = sortedCategories[index];
                                  final percentage =
                                      totalExpenses == 0
                                          ? 0.0
                                          : entry.value /
                                              totalExpenses *
                                              100;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 7,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: _categoryColor(index),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(entry.key),
                                        ),
                                        Text(
                                          '${percentage.toStringAsFixed(1)}%',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          _money(entry.value),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 20),
                Text(
                  '${transactions.length} transaction(s) included '
                  'in this report.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _IncomeExpenseChart extends StatelessWidget {
  final double income;
  final double expenses;

  const _IncomeExpenseChart({
    required this.income,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context) {
    final largest = income > expenses ? income : expenses;
    final maxY = largest <= 0 ? 100.0 : largest * 1.25;

    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceEvenly,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: income,
                color: Colors.green,
                width: 42,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: expenses,
                color: Colors.red,
                width: 42,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          ),
        ],
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: const Text('Amount (₱)'),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 55,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    value >= 1000
                        ? '₱${(value / 1000).toStringAsFixed(0)}k'
                        : '₱${value.toInt()}',
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                final label = value.toInt() == 0
                    ? 'Income'
                    : value.toInt() == 1
                        ? 'Expenses'
                        : '';

                if (label.isEmpty) {
                  return const SizedBox.shrink();
                }

                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;
  final IconData icon;
  final bool fullWidth;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    amount,
                    style: TextStyle(
                      color: color,
                      fontSize: fullWidth ? 22 : 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
