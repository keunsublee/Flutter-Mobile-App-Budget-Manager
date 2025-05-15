// lib/screens/budget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';     
import 'settings.dart';
import 'dashboard.dart';

class BudgetScreen extends StatefulWidget {
  final String email;
  const BudgetScreen({super.key, this.email = ''});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class BudgetItem {
  final String label;
  final double percentage;
  BudgetItem(this.label, this.percentage);
}

class _BudgetScreenState extends State<BudgetScreen> {
  // Controllers
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _percentController = TextEditingController();
  List<BudgetItem> _items = [];

  // Category types
  final List<String> _types = [
    'bills', 'shopping', 'food_drink',
    'entertainment', 'travel', 'personal',
  ];
  String _selectedType = 'bills';

  // Month picker
  final List<String> _monthNames = const [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  int _selectedMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _loadForMonth();
  }

  // load budget and items for selected month
  Future<void> _loadForMonth() async {
    final prefs = await SharedPreferences.getInstance();
    final budgetKey = 'monthlyBudget_${widget.email}_$_selectedMonth';
    final savedBudget = prefs.getDouble(budgetKey) ?? 0.0;
    _budgetController.text = savedBudget > 0
        ? savedBudget.toStringAsFixed(2)
        : '';

    final itemsKey = 'items_${widget.email}_$_selectedMonth';
    final list = prefs.getStringList(itemsKey) ?? [];
    setState(() {
      _items = list.map((e) {
        final parts = e.split('|');
        return BudgetItem(parts[0], double.tryParse(parts[1]) ?? 0.0);
      }).toList();
    });
  }

  // save budget and items for selected month
  Future<void> _saveBudget() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'monthlyBudget_${widget.email}_$_selectedMonth';
    final value = double.tryParse(_budgetController.text) ?? 0.0;
    await prefs.setDouble(key, value);
  }

  Future<void> _saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'items_${widget.email}_$_selectedMonth';
    final list = _items.map((i) => '${i.label}|${i.percentage}').toList();
    await prefs.setStringList(key, list);
  }

  void _addItem() {
    final label = _itemController.text.trim();
    final pct = double.tryParse(_percentController.text) ?? 0.0;
    if (label.isEmpty || pct <= 0) return;
    final total = _items.fold(0.0, (sum, item) => sum + item.percentage);
    if (total + pct > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Total percentage cannot exceed 100%.')),
      );
      return;
    }
    setState(() {
      _items.insert(0, BudgetItem(label, pct));
      _itemController.clear();
      _percentController.clear();
    });
    _saveItems();
  }

  void _deleteItem(int index) {
    setState(() => _items.removeAt(index));
    _saveItems();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              color: const Color(0xFF673AB7),
              child: const Text(
                'Budgeting',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            // Month selector
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
                      items: List.generate(12, (i) => i + 1)
                          .map((m) => DropdownMenuItem(
                                value: m,
                                child: Text(_monthNames[m - 1], style: theme.textTheme.bodyMedium),
                              ))
                          .toList(),
                      onChanged: (m) {
                        if (m != null) {
                          setState(() => _selectedMonth = m);
                          _loadForMonth();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
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
                      _buildSectionTitle(Icons.account_balance_wallet, 'Monthly Budget'),
                      _buildTextField(_budgetController, 'Enter amount', TextInputType.number, onSubmitted: (_) => _saveBudget()),
                      const SizedBox(height: 30),
                      _buildSectionTitle(Icons.category, 'Category'),
                      _buildDropdown(theme),
                      const SizedBox(height: 40),
                      _buildAddRow(theme),
                      const SizedBox(height: 40),
                      _buildSectionTitle(Icons.list, 'Items'),
                      const SizedBox(height: 25),
                      ..._items.asMap().entries.map((e) => _buildItemRow(e.key, e.value, theme)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(isDarkMode, context),
    );
  }

  Widget _buildSectionTitle(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 28, color: Theme.of(context).iconTheme.color),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
        ],
      );

  Widget _buildTextField(TextEditingController ctrl, String hint, TextInputType type, {Function(String)? onSubmitted}) => Padding(
        padding: const EdgeInsets.only(left: 40, right: 20, top: 12),
        child: Container(
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(8)),
          child: TextField(
            controller: ctrl,
            keyboardType: type,
            onSubmitted: onSubmitted,
            decoration: InputDecoration(hintText: hint, border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
          ),
        ),
      );

  Widget _buildDropdown(ThemeData theme) => Padding(
        padding: const EdgeInsets.only(left: 40, right: 20),
        child: DropdownButton<String>(
          value: _selectedType,
          isExpanded: true,
          underline: Container(height: 1, color: Colors.grey.withOpacity(0.5)),
          items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t, style: theme.textTheme.bodyMedium))).toList(),
          onChanged: (nt) {
            if (nt != null) setState(() => _selectedType = nt);
          },
        ),
      );

  Widget _buildAddRow(ThemeData theme) => Padding(
        padding: const EdgeInsets.only(left: 40, right: 20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(controller: _itemController, decoration: const InputDecoration(border: InputBorder.none, hintText: 'Item label', contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8))),
                  const SizedBox(height: 8),
                  TextField(controller: _percentController, keyboardType: TextInputType.number, decoration: const InputDecoration(border: InputBorder.none, hintText: '% of budget', contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8))),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(onPressed: _addItem, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF673AB7), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Add'))
          ],
        ),
      );

  Widget _buildItemRow(int idx, BudgetItem item, ThemeData theme) {
    final budget = double.tryParse(_budgetController.text) ?? 0.0;
    final amount = budget * item.percentage / 100;
    return Padding(
      padding: const EdgeInsets.only(left: 40, right: 20, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text('${item.label} – ${item.percentage.toStringAsFixed(1)}% (\$${amount.toStringAsFixed(2)})', style: theme.textTheme.bodyMedium)),
          IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteItem(idx)),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isDarkMode, BuildContext context) => Container(
    height: 60,
    decoration: BoxDecoration(color: isDarkMode ? Colors.grey[900] : const Color(0xFFF8F8F8), border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 77, red: 158, green: 158, blue: 158), width: 0.5))),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      IconButton(icon: Icon(Icons.home, size: 26, color: Theme.of(context).iconTheme.color), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DashboardScreen()))),
      IconButton(icon: Icon(Icons.add, size: 26, color: Theme.of(context).iconTheme.color), onPressed: () {}),
      IconButton(icon: Icon(Icons.settings, size: 26, color: Theme.of(context).iconTheme.color), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
    ]),
  );
}