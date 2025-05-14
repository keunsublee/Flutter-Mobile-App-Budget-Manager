import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';  // for ThemeProvider
import 'settings.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});
  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  // —— In‐memory items and controller
  final List<String> _items = [];
  final TextEditingController _controller = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

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
                    // Category Section
                    Row(
                      children: [
                        Icon(Icons.category,
                            size: 28,
                            color: Theme.of(context).iconTheme.color),
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
                      padding:
                          const EdgeInsets.only(left: 40.0, right: 20.0),
                      child: DropdownButton<String>(
                        value: _selectedType,
                        isExpanded: true,
                        underline: Container(
                            height: 1,
                            color: Colors.grey.withOpacity(0.5)),
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
                                controller: _controller,
                                decoration: InputDecoration(
                                  labelText: 'Add item',
                                  labelStyle: TextStyle(
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              final text = _controller.text.trim();
                              if (text.isEmpty) return;
                              setState(() {
                                _items.insert(0, text);
                                _controller.clear();
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF673AB7), // deep purple
                              foregroundColor: Colors.black,            // black text like Settings
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
                        Icon(Icons.list,
                            size: 28,
                            color: Theme.of(context).iconTheme.color),
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
                      padding: const EdgeInsets.only(
                          left: 40.0, right: 20.0),
                      child: Column(
                        children: _items.map((item) {
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(item,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    setState(
                                        () => _items.remove(item));
                                  },
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
          color: isDarkMode ? Colors.grey[900] : const Color(0xFFF8F8F8),
          border: Border(
            top: BorderSide(color: Colors.grey.withValues(alpha: 77, red: 158, green: 158, blue: 158)
              , width: 0.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(Icons.home,
                  size: 26, color: Theme.of(context).iconTheme.color),
              onPressed: () {}, // leave as-is or wire up later
            ),
            IconButton(
              icon: Icon(Icons.add,
                  size: 26, color: Theme.of(context).iconTheme.color),
              onPressed: () {}, // leave as-is or wire up later
            ),
            IconButton(
              icon: Icon(Icons.settings,
                  size: 26, color: Theme.of(context).iconTheme.color),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
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
