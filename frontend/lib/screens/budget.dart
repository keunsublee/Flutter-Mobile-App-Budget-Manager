// lib/screens/budget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  const BudgetScreen({Key? key}) : super(key: key);
  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _budgetController = TextEditingController();
  final _itemController   = TextEditingController();
  final _costController   = TextEditingController();
  List<BudgetItem> _items = [];

  final _types = ['bills','shopping','food_drink','entertainment','travel','personal'];
  String _selectedType = 'bills';

  final _monthNames = const [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December'
  ];
  int _selectedMonth = DateTime.now().month;

  String get _userId => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState(){
    super.initState();
    _loadForMonth();
  }

  Future<void> _loadForMonth() async {
    final prefs = await SharedPreferences.getInstance();

    _selectedMonth = prefs.getInt('selectedMonth_$_userId') ?? _selectedMonth;

    final budgetKey = 'monthlyBudget_${_userId}_$_selectedMonth';
    final savedBudget = prefs.getDouble(budgetKey) ?? 0.0;
    _budgetController.text = savedBudget>0 ? savedBudget.toStringAsFixed(2) : '';

    final itemsKey = 'items_${_userId}_$_selectedMonth';
    final list = prefs.getStringList(itemsKey) ?? [];
    _items = list.map((e){
      final p = e.split('|');
      return BudgetItem(p[0],double.tryParse(p[1])??0.0, p[2]);
    }).toList();

    setState((){});
  }

  Future<void> _saveBudget() async {
    final prefs = await SharedPreferences.getInstance();
    final budgetKey = 'monthlyBudget_${_userId}_$_selectedMonth';
    final value = double.tryParse(_budgetController.text) ?? 0.0;
    await prefs.setDouble(budgetKey,value);
  }

  Future<void> _saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    final itemsKey = 'items_${_userId}_$_selectedMonth';
    final encoded = _items.map((i)=> '${i.label}|${i.cost}|${i.type}').toList();
    await prefs.setStringList(itemsKey,encoded);
  }

  double get _budget => double.tryParse(_budgetController.text) ?? 0.0;
  double get _totalCost => _items.fold(0.0,(sum,i)=>sum+i.cost);

  void _addItem(){
    final label = _itemController.text.trim();
    final cost  = double.tryParse(_costController.text) ?? -1;
    if(label.isEmpty||cost<=0) return;
    if(_totalCost+cost>_budget){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adding this would exceed your budget!'))
      );
      return;
    }
    setState((){
      _items.insert(0,BudgetItem(label,cost,_selectedType));
      _itemController.clear();
      _costController.clear();
    });
    _saveItems();
  }

  void _deleteItem(int i){
    setState(()=>_items.removeAt(i));
    _saveItems();
  }

  @override
  Widget build(BuildContext context){
    final theme = Theme.of(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      body: SafeArea(child: Column(
        children:[
          // HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical:20,horizontal:20),
            color: const Color(0xFF673AB7),
            child: const Text('Budgeting',
              style: TextStyle(fontSize:28,fontWeight:FontWeight.bold,color:Colors.black)
            ),
          ),

          // MONTH PICKER
          Padding(
            padding: const EdgeInsets.fromLTRB(20,16,20,0),
            child: Row(children:[
              const Text('Month:',style: TextStyle(fontSize:16)),
              const SizedBox(width:12),
              Expanded(child: DropdownButton<int>(
                value:_selectedMonth,
                isExpanded:true,
                items: List.generate(12,(i)=>i+1).map((m)=>DropdownMenuItem(
                  value:m,
                  child:Text(_monthNames[m-1],style:theme.textTheme.bodyMedium),
                )).toList(),
                onChanged:(m) async {
                  if(m==null) return;
                  final prefs=await SharedPreferences.getInstance();
                  await prefs.setInt('selectedMonth_$_userId',m);
                  setState(()=>_selectedMonth=m);
                  await _loadForMonth();
                },
              )),
            ]),
          ),
          const SizedBox(height:20),

          // CONTENT
          Expanded(child: Container(
            width:double.infinity,
            decoration:BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft:Radius.circular(30),
                topRight:Radius.circular(30),
              ),
            ),
            child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20,30,20,20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,children:[
                // budget
                _buildSection(Icons.account_balance_wallet,'Monthly Budget'),
                _buildText(_budgetController, 'Enter amount', onSubmitted: (_) => _saveBudget()),

                const SizedBox(height:30),

                // type selector
                _buildSection(Icons.category,'Item Type'),
                Padding(padding: const EdgeInsets.fromLTRB(40,0,20,8),
                  child: DropdownButton<String>(
                    value:_selectedType,
                    isExpanded:true,
                    items:_types.map((t)=>DropdownMenuItem(
                      value:t,child:Text(t,style:theme.textTheme.bodyMedium)
                    )).toList(),
                    onChanged:(t)=>setState(()=>_selectedType=t!),
                  ),
                ),

                // add item
                _buildSection(Icons.list,'Add Item'),
                Padding(padding: const EdgeInsets.only(left:40,right:20,top:12),
                  child: Row(children:[
                    Expanded(child:TextField(controller:_itemController,decoration: const InputDecoration(hintText:'Label',border:OutlineInputBorder()))),
                    const SizedBox(width:8),
                    Expanded(child:TextField(controller:_costController,keyboardType:TextInputType.number,decoration: const InputDecoration(hintText:'Cost',border:OutlineInputBorder()))),
                    const SizedBox(width:8),
                    ElevatedButton(onPressed:_addItem,style:ElevatedButton.styleFrom(backgroundColor:const Color(0xFF673AB7),foregroundColor:Colors.black),child: const Text('Add')),
                  ]),
                ),
                const SizedBox(height:40),

                // items list
                _buildSection(Icons.receipt_long,'Items (${_totalCost.toStringAsFixed(2)} / \$${_budget.toStringAsFixed(2)})'),
                const SizedBox(height:12),
                for(int i=0;i<_items.length;i++)
                  ListTile(
                    leading:Text(_items[i].type,style:theme.textTheme.bodyMedium),
                    title:Text('${_items[i].label} — \$${_items[i].cost.toStringAsFixed(2)}'),
                    trailing:IconButton(icon: const Icon(Icons.delete),onPressed:()=>_deleteItem(i)),
                  ),
              ]),
            ),
          )),

        ],
      )),
      bottomNavigationBar: SafeArea(
        child: Container(
          height:60,
          decoration:BoxDecoration(
            color:isDark?Colors.grey[900]:const Color(0xFFF8F8F8),
            border:Border(
              top:BorderSide(
                color: Color.fromARGB(77, 158, 158, 158),
                width:0.5
              )
            )
          ),
          child: Row(mainAxisAlignment:MainAxisAlignment.spaceEvenly,children:[
            IconButton(icon:Icon(Icons.home,size:26,color:theme.iconTheme.color),
              onPressed:()=>Navigator.pushReplacementNamed(context,'/Dashboard'),
            ),
            IconButton(icon:Icon(Icons.add,size:26,color:theme.iconTheme.color),
              onPressed:()=>Navigator.pushReplacementNamed(context,'/budget'),
            ),
            IconButton(icon:Icon(Icons.settings,size:26,color:theme.iconTheme.color),
              onPressed:()=>Navigator.pushReplacementNamed(context,'/settings'),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildSection(IconData icon,String text)=>Padding(
    padding: const EdgeInsets.fromLTRB(40,20,20,8),
    child: Row(children:[
      Icon(icon,size:28,color:Theme.of(context).iconTheme.color),
      const SizedBox(width:12),
      Text(text,style: TextStyle(fontSize:20,fontWeight:FontWeight.bold,color:Theme.of(context).textTheme.bodyLarge?.color)),
    ]),
  );

  Widget _buildText(TextEditingController c,String hint,{Function(String)?onSubmitted})=>Padding(
    padding: const EdgeInsets.fromLTRB(40,0,20,0),
    child:Container(
      decoration:BoxDecoration(color:Theme.of(context).cardColor,borderRadius:BorderRadius.circular(8)),
      child:TextField(controller:c,onSubmitted:onSubmitted,decoration:InputDecoration(hintText:hint,border:InputBorder.none,contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:12))),
    ),
  );
}
