import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cookbook_app/models/recipe.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ---------------------------------------------------------------------------
// RECIPES NOTIFIER (DIRECT STREAM SYNC)
// ---------------------------------------------------------------------------
class RecipeNotifier extends StateNotifier<List<Recipe>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RecipeNotifier() : super([]) {
    _listenToFirestore();
  }

  void _listenToFirestore() {
    _firestore.collection('recipes').snapshots().listen((snapshot) {
      final recipes = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Recipe.fromJson(data);
      }).toList();

      if (recipes.isEmpty) {
        _seedDefaultRecipes();
      } else {
        state = recipes;
      }
    }, onError: (_) {
      state = _defaultRecipes();
    });
  }

  Future<void> _seedDefaultRecipes() async {
    final defaults = _defaultRecipes();
    // Only seed locally first to prevent UI freezing
    state = defaults;
    
    // Then push to Firestore in the background
    for (final recipe in defaults) {
      await _firestore.collection('recipes').doc(recipe.id).set(recipe.toJson());
    }
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
// SHOPPING LIST NOTIFIER (FIREBASE SYNC)
// ---------------------------------------------------------------------------
class ShoppingListNotifier extends StateNotifier<List<ShoppingItem>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ShoppingListNotifier() : super([]) {
    _listenToFirestore();
  }

  void _listenToFirestore() {
    _firestore.collection('shopping_list').snapshots().listen((snapshot) {
      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Use the Firebase document ID
        return ShoppingItem.fromJson(data);
      }).toList();
      
      state = items;
    }, onError: (error) {
      print("Error listening to shopping list: $error");
      state = [];
    });
  }

  // Helper to save or update an individual item in Firebase
  Future<void> _saveItemToFirebase(ShoppingItem item) async {
    await _firestore.collection('shopping_list').doc(item.id).set(item.toJson());
  }

  // Helper to delete an individual item from Firebase
  Future<void> _deleteItemFromFirebase(String id) async {
    await _firestore.collection('shopping_list').doc(id).delete();
  }

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
        final updatedItem = existing.copyWith(
          quantity: existing.quantity + ing.quantity,
        );
        updatedList[existingIndex] = updatedItem;
        _saveItemToFirebase(updatedItem); // Send update to cloud
      } else {
        final newItem = ShoppingItem(
          id: DateTime.now().microsecondsSinceEpoch.toString() +
              ing.name.hashCode.toString(),
          name: ing.name,
          quantity: ing.quantity,
          unit: ing.unit,
          category: ing.category,
        );
        updatedList.add(newItem);
        _saveItemToFirebase(newItem); // Send new item to cloud
      }
    }
    state = updatedList; // Update local UI instantly
  }

  void addIngredientsFromRecipe(Recipe recipe) {
    // Reuse the logic above for cleaner code!
    addRecipeIngredients(recipe.ingredients);
  }

  void addItem(String name, double quantity, String unit, Category category) {
    final existingIndex = state.indexWhere(
      (item) => item.name.toLowerCase() == name.toLowerCase() && item.unit.toLowerCase() == unit.toLowerCase(),
    );

    if (existingIndex != -1) {
      final existing = state[existingIndex];
      final updatedItem = existing.copyWith(quantity: existing.quantity + quantity);
      
      final updatedList = List<ShoppingItem>.from(state);
      updatedList[existingIndex] = updatedItem;
      state = updatedList;
      
      _saveItemToFirebase(updatedItem);
    } else {
      final newItem = ShoppingItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        quantity: quantity,
        unit: unit,
        category: category,
      );
      state = [...state, newItem];
      
      _saveItemToFirebase(newItem);
    }
  }

  void toggleItem(String id) {
    final existingIndex = state.indexWhere((item) => item.id == id);
    if (existingIndex != -1) {
      final item = state[existingIndex];
      final updatedItem = item.copyWith(isChecked: !item.isChecked);
      
      state = [
        for (final i in state)
          if (i.id == id) updatedItem else i
      ];
      
      _saveItemToFirebase(updatedItem);
    }
  }

  void removeItem(String id) {
    state = state.where((item) => item.id != id).toList();
    _deleteItemFromFirebase(id);
  }

  void clearChecked() {
    final checkedItems = state.where((item) => item.isChecked).toList();
    state = state.where((item) => !item.isChecked).toList();
    
    // Delete all checked items from Firebase
    for (final item in checkedItems) {
      _deleteItemFromFirebase(item.id);
    }
  }

  void clearAll() {
    final allItems = List<ShoppingItem>.from(state);
    state = [];
    
    // Delete all items from Firebase
    for (final item in allItems) {
      _deleteItemFromFirebase(item.id);
    }
  }
}

// Notice how we removed the Hive Box injection here!
final shoppingListProvider = StateNotifierProvider<ShoppingListNotifier, List<ShoppingItem>>((ref) {
  return ShoppingListNotifier();
});

// ---------------------------------------------------------------------------
// INGREDIENT MEMORY NOTIFIER (FIREBASE SYNC)
// ---------------------------------------------------------------------------
class IngredientMemoryNotifier extends StateNotifier<Map<String, Category>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // We'll store the memory map in a dedicated document inside 'settings'
  final String _docId = 'ingredient_memory'; 

  IngredientMemoryNotifier() : super({}) {
    _listenToFirestore();
  }

  void _listenToFirestore() {
    _firestore.collection('settings').doc(_docId).snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        try {
          final data = snapshot.data()!;
          final Map<String, Category> map = {};
          
          data.forEach((key, value) {
            map[key.toString().toLowerCase()] = Category.fromString(value.toString());
          });
          
          state = map;
        } catch (_) {
          state = {};
        }
      }
    }, onError: (error) {
      print("Error listening to ingredient memory: $error");
    });
  }

  Future<void> _saveToFirebase() async {
    final Map<String, String> rawMap = {};
    state.forEach((key, value) {
      rawMap[key] = value.name;
    });
    
    // Push the entire map to Firestore
    await _firestore.collection('settings').doc(_docId).set(rawMap);
  }

  Category? lookupCategory(String name) {
    return state[name.trim().toLowerCase()];
  }

  void rememberCategory(String name, Category category) {
    final key = name.trim().toLowerCase();
    if (key.isEmpty) return;
    
    if (state[key] != category) {
      state = {...state, key: category}; // Update local UI instantly
      _saveToFirebase(); // Sync to the cloud
    }
  }
}

// Notice we removed the Hive.box() injection here!
final ingredientMemoryProvider = StateNotifierProvider<IngredientMemoryNotifier, Map<String, Category>>((ref) {
  return IngredientMemoryNotifier();
});

// ---------------------------------------------------------------------------
// THEME MODE NOTIFIER (FIREBASE SYNC)
// ---------------------------------------------------------------------------
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _docId = 'user_settings'; // A single document for global settings

  ThemeModeNotifier() : super(ThemeMode.system) {
    _listenToFirestore();
  }

  void _listenToFirestore() {
    _firestore.collection('settings').doc(_docId).snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        // Read the theme from Firebase
        final savedMode = snapshot.data()!['theme_mode'] as String? ?? 'system';
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
      } else {
        // If no settings exist yet in Firebase, save the default
        _saveToFirebase(ThemeMode.system);
      }
    }, onError: (error) {
      print("Error listening to theme settings: $error");
    });
  }

  Future<void> _saveToFirebase(ThemeMode mode) async {
    // SetOptions(merge: true) ensures we don't overwrite other settings later
    await _firestore.collection('settings').doc(_docId).set({
      'theme_mode': mode.name, 
    }, SetOptions(merge: true));
  }

  void toggleTheme() {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = newMode; // Instantly update UI locally
    _saveToFirebase(newMode); // Sync to the cloud
  }

  void setThemeMode(ThemeMode mode) {
    state = mode; // Instantly update UI locally
    _saveToFirebase(mode); // Sync to the cloud
  }
}

// Notice we removed the Hive.box() call here!
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});
