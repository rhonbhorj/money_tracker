
import 'package:flutter/material.dart';
import 'models/transaction_model.dart';
import 'services/api_service.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/budget_screen.dart';

void main() {
  runApp(const MoneyTrackerApp());
}

class MoneyTrackerApp extends StatelessWidget {
  const MoneyTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Money Tracker',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF16876A),
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F8F7), ///back ground color
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService api = ApiService();

  late Future<List<TransactionModel>> transactionsFuture;

  @override
  void initState() {
    super.initState();
    transactionsFuture = api.getTransactions();
  }

  String peso(double amount) => '₱${amount.toStringAsFixed(2)}';

  void reloadTransactions() {
    setState(() {
      transactionsFuture = api.getTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Money Tracker',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          // actions: [
          //   IconButton(
          //     onPressed: reloadTransactions,
          //     icon: const Icon(Icons.refresh),
          //   ),
          // ],
  actions: [
    IconButton(
      tooltip: 'Reports & Charts',
      icon: const Icon(Icons.bar_chart),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportsScreen(),
          ),
        );
      },
    ),
  IconButton(
    tooltip: 'Transaction History',
    icon: const Icon(Icons.receipt_long),
    onPressed: () async {
      final changed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => const TransactionsScreen(),
        ),
      );

      if (changed == true && mounted) {
        reloadTransactions();
      }
    },

  ),
  IconButton(
    tooltip: 'Monthly Budgets',
    icon: const Icon(Icons.account_balance_wallet),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const BudgetScreen(),
        ),
      );
    },
  ),

  ],


      ),
floatingActionButton: FloatingActionButton.extended(
  onPressed: () async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddTransactionScreen(),
      ),
    );

    if (saved == true && mounted) {
      reloadTransactions();
    }
  },
  icon: const Icon(Icons.add),
  label: const Text('Add Transaction'),
),


      body: FutureBuilder<List<TransactionModel>>(
        future: transactionsFuture,
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
                      Icons.cloud_off,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    const Text('Unable to connect to your API'),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: reloadTransactions,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final transactions = snapshot.data ?? [];

          final income = transactions
              .where((t) => t.type == 'income')
              .fold<double>(0, (sum, t) => sum + t.amount);

          final expenses = transactions
              .where((t) => t.type == 'expense')
              .fold<double>(0, (sum, t) => sum + t.amount);

          final balance = income - expenses;

          return RefreshIndicator(
            onRefresh: () async => reloadTransactions(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16876A),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Balance',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        peso(balance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _summary(
                              'Income',
                              income,
                              Icons.arrow_downward,
                              Colors.white,
                            ),
                          ),
                          Expanded(
                            child: _summary(
                              'Expenses',
                              expenses,
                              Icons.arrow_upward,
                              Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (transactions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text('No transactions yet.'),
                    ),
                  ),
                ...transactions.take(10).map((transaction) {
                  final isIncome = transaction.type == 'income';

                  return Card(
                    elevation: 0,
                    color: Colors.white,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isIncome
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        child: Icon(
                          isIncome
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: isIncome ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(transaction.category),
                      subtitle: Text(
                        transaction.note?.isNotEmpty == true
                            ? transaction.note!
                            : transaction.transactionDate,
                      ),
                      trailing: Text(
                        '${isIncome ? '+' : '-'}${peso(transaction.amount)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isIncome ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _summary(
    String title,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(color: color)),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          peso(amount),
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
