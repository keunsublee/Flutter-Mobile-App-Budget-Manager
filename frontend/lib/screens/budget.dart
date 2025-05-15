// lib/screens/budget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';      // for ThemeProvider
import 'settings.dart';

class BudgetScreen extends StatefulWidget {
  final String email;
  const BudgetScreen({super.key, this.email = ''});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  // —— Controllers and in-memory lists
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _itemController = TextEditingController();
  List<String> _items = [];

  // —— Category types
  final List<String> _types = [
    'bills', 'shopping', 'food_drink',
    'entertainment', 'travel', 'personal',
  ];
  String _selectedType = 'bills';

  @override
  void initState() {
    super.initState();
    _loadBudget();
    _loadItems();
  }

  Future<void> _loadBudget() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'monthlyBudget_${widget.email}';
    final saved = prefs.getDouble(key) ?? 0.0;
    if (saved > 0) {
      _budgetController.text = saved.toStringAsFixed(2);
    }
  }

  Future<void> _saveBudget() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'monthlyBudget_${widget.email}';
    final value = double.tryParse(_budgetController.text) ?? 0.0;
    await prefs.setDouble(key, value);
  }

  Future<void> _loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'items_${widget.email}';
    final list = prefs.getStringList(key) ?? [];
    setState(() {
      _items = list;
    });
  }

  Future<void> _saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'items_${widget.email}';
    await prefs.setStringList(key, _items);
  }

  void _addItem() {
    final text = _itemController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _items.insert(0, text);
      _itemController.clear();
    });
    _saveItems();
  }

  void _deleteItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
    _saveItems();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      body: Column(
        children: [
          // Purple header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 20, left: 20),
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

          // Main content with rounded top corners
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
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
                    // Monthly Budget Section
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          size: 28,
                          color: Theme.of(context).iconTheme.color,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Monthly Budget',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(left: 40.0, right: 20.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _budgetController,
                          keyboardType: TextInputType.number,
                          onSubmitted: (_) => _saveBudget(),
                          decoration: const InputDecoration(
                            hintText: 'Enter amount',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Category Section
                    Row(
                      children: [
                        Icon(
                          Icons.category,
                          size: 28,
                          color: Theme.of(context).iconTheme.color,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Category',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // Dropdown for type selection
                    Padding(
                      padding: const EdgeInsets.only(left: 40.0, right: 20.0),
                      child: DropdownButton<String>(
                        value: _selectedType,
                        isExpanded: true,
                        underline: Container(
                          height: 1,
                          color: Colors.grey.withOpacity(0.5),
                        ),
                        items: _types
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(
                                    t,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge,
                                  ),
                                ))
                            .toList(),
                        onChanged: (newT) {
                          if (newT != null) {
                            setState(() => _selectedType = newT);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Input + Add button
                    Padding(
                      padding: const EdgeInsets.only(left: 40.0, right: 20.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: TextField(
                                controller: _itemController,
                                decoration: InputDecoration(
                                  labelText: 'Add item',
                                  labelStyle: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _addItem,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF673AB7),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Items Section
                    Row(
                      children: [
                        Icon(
                          Icons.list,
                          size: 28,
                          color: Theme.of(context).iconTheme.color,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Items',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // Items list with delete
                    Padding(
                      padding: const EdgeInsets.only(left: 40.0, right: 20.0),
                      child: Column(
                        children: _items.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final item = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteItem(idx),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // Bottom navigation bar
      bottomNavigationBar: Container(
        height: 60,
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.grey[900]
              : const Color(0xFFF8F8F8),
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
              icon: Icon(
                Icons.home,
                size: 26,
                color: Theme.of(context).iconTheme.color,
              ),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(
                Icons.add,
                size: 26,
                color: Theme.of(context).iconTheme.color,
              ),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(
                Icons.settings,
                size: 26,
                color: Theme.of(context).iconTheme.color,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
