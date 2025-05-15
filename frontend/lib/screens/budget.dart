// lib/screens/// lib/screens/budget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import 'dashboard.dart';
import 'settings.dart';

class BudgetItem {
  final String label;
  final double cost;
  final String type;
  BudgetItem(this.label, this.cost, this.type);
}

class BudgetScreen extends StatefulWidget {
  final String email;
  const BudgetScreen({Key? key, this.email = ''}) : super(key: key);

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  // Controllers
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _costController = TextEditingController();

  // In‐memory list of items
  List<BudgetItem> _items = [];

  // —— Category types
  final List<String> _types = [
    'bills',
    'shopping',
    'food_drink',
    'entertainment',
    'travel',
    'personal',
  ];
  String _selectedType = 'bills';

  // Month‐picker data
  final List<String> _monthNames = const [
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
    'December'
  ];
  int _selectedMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _loadForMonth();
  }

  Future<void> _loadForMonth() async {
    final prefs = await SharedPreferences.getInstance();

    // restore saved month
    _selectedMonth =
        prefs.getInt('selectedMonth_${widget.email}') ?? _selectedMonth;

    // load budget
    final budgetKey =
        'monthlyBudget_${widget.email}_$_selectedMonth';
    final savedBudget = prefs.getDouble(budgetKey) ?? 0.0;
    _budgetController.text =
        savedBudget > 0 ? savedBudget.toStringAsFixed(2) : '';

    // load items
    final itemsKey = 'items_${widget.email}_$_selectedMonth';
    final list = prefs.getStringList(itemsKey) ?? [];
    _items = list.map((e) {
      final parts = e.split('|');
      return BudgetItem(
        parts[0],
        double.tryParse(parts[1]) ?? 0.0,
        parts.length > 2 ? parts[2] : _types.first,
      );
    }).toList();

    setState(() {});
  }

  Future<void> _saveBudget() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'monthlyBudget_${widget.email}_$_selectedMonth';
    final value = double.tryParse(_budgetController.text) ?? 0.0;
    await prefs.setDouble(key, value);
  }

  Future<void> _saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'items_${widget.email}_$_selectedMonth';
    final list = _items
        .map((i) => '${i.label}|${i.cost}|${i.type}')
        .toList();
    await prefs.setStringList(key, list);
  }

  double get _budget =>
      double.tryParse(_budgetController.text.trim()) ?? 0.0;

  double get _totalCost =>
      _items.fold(0.0, (sum, item) => sum + item.cost);

  void _addItem() {
    final label = _itemController.text.trim();
    final cost = double.tryParse(_costController.text) ?? -1;
    if (label.isEmpty || cost <= 0) return;

    // enforce not going over budget
    if (_totalCost + cost > _budget) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Adding this would exceed your budget!')),
      );
      return;
    }

    setState(() {
      _items.insert(
          0, BudgetItem(label, cost, _selectedType));
      _itemController.clear();
      _costController.clear();
    });
    _saveItems();
  }

  void _deleteItem(int idx) {
    setState(() => _items.removeAt(idx));
    _saveItems();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // header
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              color: const Color(0xFF673AB7),
              child: const Text(
                'Budgeting',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
            ),

            // month selector
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const Text('Month:', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButton<int>(
                      value: _selectedMonth,
                      isExpanded: true,
                      items:
                          List.generate(12, (i) => i + 1).map((m) {
                        return DropdownMenuItem(
                          value: m,
                          child: Text(_monthNames[m - 1],
                              style: theme.textTheme.bodyMedium),
                        );
                      }).toList(),
                      onChanged: (m) async {
                        if (m == null) return;
                        final prefs =
                            await SharedPreferences.getInstance();
                        await prefs.setInt(
                            'selectedMonth_${widget.email}', m);
                        setState(() => _selectedMonth = m);
                        await _loadForMonth();
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // content area
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
                      // budget input
                      _buildSectionTitle(
                          Icons.account_balance_wallet,
                          'Monthly Budget'),
                      _buildTextField(
                          _budgetController,
                          'Enter amount',
                          TextInputType.number,
                          onSubmitted: (_) => _saveBudget()),
                      const SizedBox(height: 30),

                      // category picker + add row
                      _buildSectionTitle(
                          Icons.category, 'Item Type'),
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(40, 0, 20, 8),
                        child: DropdownButton<String>(
                          value: _selectedType,
                          isExpanded: true,
                          items: _types
                              .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t,
                                      style: theme
                                          .textTheme.bodyMedium)))
                              .toList(),
                          onChanged: (nt) {
                            if (nt != null) setState(() => _selectedType = nt);
                          },
                        ),
                      ),

                      _buildSectionTitle(Icons.list, 'Add Item'),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 40, right: 20, top: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _itemController,
                                decoration: const InputDecoration(
                                    hintText: 'Label',
                                    border: OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _costController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                    hintText: 'Cost',
                                    border: OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _addItem,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF673AB7),
                                foregroundColor: Colors.black,
                              ),
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // items list
                      _buildSectionTitle(
                          Icons.receipt_long,
                          'Items (${_totalCost.toStringAsFixed(2)} / \$${_budget.toStringAsFixed(2)})'),
                      const SizedBox(height: 12),
                      ..._items.asMap().entries.map((e) {
                        final item = e.value;
                        return ListTile(
                          leading: Text(item.type,
                              style: theme.textTheme.bodyMedium),
                          title: Text(
                              '${item.label} — \$${item.cost.toStringAsFixed(2)}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteItem(e.key),
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

      // bottom nav bar
      bottomNavigationBar: Container(
        height: 60,
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.grey[900]
              : const Color(0xFFF8F8F8),
          border: Border(
              top:
                  BorderSide(color: Colors.grey.withValues(alpha: 77, red: 158, green: 158, blue: 158), width: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(Icons.home,
                  size: 26, color: theme.iconTheme.color),
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/Dashboard'),
            ),
            IconButton(
              icon: Icon(Icons.add,
                  size: 26, color: theme.iconTheme.color),
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/budget'),
            ),
            IconButton(
              icon: Icon(Icons.settings,
                  size: 26, color: theme.iconTheme.color),
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 20, 20, 8),
      child: Row(
        children: [
          Icon(icon,
              size: 28, color: Theme.of(context).iconTheme.color),
          const SizedBox(width: 12),
          Text(text,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.color)),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String hint,
    TextInputType type, {
    Function(String)? onSubmitted,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 0, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: TextField(
          controller: ctrl,
          keyboardType: type,
          onSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }
}
