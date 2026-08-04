import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:cookbook_app/models/recipe.dart';
import 'package:cookbook_app/providers/app_state.dart';
import 'package:cookbook_app/screens/add_recipe_screen.dart';

class RecipeListScreen extends ConsumerStatefulWidget {
  const RecipeListScreen({super.key});

  @override
  ConsumerState<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends ConsumerState<RecipeListScreen> {
  Recipe? _selectedRecipe;

  @override
  Widget build(BuildContext context) {
    final recipes = ref.watch(recipeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_selectedRecipe != null) {
      final updated = recipes.where((r) => r.id == _selectedRecipe!.id);
      if (updated.isNotEmpty) {
        _selectedRecipe = updated.first;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Cookbook',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 28),
            color: const Color(0xFF007AFF),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddRecipeScreen()),
              );
            },
          ),
        ],
      ),
      body: recipes.isEmpty
          ? const Center(
              child: Text(
                'No recipes yet. Tap + to add one!',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 700) {
                  return Row(
                    children: [
                      SizedBox(
                        width: 300,
                        child: _buildRecipeListView(recipes),
                      ),
                      VerticalDivider(width: 1, color: isDark ? Colors.white12 : Colors.black12),
                      Expanded(
                        child: _selectedRecipe == null
                            ? const Center(
                                child: Text(
                                  'Select a recipe to view details',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : _RecipeDetailCard(
                                recipe: _selectedRecipe!,
                                onEdit: () => _openEditScreen(_selectedRecipe!),
                              ),
                      ),
                    ],
                  );
                }

                if (_selectedRecipe != null) {
                  return PopScope(
                    canPop: false,
                    onPopInvokedWithResult: (didPop, result) {
                      if (didPop) return;
                      setState(() => _selectedRecipe = null);
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: isDark ? Colors.grey[900] : Colors.grey[200],
                          child: Row(
                            children: [
                              TextButton.icon(
                                onPressed: () => setState(() => _selectedRecipe = null),
                                icon: const Icon(Icons.arrow_back, color: Color(0xFF007AFF)),
                                label: const Text('All Recipes', style: TextStyle(color: Color(0xFF007AFF))),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _RecipeDetailCard(
                            recipe: _selectedRecipe!,
                            onEdit: () => _openEditScreen(_selectedRecipe!),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return _buildRecipeListView(recipes);
              },
            ),
    );
  }

  Widget _buildRecipeListView(List<Recipe> recipes) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        final isSelected = _selectedRecipe?.id == recipe.id;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          color: isSelected
              ? const Color(0xFF007AFF).withValues(alpha: 0.15)
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isSelected
                ? const BorderSide(color: Color(0xFF007AFF), width: 1.5)
                : BorderSide.none,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              recipe.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${recipe.prepTimeMinutes} mins', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(width: 12),
                const Icon(Icons.restaurant, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${recipe.ingredients.length} items', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              setState(() {
                _selectedRecipe = recipe;
              });
            },
          ),
        );
      },
    );
  }

  void _openEditScreen(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddRecipeScreen(recipeToEdit: recipe),
      ),
    );
  }
}

class _RecipeDetailCard extends ConsumerWidget {
  final Recipe recipe;
  final VoidCallback onEdit;

  const _RecipeDetailCard({required this.recipe, required this.onEdit});

  // Helper method to safely render formatted text or fallback to standard text
  Widget _buildRichTextView(String text) {
    try {
      // Try to parse the string as a JSON array (Quill Delta format)
      final jsonDelta = jsonDecode(text);
      final controller = QuillController(
        document: Document.fromJson(jsonDelta),
        selection: const TextSelection.collapsed(offset: 0),
      );
      
      return AbsorbPointer( // Prevents the read-only editor from stealing scrolling focus
        child: QuillEditor.basic(
          controller: controller,
        ),
      );
    } catch (e) {
      // If parsing fails, it's a legacy plain-text recipe
      return Text(
        text,
        style: const TextStyle(fontSize: 15, height: 1.6),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time_filled, size: 14, color: Color(0xFF007AFF)),
                          const SizedBox(width: 6),
                          Text(
                            'Approx. ${recipe.prepTimeMinutes} mins',
                            style: const TextStyle(
                              color: Color(0xFF007AFF),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_note, color: Color(0xFF007AFF), size: 28),
                tooltip: 'Edit Recipe',
                onPressed: onEdit,
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // --- PREP SECTION ---
          if (recipe.prep != null && recipe.prep!.trim().isNotEmpty)
            Card(
              clipBehavior: Clip.antiAlias,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ExpansionTile(
                initiallyExpanded: false,
                collapsedBackgroundColor: const Color.fromARGB(255, 253, 115, 2).withValues(alpha: 0.1),
                backgroundColor: const Color.fromARGB(255, 253, 115, 2).withValues(alpha: 0.1),
                textColor: const Color.fromARGB(255, 253, 115, 2),
                collapsedTextColor: const Color.fromARGB(255, 253, 115, 2),
                iconColor: const Color.fromARGB(255, 253, 115, 2),
                collapsedIconColor: const Color.fromARGB(255, 253, 115, 2),
                leading: const Icon(Icons.flatware),
                title: const Text(
                  'PREP WORK',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.2),
                ),
                children: [
                  Container(
                    width: double.infinity,
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
                    padding: const EdgeInsets.all(16.0),
                    child: _buildRichTextView(recipe.prep!),
                  ),
                ],
              ),
            ),

          // --- NOTES SECTION ---
          if (recipe.notes != null && recipe.notes!.trim().isNotEmpty)
            Card(
              clipBehavior: Clip.antiAlias,
              margin: const EdgeInsets.only(bottom: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ExpansionTile(
                initiallyExpanded: false,
                collapsedBackgroundColor: Colors.deepPurple.withValues(alpha: 0.1),
                backgroundColor: Colors.deepPurple.withValues(alpha: 0.1),
                textColor: Colors.deepPurple,
                collapsedTextColor: Colors.deepPurple,
                iconColor: Colors.deepPurple,
                collapsedIconColor: Colors.deepPurple,
                leading: const Icon(Icons.note_alt),
                title: const Text(
                  'NOTES',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.2),
                ),
                children: [
                  Container(
                    width: double.infinity,
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
                    padding: const EdgeInsets.all(16.0),
                    child: _buildRichTextView(recipe.notes!),
                  ),
                ],
              ),
            ),
            
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 550;

              final ingredientsWidget = Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'INGREDIENTS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: Color(0xFF007AFF),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...recipe.ingredients.map(
                      (ing) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: ing.category.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                ing.name,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            if (ing.formattedMeasurement != null)
                              Text(
                                ing.formattedMeasurement!,
                                style: const TextStyle(color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );

              final instructionsWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'INSTRUCTIONS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: Color(0xFF007AFF),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRichTextView(recipe.instructions),
                ],
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: instructionsWidget),
                    const SizedBox(width: 20),
                    Expanded(flex: 2, child: ingredientsWidget),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ingredientsWidget,
                  const SizedBox(height: 20),
                  instructionsWidget,
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                elevation: 4,
              ),
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text(
                'Add Ingredients to Shopping List',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                ref.read(shoppingListProvider.notifier).addRecipeIngredients(recipe.ingredients);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added ingredients for "${recipe.title}" to Shopping List!'),
                    backgroundColor: const Color(0xFF007AFF),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}