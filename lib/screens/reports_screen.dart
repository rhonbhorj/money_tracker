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
  late Future<List<TransactionModel>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void _loadTransactions() {
    _transactionsFuture = ApiService().getTransactions();
  }

  Future<void> _refresh() async {
    setState(_loadTransactions);
    await _transactionsFuture;
  }

  String _money(double amount) {
    return '₱${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Charts'),
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

          final transactions =
              snapshot.data ?? <TransactionModel>[];

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
            final category = transaction.category;
            expensesByCategory[category] =
                (expensesByCategory[category] ?? 0) +
                    transaction.amount;
          }

          final sortedCategories = expensesByCategory.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Financial Overview',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Financial summary cards.
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
                  title: 'Remaining Balance',
                  amount: _money(balance),
                  color: balance < 0 ? Colors.red : Colors.blue,
                  icon: Icons.account_balance_wallet,
                  fullWidth: true,
                ),
                const SizedBox(height: 28),

                // Income vs expenses chart.
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

                // Expense category chart.
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
                    child: expensesByCategory.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 36),
                            child: Center(
                              child: Text(
                                'No expense transactions available yet.',
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
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              ...List.generate(
                                sortedCategories.length,
                                (index) {
                                  final entry = sortedCategories[index];
                                  final color = _categoryColor(index);

                                  final percentage = totalExpenses == 0
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
                                            color: color,
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
                const Text(
                  'Reports are calculated from all transactions returned by your API.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(
    List<MapEntry<String, double>> categories,
  ) {
    final total = categories.fold<double>(
      0,
      (sum, entry) => sum + entry.value,
    );

    if (total == 0) return [];

    return List.generate(categories.length, (index) {
      final entry = categories[index];
      final percentage = entry.value / total * 100;

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
                String label;

                if (value.toInt() == 0) {
                  label = 'Income';
                } else if (value.toInt() == 1) {
                  label = 'Expenses';
                } else {
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