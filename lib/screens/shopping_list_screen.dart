import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cookbook_app/models/recipe.dart';
import 'package:cookbook_app/providers/app_state.dart';

class ShoppingListScreen extends ConsumerWidget {
  const ShoppingListScreen({super.key});

  void _showAddItemDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    final unitController = TextEditingController();
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
                    // Default to 0.0 instead of 1.0 if empty
                    final qty = double.tryParse(quantityController.text.trim()) ?? 0.0;
                    final unit = unitController.text.trim();

                    if (name.isNotEmpty) {
                      ref.read(shoppingListProvider.notifier).addItem(
                            name,
                            qty,
                            unit,
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
                  // IMPORTANT: This keeps the colored backgrounds inside the rounded corners
                  clipBehavior: Clip.antiAlias, 
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    
                    // 1. Color the entire tile header the bold, solid category color
                    collapsedBackgroundColor: category.color,
                    backgroundColor: category.color,
                    
                    // 2. Make the text and icons white so they pop against the bold header
                    textColor: Colors.white,
                    collapsedTextColor: Colors.white,
                    iconColor: Colors.white,
                    collapsedIconColor: Colors.white,
                    
                    leading: Icon(category.icon, color: Colors.white),
                    title: Text(
                      '${category.displayName} (${categoryItems.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    
                    // 3. Wrap the list items to create the faded background effect
                    children: [
                      Container(
                        // Base layer: Blocks the solid color from bleeding through
                        color: Theme.of(context).cardColor, 
                        child: Container(
                          // Faded layer: Applies the category color at 15% opacity
                          color: category.color.withValues(alpha: 0.15), 
                          child: Column(
                            // We use a Column here so all items share the single background Container
                            children: categoryItems.map((item) {
                              
                              // 1. Determine if fields are "empty"
                              final bool isEmptyQuantity = item.quantity == 0;
                              final bool isEmptyUnit = item.unit.trim().isEmpty;

                              // 2. Build the exact string we want
                              String? subtitleText;
                              if (isEmptyQuantity && isEmptyUnit) {
                                subtitleText = null; // Shows nothing (e.g., Ketchup)
                              } else if (isEmptyQuantity) {
                                subtitleText = item.unit; // Shows just unit (e.g., Taste)
                              } else {
                                // Shows quantity + unit, or just quantity
                                final qtyStr = item.quantity % 1 == 0 ? item.quantity.toInt().toString() : item.quantity.toString();
                                subtitleText = isEmptyUnit ? qtyStr : '$qtyStr ${item.unit}';
                              }

                              return CheckboxListTile(
                                value: item.isChecked,
                                title: Text(
                                  item.name,
                                  style: TextStyle(
                                    decoration: item.isChecked ? TextDecoration.lineThrough : null,
                                    // Set to null instead of black87 so it automatically adapts to light/dark themes
                                    color: item.isChecked ? Colors.grey : null, 
                                  ),
                                ),
                                // 3. Inject our smart subtitle!
                                subtitle: subtitleText == null 
                                    ? null 
                                    : Text(
                                        subtitleText,
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
                        ),
                      ),
                    ],
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