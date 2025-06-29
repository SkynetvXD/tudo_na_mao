import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/check_item.dart';
import '../widgets/check_list_widget.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<CheckItem> _items = [];
  String _departureTime = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Carregar e formatar horário corretamente
    final timeString = prefs.getString('departure_time') ?? '7:0';
    final timeParts = timeString.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    _departureTime = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    
    // Carregar itens ou criar lista padrão
    final itemsJson = prefs.getStringList('check_items');
    if (itemsJson != null && itemsJson.isNotEmpty) {
      _items = itemsJson.map((json) => CheckItem.fromJson(json)).toList();
    } else {
      _items = [
        CheckItem(name: 'Chave'),
        CheckItem(name: 'Carteira'),
        CheckItem(name: 'Celular'),
        CheckItem(name: 'Óculos'),
        CheckItem(name: 'Marmita'),
      ];
      await _saveItems();
    }
    
    setState(() {});
  }

  Future<void> _saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = _items.map((item) => item.toJson()).toList();
    await prefs.setStringList('check_items', itemsJson);
  }

  void _toggleItem(int index) {
    setState(() {
      _items[index].isChecked = !_items[index].isChecked;
    });
    _saveItems();
  }

  void _addItem(String name) {
    setState(() {
      _items.add(CheckItem(name: name));
    });
    _saveItems();
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
    _saveItems();
  }

  void _resetChecklist() {
    setState(() {
      for (var item in _items) {
        item.isChecked = false;
      }
    });
    _saveItems();
  }

  void _showAddItemDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Item'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Nome do item',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _addItem(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final checkedCount = _items.where((item) => item.isChecked).length;
    final totalCount = _items.length;
    final allChecked = checkedCount == totalCount && totalCount > 0;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Tudo na Mão'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              ).then((_) => _loadData());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header com progresso
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text(
                    'Saída programada: $_departureTime',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  CircularProgressIndicator(
                    value: totalCount > 0 ? checkedCount / totalCount : 0,
                    backgroundColor: Colors.white30,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 8,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$checkedCount de $totalCount itens',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  if (allChecked) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '✅ Tudo pronto!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Lista de itens
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CheckListWidget(
                items: _items,
                onToggle: _toggleItem,
                onRemove: _removeItem,
              ),
            ),
          ),
          
          // Botões de ação
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showAddItemDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _resetChecklist,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Resetar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Botão "Saída Agora"
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (allChecked) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Você está pronto para sair!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('⚠️ Faltam ${totalCount - checkedCount} itens!'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: allChecked ? Colors.green : Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  allChecked ? '✅ PRONTO PARA SAIR!' : '⚠️ CONFERIR LISTA',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}