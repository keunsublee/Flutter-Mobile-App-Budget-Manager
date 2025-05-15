// lib/screens/dashboard.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';     
import 'settings.dart';

class DashboardScreen extends StatefulWidget {
  final String email;
  const DashboardScreen({Key? key, this.email = ''}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class BudgetItem {
  final String label;
  final double cost;
  BudgetItem(this.label, this.cost);
}

class _DashboardScreenState extends State<DashboardScreen> {
  double _budget = 0.0;
  List<BudgetItem> _items = [];
  int _month = DateTime.now().month;

  final List<Color> _sliceColors = [
    Colors.tealAccent,
    Colors.lightBlueAccent,
    Colors.redAccent,
    Colors.purpleAccent,
    Colors.orangeAccent,
    Colors.greenAccent,
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // read selected month
    _month = prefs.getInt('selectedMonth_${widget.email}') ?? DateTime.now().month;

    // load budget for that month
    final budgetKey = 'monthlyBudget_${widget.email}_$_month';
    _budget = prefs.getDouble(budgetKey) ?? 0.0;

    // load items
    final itemsKey = 'items_${widget.email}_$_month';
    final saved = prefs.getStringList(itemsKey) ?? [];
    _items = saved.map((e) {
      final parts = e.split('|');
      return BudgetItem(parts[0], double.tryParse(parts[1]) ?? 0.0);
    }).toList();

    setState(() {});
  }

  String get _monthName {
    const names = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    return names[_month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final theme = Theme.of(context);

    final userName = widget.email.contains('@')
        ? widget.email.split('@')[0]
        : 'Please Sign In';

    // compute total spent
    final totalSpent = _items.fold<double>(0.0, (sum, i) => sum + i.cost);
    final remaining = _budget - totalSpent;

    // build map of label → cost
    final dataMap = <String,double>{};
    for (var item in _items) {
      dataMap[item.label] = (dataMap[item.label] ?? 0) + item.cost;
    }

    final colorList = List<Color>.generate(
      dataMap.length,
      (i) => _sliceColors[i % _sliceColors.length],
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              color: const Color(0xFF673AB7),
              child: const Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),

            // body
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20,30,20,20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hello, $userName!', style: theme.textTheme.titleLarge),
                      Text(TimeOfDay.now().format(context), style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('Month: $_monthName', style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 20),

                      Text('Monthly Budget: \$${_budget.toStringAsFixed(2)}', style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 8),
                      Text('Spent: \$${totalSpent.toStringAsFixed(2)}', style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 4),
                      Text('Remaining: \$${remaining.toStringAsFixed(2)}', style: theme.textTheme.bodyMedium),
                      const Divider(height: 30),

                      // pie chart sized by cost values
                      if (dataMap.isNotEmpty)
                        PieChart(
                          dataMap: dataMap,
                          colorList: colorList,
                          chartType: ChartType.disc,
                          // show the actual percent of each slice
                          chartValuesOptions: const ChartValuesOptions(
                            showChartValuesInPercentage: true,
                            showChartValuesOutside: false,
                          ),
                          legendOptions: const LegendOptions(showLegends: false),
                        )
                      else
                        const Center(child: Text('No data to display')),
                      const SizedBox(height: 20),

                      // legend
                      ..._items.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final item = entry.value;
                        final pct = totalSpent > 0
                            ? item.cost / totalSpent * 100
                            : 0.0;
                        final sliceColor = colorList[idx];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(width: 16, height: 16, color: sliceColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${item.label}: \$${item.cost.toStringAsFixed(2)} '
                                  '(${pct.toStringAsFixed(1)}%)',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // bottom nav
      bottomNavigationBar: Container(
        height: 60,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : const Color(0xFFF8F8F8),
          border: Border(
            top: BorderSide(
              color: Colors.grey.withValues(alpha: 77, red: 158, green: 158, blue: 158),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(Icons.home, size: 26, color: theme.iconTheme.color),
              onPressed: () => Navigator.pushReplacementNamed(context, '/Dashboard'),
            ),
            IconButton(
              icon: Icon(Icons.add, size: 26, color: theme.iconTheme.color),
              onPressed: () => Navigator.pushReplacementNamed(context, '/budget'),
            ),
            IconButton(
              icon: Icon(Icons.settings, size: 26, color: theme.iconTheme.color),
              onPressed: () => Navigator.pushReplacementNamed(context, '/settings'),
            ),
          ],
        ),
      ),
    );
  }
}
