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
  final double percentage;
  BudgetItem(this.label, this.percentage);
}

class _DashboardScreenState extends State<DashboardScreen> {
  double _budget = 0.0;
  List<BudgetItem> _items = [];
  int _month = DateTime.now().month;

  // Default palette for pie slices
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
    final monthKey = 'selectedMonth_${widget.email}';
    _month = prefs.getInt(monthKey) ?? DateTime.now().month;

    final budgetKey = 'monthlyBudget_${widget.email}_\$_month';
    final itemsKey = 'items_${widget.email}_\$_month';

    _budget = prefs.getDouble(budgetKey) ?? 0.0;
    final savedList = prefs.getStringList(itemsKey) ?? [];
    _items = savedList.map((e) {
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

    final userName = (widget.email.contains('@'))
        ? widget.email.split('@')[0]
        : 'Please Sign In';

    final totalPct = _items.fold<double>(0, (sum, i) => sum + i.percentage);
    final totalSpent = _budget * totalPct / 100;
    final remaining = _budget - totalSpent;

    final dataMap = <String,double>{};
    for (var item in _items) {
      dataMap[item.label] = (dataMap[item.label] ?? 0) + item.percentage;
    }
    final colorList = List<Color>.generate(
      dataMap.length,
      (i) => _sliceColors[i % _sliceColors.length],
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              color: const Color(0xFF673AB7),
              child: const Text(
                'Dashboard',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
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
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
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

                      if (dataMap.isNotEmpty)
                        PieChart(
                          dataMap: dataMap,
                          colorList: colorList,
                          chartType: ChartType.disc,
                          chartValuesOptions: const ChartValuesOptions(showChartValues: true),
                          legendOptions: const LegendOptions(showLegends: false),
                        )
                      else
                        const Center(child: Text('No data to display')),
                      const SizedBox(height: 20),

                      ..._items.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final item = entry.value;
                        final amt = _budget * item.percentage / 100;
                        final sliceColor = colorList[idx];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(width: 16, height: 16, color: sliceColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${item.label}: ${item.percentage.toStringAsFixed(1)}% (\$${amt.toStringAsFixed(2)})',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 60,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : const Color(0xFFF8F8F8),
          border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 77, red: 158, green: 158, blue: 158), width: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(icon: Icon(Icons.home, size: 26, color: theme.iconTheme.color), onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard')),
            IconButton(icon: Icon(Icons.add, size: 26, color: theme.iconTheme.color), onPressed: () => Navigator.pushReplacementNamed(context, '/budget')),
            IconButton(icon: Icon(Icons.settings, size: 26, color: theme.iconTheme.color), onPressed: () => Navigator.pushReplacementNamed(context, '/settings')),
          ],
        ),
      ),
    );
  }
}
