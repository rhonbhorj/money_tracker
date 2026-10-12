import 'package:flutter/material.dart';

void main() {
  runApp(const MoneyTrackerApp());
}

class MoneyTrackerApp extends StatelessWidget {
  const MoneyTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // title: 'Money Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF16845B),
        ),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home.'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
 
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: Text(widget.title),
      ),
      body: Center(
 
        child: Column(
       
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}



// class DashboardScreen extends StatefulWidget {
//   const DashboardScreen({super.key});

//   @override
//   // State<DashboardScreen> createState() => _DashboardScreenState();
// }

// class _DashboardScreenState extends State<DashboardScreen> {
//   int selectedIndex = 0;

//   final List<Map<String, dynamic>> transactions = [
//     {
//       'title': 'Monthly Salary',
//       'category': 'Income',
//       'amount': 32000.0,
//       'icon': Icons.account_balance_wallet_outlined,
//       'color': Colors.green,
//     },
//     {
//       'title': 'Groceries',
//       'category': 'Food & Drinks',
//       'amount': -1250.0,
//       'icon': Icons.shopping_basket_outlined,
//       'color': Colors.orange,
//     },
//     {
//       'title': 'Transportation',
//       'category': 'Travel',
//       'amount': -300.0,
//       'icon': Icons.directions_bus_outlined,
//       'color': Colors.blue,
//     },
//     {
//       'title': 'Electricity Bill',
//       'category': 'Utilities',
//       'amount': -850.0,
//       'icon': Icons.bolt_outlined,
//       'color': Colors.purple,
//     },
//   ];

//   double get totalIncome => transactions
//       .where((t) => (t['amount'] as double) > 0)
//       .fold(0.0, (sum, t) => sum + (t['amount'] as double));

//   double get totalExpenses => transactions
//       .where((t) => (t['amount'] as double) < 0)
//       .fold(0.0, (sum, t) => sum + (t['amount'] as double).abs());

//   double get balance => totalIncome - totalExpenses;

//   String money(double amount) =>
//       '₱${amount.toStringAsFixed(2).replaceAllMapped(
//             RegExp(r'\B(?=(\d{3})+(?!\d))'),
//             (match) => ',',
//           )}';

//   void addSampleExpense() {
//     setState(() {
//       transactions.insert(0, {
//         'title': 'New Expense',
//         'category': 'Other',
//         'amount': -100.0,
//         'icon': Icons.receipt_long_outlined,
//         'color': Colors.redAccent,
//       });
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isWide = MediaQuery.of(context).size.width >= 700;

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color(0xFFF5F7FA),
//         title: const Text(
//           'Money Tracker',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         actions: [
//           IconButton(
//             tooltip: 'Notifications',
//             onPressed: () {},
//             icon: const Icon(Icons.notifications_none),
//           ),
//           const SizedBox(width: 12),
//         ],
//       ),
//       body: Center(
//         child: ConstrainedBox(
//           constraints: const BoxConstraints(maxWidth: 1000),
//           child: ListView(
//             padding: const EdgeInsets.all(20),
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(24),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF16845B),
//                   borderRadius: BorderRadius.circular(24),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Total Balance',
//                       style: TextStyle(
//                         color: Colors.white70,
//                         fontSize: 16,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     Text(
//                       money(balance),
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 32,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     const Row(
//                       children: [
//                         Icon(
//                           Icons.trending_up,
//                           color: Colors.white,
//                         ),
//                         SizedBox(width: 8),
//                         Text(
//                           'Track your money with confidence',
//                           style: TextStyle(color: Colors.white),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 20),
//               LayoutBuilder(
//                 builder: (context, constraints) {
//                   final cardWidth =
//                       isWide ? (constraints.maxWidth - 16) / 2 : null;

//                   return Wrap(
//                     spacing: 16,
//                     runSpacing: 16,
//                     children: [
//                       SizedBox(
//                         width: cardWidth ??
//                             (constraints.maxWidth - 1) / 2,
//                         child: SummaryCard(
//                           title: 'Income',
//                           amount: money(totalIncome),
//                           icon: Icons.arrow_downward,
//                           color: const Color(0xFF16845B),
//                         ),
//                       ),
//                       SizedBox(
//                         width: cardWidth ??
//                             (constraints.maxWidth - 1) / 2,
//                         child: SummaryCard(
//                           title: 'Expenses',
//                           amount: money(totalExpenses),
//                           icon: Icons.arrow_upward,
//                           color: Colors.redAccent,
//                         ),
//                       ),
//                     ],
//                   );
//                 },
//               ),
//               const SizedBox(height: 28),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text(
//                     'Recent Transactions',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   TextButton(
//                     onPressed: () => setState(() => selectedIndex = 1),
//                     child: const Text('See all'),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               ...transactions.map(
//                 (transaction) => TransactionTile(
//                   title: transaction['title'] as String,
//                   category: transaction['category'] as String,
//                   amount: transaction['amount'] as double,
//                   icon: transaction['icon'] as IconData,
//                   color: transaction['color'] as Color,
//                   formatMoney: money,
//                 ),
//               ),
//               const SizedBox(height: 90),
//             ],
//           ),
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: addSampleExpense,
//         tooltip: 'Add sample expense',
//         backgroundColor: const Color(0xFF16845B),
//         foregroundColor: Colors.white,
//         child: const Icon(Icons.add),
//       ),
//       bottomNavigationBar: NavigationBar(
//         selectedIndex: selectedIndex,
//         onDestinationSelected: (index) {
//           setState(() => selectedIndex = index);
//         },
//         destinations: const [
//           NavigationDestination(
//             icon: Icon(Icons.home_outlined),
//             selectedIcon: Icon(Icons.home),
//             label: 'Home',
//           ),
//           NavigationDestination(
//             icon: Icon(Icons.receipt_long_outlined),
//             label: 'Transactions',
//           ),
//           NavigationDestination(
//             icon: Icon(Icons.bar_chart_outlined),
//             label: 'Reports',
//           ),
//           NavigationDestination(
//             icon: Icon(Icons.settings_outlined),
//             label: 'Settings',
//           ),
//         ],
//       ),
//     );
//   }
// }

// class SummaryCard extends StatelessWidget {
//   final String title;
//   final String amount;
//   final IconData icon;
//   final Color color;

//   const SummaryCard({
//     super.key,
//     required this.title,
//     required this.amount,
//     required this.icon,
//     required this.color,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 0,
//       color: Colors.white,
//       child: Padding(
//         padding: const EdgeInsets.all(18),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Icon(icon, color: color, size: 28),
//             const SizedBox(height: 14),
//             Text(
//               title,
//               style: const TextStyle(color: Colors.black54),
//             ),
//             const SizedBox(height: 6),
//             FittedBox(
//               fit: BoxFit.scaleDown,
//               alignment: Alignment.centerLeft,
//               child: Text(
//                 amount,
//                 style: const TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class TransactionTile extends StatelessWidget {
//   final String title;
//   final String category;
//   final double amount;
//   final IconData icon;
//   final Color color;
//   final String Function(double) formatMoney;

//   const TransactionTile({
//     super.key,
//     required this.title,
//     required this.category,
//     required this.amount,
//     required this.icon,
//     required this.color,
//     required this.formatMoney,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final isIncome = amount >= 0;

//     return Card(
//       elevation: 0,
//       color: Colors.white,
//       margin: const EdgeInsets.only(bottom: 10),
//       child: ListTile(
//         contentPadding: const EdgeInsets.symmetric(
//           horizontal: 16,
//           vertical: 4,
//         ),
//         leading: CircleAvatar(
//           backgroundColor: color.withValues(alpha: 0.12),
//           child: Icon(icon, color: color),
//         ),
//         title: Text(
//           title,
//           style: const TextStyle(fontWeight: FontWeight.w600),
//         ),
//         subtitle: Text(category),
//         trailing: Text(
//           '${isIncome ? '+' : '-'}${formatMoney(amount.abs())}',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             color: isIncome ? Colors.green : Colors.redAccent,
//           ),
//         ),
//       ),
//     );
//   }
// }