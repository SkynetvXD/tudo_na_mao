import 'package:flutter/material.dart';
import '../models/check_item.dart';

class CheckListWidget extends StatelessWidget {
  final List<CheckItem> items;
  final Function(int) onToggle;
  final Function(int) onRemove;

  const CheckListWidget({
    super.key,
    required this.items,
    required this.onToggle,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.checklist_rounded,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum item na lista',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toque em "Adicionar" para começar',
              style: TextStyle(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Checkbox(
              value: item.isChecked,
              onChanged: (_) => onToggle(index),
              activeColor: Colors.green,
            ),
            title: Text(
              item.name,
              style: TextStyle(
                fontSize: 18,
                decoration: item.isChecked 
                    ? TextDecoration.lineThrough 
                    : null,
                color: item.isChecked 
                    ? Colors.grey.shade600 
                    : null,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Remover Item'),
                    content: Text('Deseja remover "${item.name}" da lista?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          onRemove(index);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Remover'),
                      ),
                    ],
                  ),
                );
              },
            ),
            onTap: () => onToggle(index),
          ),
        );
      },
    );
  }
}