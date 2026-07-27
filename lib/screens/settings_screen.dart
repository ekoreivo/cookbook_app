import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cookbook_app/models/recipe.dart';
import 'package:cookbook_app/providers/app_state.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _ingredientController = TextEditingController();
  Category _selectedCategory = Category.fruit;

  @override
  void dispose() {
    _ingredientController.dispose();
    super.dispose();
  }

  void _addOrUpdateMapping() {
    final name = _ingredientController.text.trim();
    if (name.isNotEmpty) {
      ref.read(ingredientMemoryProvider.notifier).rememberCategory(name, _selectedCategory);
      _ingredientController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved categorization for "$name"')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final mappings = ref.watch(ingredientMemoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile(
              secondary: Icon(
                isDark ? Icons.dark_mode : Icons.light_mode,
                color: const Color(0xFF007AFF),
              ),
              title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.bold)),
              value: isDark,
              onChanged: (_) {
                ref.read(themeModeProvider.notifier).toggleTheme();
              },
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Ingredient Categorization Rules',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Assign default categories to ingredients so they auto-group on your shopping list.',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _ingredientController,
                    decoration: const InputDecoration(
                      labelText: 'Ingredient Name (e.g. Avocado)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<Category>(
                          initialValue: _selectedCategory,
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
                          onChanged: (cat) {
                            if (cat != null) setState(() => _selectedCategory = cat);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007AFF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        ),
                        onPressed: _addOrUpdateMapping,
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (mappings.isNotEmpty) ...[
            const Text('Saved Mappings:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...mappings.entries.map((entry) {
              return ListTile(
                dense: true,
                title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: entry.value.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    entry.value.displayName,
                    style: TextStyle(color: entry.value.color, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}