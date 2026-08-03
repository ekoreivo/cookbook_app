import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cookbook_app/models/recipe.dart';
import 'package:cookbook_app/providers/app_state.dart';

class AddRecipeScreen extends ConsumerStatefulWidget {
  final Recipe? recipeToEdit;

  const AddRecipeScreen({super.key, this.recipeToEdit});

  @override
  ConsumerState<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class TempIngredient {
  final TextEditingController nameController;
  final TextEditingController quantityController;
  final TextEditingController unitController;
  Category category;

  TempIngredient({
    String name = '',
    String quantity = '',
    String unit = '',
    this.category = Category.other,
  })  : nameController = TextEditingController(text: name),
        quantityController = TextEditingController(text: quantity),
        unitController = TextEditingController(text: unit);

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    unitController.dispose();
  }
}

class _AddRecipeScreenState extends ConsumerState<AddRecipeScreen> {
  late TextEditingController _titleController;
  late TextEditingController _timeController;
  late TextEditingController _instructionsController;
  late List<TempIngredient> _ingredients;
  late TextEditingController _notesController;
  late TextEditingController _prepController;


  bool get isEditing => widget.recipeToEdit != null;

  @override
  void initState() {
    super.initState();
    final r = widget.recipeToEdit;
    _titleController = TextEditingController(text: r?.title ?? '');
    _timeController = TextEditingController(text: (r?.prepTimeMinutes ?? 20).toString());
    _instructionsController = TextEditingController(text: r?.instructions ?? '');
    _notesController = TextEditingController(text: r?.notes ?? '');
    _prepController = TextEditingController(text: r?.prep ?? '');

    if (r != null && r.ingredients.isNotEmpty) {
      _ingredients = r.ingredients
          .map((ing) => TempIngredient(
                name: ing.name,
                quantity: ing.quantity % 1 == 0 ? ing.quantity.toInt().toString() : ing.quantity.toString(),
                unit: ing.unit,
                category: ing.category,
              ))
          .toList();
    } else {
      _ingredients = [TempIngredient()];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _timeController.dispose();
    _instructionsController.dispose();
    _notesController.dispose();
    _prepController.dispose();
    for (var ing in _ingredients) {
      ing.dispose();
    }
    super.dispose();
  }

  void _addIngredientRow() {
    setState(() {
      _ingredients.add(TempIngredient());
    });
  }

  void _removeIngredientRow(int index) {
    if (_ingredients.length > 1) {
      setState(() {
        final removed = _ingredients.removeAt(index);
        removed.dispose();
      });
    }
  }

  void _checkAutoCategory(int index, String name) {
    if (name.trim().isEmpty) return;
    final matchedCategory = ref.read(ingredientMemoryProvider.notifier).lookupCategory(name);
    if (matchedCategory != null && _ingredients[index].category != matchedCategory) {
      setState(() {
        _ingredients[index].category = matchedCategory;
      });
    }
  }

  void _saveRecipe() {
    final title = _titleController.text.trim();
    final time = int.tryParse(_timeController.text.trim()) ?? 20;
    final instructions = _instructionsController.text.trim();
    final notes = _notesController.text.trim();
    final prep = _prepController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a recipe title.')),
      );
      return;
    }

    final List<Ingredient> parsedIngredients = [];
    final memoryNotifier = ref.read(ingredientMemoryProvider.notifier);

    for (var temp in _ingredients) {
      final name = temp.nameController.text.trim();
      final qty = double.tryParse(temp.quantityController.text.trim()) ?? 0.0;
      final unit = temp.unitController.text.trim();

      if (name.isNotEmpty) {
        parsedIngredients.add(
          Ingredient(
            name: name,
            quantity: qty,
            unit: unit,
            category: temp.category,
          ),
        );
        memoryNotifier.rememberCategory(name, temp.category);
      }
    }

    if (parsedIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one ingredient.')),
      );
      return;
    }

    if (isEditing) {
      final updated = Recipe(
        id: widget.recipeToEdit!.id,
        title: title,
        prepTimeMinutes: time,
        instructions: instructions,
        ingredients: parsedIngredients,
        notes: notes.isEmpty ? null : notes,
        prep: prep.isEmpty ? null : prep,
      );
      ref.read(recipeProvider.notifier).updateRecipe(updated);
    } else {
      final newRecipe = Recipe(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title,
        prepTimeMinutes: time,
        instructions: instructions,
        ingredients: parsedIngredients,
        notes: notes.isEmpty ? null : notes,
        prep: prep.isEmpty ? null : prep,
      );
      ref.read(recipeProvider.notifier).addRecipe(newRecipe);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Recipe' : 'Add Recipe'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Recipe Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _timeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Approx. Cooking Time (minutes)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _instructionsController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Cooking Instructions',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _prepController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Prep Work (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Ingredients',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._ingredients.asMap().entries.map((entry) {
              final index = entry.key;
              final tempIng = entry.value;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: tempIng.nameController,
                              decoration: const InputDecoration(labelText: 'Ingredient', isDense: true),
                              onChanged: (val) => _checkAutoCategory(index, val),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: tempIng.quantityController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Qty', isDense: true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: tempIng.unitController,
                              decoration: const InputDecoration(labelText: 'Unit', isDense: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          DropdownButton<Category>(
                            value: tempIng.category,
                            items: Category.values.map((cat) {
                              return DropdownMenuItem(
                                value: cat,
                                child: Text(cat.displayName),
                              );
                            }).toList(),
                            onChanged: (newCat) {
                              if (newCat != null) {
                                setState(() => tempIng.category = newCat);
                              }
                            },
                          ),
                          if (_ingredients.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => _removeIngredientRow(index),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            TextButton.icon(
              onPressed: _addIngredientRow,
              icon: const Icon(Icons.add),
              label: const Text('Add Ingredient'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveRecipe,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: Text(
                  isEditing ? 'Update Recipe' : 'Save Recipe',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}