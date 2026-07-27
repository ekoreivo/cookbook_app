import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cookbook_app/models/recipe.dart';
import 'package:cookbook_app/providers/app_state.dart';

class ShoppingListScreen extends ConsumerWidget {
  const ShoppingListScreen({super.key});

  void _showAddItemDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final unitController = TextEditingController(text: 'item');
    Category selectedCategory = Category.other;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Custom Item'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Item Name',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        final matchedCategory =
                            ref.read(ingredientMemoryProvider.notifier).lookupCategory(val);
                        if (matchedCategory != null) {
                          setDialogState(() {
                            selectedCategory = matchedCategory;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: quantityController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Qty',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: unitController,
                            decoration: const InputDecoration(
                              labelText: 'Unit',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Category>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: Category.values.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat.displayName),
                        );
                      }).toList(),
                      onChanged: (newCat) {
                        if (newCat != null) {
                          setDialogState(() {
                            selectedCategory = newCat;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final qty = double.tryParse(quantityController.text.trim()) ?? 1.0;
                    final unit = unitController.text.trim();

                    if (name.isNotEmpty) {
                      ref.read(shoppingListProvider.notifier).addItem(
                            name,
                            qty,
                            unit.isEmpty ? 'item' : unit,
                            selectedCategory,
                          );
                      ref
                          .read(ingredientMemoryProvider.notifier)
                          .rememberCategory(name, selectedCategory);
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(shoppingListProvider);

    final Map<Category, List<ShoppingItem>> groupedItems = {};
    for (var cat in Category.values) {
      groupedItems[cat] = [];
    }
    for (var item in items) {
      groupedItems[item.category]?.add(item);
    }

    final activeCategories = Category.values.where((cat) => (groupedItems[cat] ?? []).isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        actions: [
          if (items.any((item) => item.isChecked))
            IconButton(
              icon: const Icon(Icons.cleaning_services_outlined),
              tooltip: 'Clear Checked Items',
              onPressed: () => ref.read(shoppingListProvider.notifier).clearChecked(),
            ),
          if (items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever_outlined),
              tooltip: 'Clear All Items',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear List?'),
                    content: const Text('This will remove all items from your shopping list.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(shoppingListProvider.notifier).clearAll();
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('Clear All', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 72, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'Your shopping list is empty!',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add ingredients from your recipes or tap + below.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80, top: 8),
              itemCount: activeCategories.length,
              itemBuilder: (context, catIndex) {
                final category = activeCategories[catIndex];
                final categoryItems = groupedItems[category]!;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    leading: Icon(category.icon, color: Theme.of(context).primaryColor),
                    title: Text(
                      '${category.displayName} (${categoryItems.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    children: categoryItems.map((item) {
                      return CheckboxListTile(
                        value: item.isChecked,
                        title: Text(
                          item.name,
                          style: TextStyle(
                            decoration: item.isChecked ? TextDecoration.lineThrough : null,
                            color: item.isChecked ? Colors.grey : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} ${item.unit}',
                          style: TextStyle(
                            decoration: item.isChecked ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        secondary: IconButton(
                          icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                          onPressed: () => ref.read(shoppingListProvider.notifier).removeItem(item.id),
                        ),
                        onChanged: (_) {
                          ref.read(shoppingListProvider.notifier).toggleItem(item.id);
                        },
                      );
                    }).toList(),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}