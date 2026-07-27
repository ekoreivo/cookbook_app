import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cookbook_app/models/recipe.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Hive Box Constants
const String kRecipesBox = 'recipes_box';
const String kShoppingBox = 'shopping_box';
const String kMemoryBox = 'ingredient_memory_box';
const String kSettingsBox = 'settings_box';

// ---------------------------------------------------------------------------
// RECIPES NOTIFIER (FIRESTORE CLOUD SYNC)
// ---------------------------------------------------------------------------
class RecipeNotifier extends StateNotifier<List<Recipe>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RecipeNotifier() : super([]) {
    _loadInitialData();
  }

  void _loadInitialData() async {
    try {
      final snapshot = await _firestore.collection('recipes').get();
      if (snapshot.docs.isEmpty) {
        await _seedDefaultRecipes();
      } else {
        state = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return Recipe.fromJson(data);
        }).toList();
      }
      _listenToFirestore();
    } catch (_) {
      state = _defaultRecipes();
    }
  }

  void _listenToFirestore() {
    _firestore.collection('recipes').snapshots().listen((snapshot) {
      final recipes = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Recipe.fromJson(data);
      }).toList();
      
      if (recipes.isNotEmpty) {
        state = recipes;
      }
    });
  }

  Future<void> _seedDefaultRecipes() async {
    final defaults = _defaultRecipes();
    for (final recipe in defaults) {
      await _firestore.collection('recipes').doc(recipe.id).set(recipe.toJson());
    }
    state = defaults;
  }

  Future<void> addRecipe(Recipe recipe) async {
    state = [...state, recipe];
    await _firestore.collection('recipes').doc(recipe.id).set(recipe.toJson());
  }

  Future<void> updateRecipe(Recipe recipe) async {
    state = [
      for (final r in state)
        if (r.id == recipe.id) recipe else r
    ];
    await _firestore.collection('recipes').doc(recipe.id).update(recipe.toJson());
  }

  Future<void> deleteRecipe(String id) async {
    state = state.where((r) => r.id != id).toList();
    await _firestore.collection('recipes').doc(id).delete();
  }

  List<Recipe> _defaultRecipes() {
    return [
      Recipe(
        id: '1',
        title: 'Classic Spaghetti Carbonara',
        prepTimeMinutes: 20,
        instructions:
            '1. Cook spaghetti in salted water.\n2. Crisp guanciale in a dry skillet.\n3. Whisk egg yolks, grated Pecorino, and pepper.\n4. Combine pasta and fat off heat, then stir in egg mix quickly.',
        ingredients: [
          Ingredient(name: 'Spaghetti', quantity: 400, unit: 'g', category: Category.grain),
          Ingredient(name: 'Guanciale', quantity: 150, unit: 'g', category: Category.meat),
          Ingredient(name: 'Egg Yolks', quantity: 4, unit: 'items', category: Category.dairy),
          Ingredient(name: 'Pecorino Romano', quantity: 50, unit: 'g', category: Category.dairy),
        ],
      ),
      Recipe(
        id: '2',
        title: 'Fresh Garden Salad',
        prepTimeMinutes: 10,
        instructions:
            '1. Wash and chop lettuce, tomatoes, and cucumbers.\n2. Whisk olive oil, lemon juice, salt, and pepper for dressing.\n3. Toss salad ingredients and serve immediately.',
        ingredients: [
          Ingredient(name: 'Romaine Lettuce', quantity: 1, unit: 'head', category: Category.vegetable),
          Ingredient(name: 'Cherry Tomatoes', quantity: 200, unit: 'g', category: Category.fruit),
          Ingredient(name: 'Cucumber', quantity: 1, unit: 'item', category: Category.vegetable),
          Ingredient(name: 'Olive Oil', quantity: 2, unit: 'tbsp', category: Category.sauceSeasoning),
        ],
      ),
    ];
  }
}

final recipeProvider = StateNotifierProvider<RecipeNotifier, List<Recipe>>((ref) {
  return RecipeNotifier();
});

// ---------------------------------------------------------------------------
// SHOPPING LIST NOTIFIER
// ---------------------------------------------------------------------------
class ShoppingListNotifier extends StateNotifier<List<ShoppingItem>> {
  final Box box;

  ShoppingListNotifier(this.box) : super([]) {
    _loadFromBox();
  }

  void _loadFromBox() {
    final rawList = box.get('shopping');
    if (rawList != null) {
      try {
        final List<dynamic> decoded = rawList as List<dynamic>;
        state = decoded
            .map((item) => ShoppingItem.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      } catch (_) {
        state = [];
      }
    }
  }

  void _saveToBox() {
    box.put('shopping', state.map((item) => item.toJson()).toList());
  }

  /// Accepts a list of ingredients directly (matches line 363)
  void addRecipeIngredients(List<Ingredient> ingredients) {
    final List<ShoppingItem> updatedList = List.from(state);

    for (final ing in ingredients) {
      final existingIndex = updatedList.indexWhere(
        (item) =>
            item.name.toLowerCase() == ing.name.toLowerCase() &&
            item.unit.toLowerCase() == ing.unit.toLowerCase(),
      );

      if (existingIndex != -1) {
        final existing = updatedList[existingIndex];
        updatedList[existingIndex] = existing.copyWith(
          quantity: existing.quantity + ing.quantity,
        );
      } else {
        updatedList.add(
          ShoppingItem(
            id: DateTime.now().microsecondsSinceEpoch.toString() +
                ing.name.hashCode.toString(),
            name: ing.name,
            quantity: ing.quantity,
            unit: ing.unit,
            category: ing.category,
          ),
        );
      }
    }

    state = updatedList;
    _saveToBox();
  }

  void addIngredientsFromRecipe(Recipe recipe) {
    final List<ShoppingItem> updatedList = List.from(state);

    for (final ing in recipe.ingredients) {
      final existingIndex = updatedList.indexWhere(
        (item) => item.name.toLowerCase() == ing.name.toLowerCase() && item.unit.toLowerCase() == ing.unit.toLowerCase(),
      );

      if (existingIndex != -1) {
        final existing = updatedList[existingIndex];
        updatedList[existingIndex] = existing.copyWith(
          quantity: existing.quantity + ing.quantity,
        );
      } else {
        updatedList.add(
          ShoppingItem(
            id: DateTime.now().microsecondsSinceEpoch.toString() + ing.name.hashCode.toString(),
            name: ing.name,
            quantity: ing.quantity,
            unit: ing.unit,
            category: ing.category,
          ),
        );
      }
    }

    state = updatedList;
    _saveToBox();
  }

  void addItem(String name, double quantity, String unit, Category category) {
    final existingIndex = state.indexWhere(
      (item) => item.name.toLowerCase() == name.toLowerCase() && item.unit.toLowerCase() == unit.toLowerCase(),
    );

    if (existingIndex != -1) {
      final existing = state[existingIndex];
      final updated = List<ShoppingItem>.from(state);
      updated[existingIndex] = existing.copyWith(quantity: existing.quantity + quantity);
      state = updated;
    } else {
      final newItem = ShoppingItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        quantity: quantity,
        unit: unit,
        category: category,
      );
      state = [...state, newItem];
    }
    _saveToBox();
  }

  void toggleItem(String id) {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(isChecked: !item.isChecked) else item
    ];
    _saveToBox();
  }

  void removeItem(String id) {
    state = state.where((item) => item.id != id).toList();
    _saveToBox();
  }

  void clearChecked() {
    state = state.where((item) => !item.isChecked).toList();
    _saveToBox();
  }

  void clearAll() {
    state = [];
    _saveToBox();
  }
}

final shoppingListProvider = StateNotifierProvider<ShoppingListNotifier, List<ShoppingItem>>((ref) {
  final box = Hive.box(kShoppingBox);
  return ShoppingListNotifier(box);
});

// ---------------------------------------------------------------------------
// INGREDIENT MEMORY NOTIFIER
// ---------------------------------------------------------------------------
class IngredientMemoryNotifier extends StateNotifier<Map<String, Category>> {
  final Box box;

  IngredientMemoryNotifier(this.box) : super({}) {
    _loadFromBox();
  }

  void _loadFromBox() {
    final rawMap = box.get('memory');
    if (rawMap != null) {
      try {
        final Map<dynamic, dynamic> decoded = rawMap as Map<dynamic, dynamic>;
        final Map<String, Category> map = {};
        decoded.forEach((key, value) {
          map[key.toString().toLowerCase()] = Category.fromString(value.toString());
        });
        state = map;
      } catch (_) {
        state = {};
      }
    }
  }

  void _saveToBox() {
    final Map<String, String> rawMap = {};
    state.forEach((key, value) {
      rawMap[key] = value.name;
    });
    box.put('memory', rawMap);
  }

  Category? lookupCategory(String name) {
    return state[name.trim().toLowerCase()];
  }

  void rememberCategory(String name, Category category) {
    final key = name.trim().toLowerCase();
    if (key.isEmpty) return;
    if (state[key] != category) {
      state = {...state, key: category};
      _saveToBox();
    }
  }
}

final ingredientMemoryProvider = StateNotifierProvider<IngredientMemoryNotifier, Map<String, Category>>((ref) {
  final box = Hive.box(kMemoryBox);
  return IngredientMemoryNotifier(box);
});

// ---------------------------------------------------------------------------
// THEME MODE NOTIFIER
// ---------------------------------------------------------------------------
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final Box box;

  ThemeModeNotifier(this.box) : super(ThemeMode.system) {
    _loadFromBox();
  }

  void _loadFromBox() {
    final savedMode = box.get('theme_mode', defaultValue: 'system') as String;
    switch (savedMode) {
      case 'dark':
        state = ThemeMode.dark;
        break;
      case 'light':
        state = ThemeMode.light;
        break;
      default:
        state = ThemeMode.system;
    }
  }

  void toggleTheme() {
    if (state == ThemeMode.dark) {
      state = ThemeMode.light;
      box.put('theme_mode', 'light');
    } else {
      state = ThemeMode.dark;
      box.put('theme_mode', 'dark');
    }
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    box.put('theme_mode', mode.name);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final box = Hive.box(kSettingsBox);
  return ThemeModeNotifier(box);
});
