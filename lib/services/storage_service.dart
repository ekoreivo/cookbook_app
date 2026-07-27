import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cookbook_app/models/recipe.dart';

class StorageService {
  static const String _recipesBoxName = 'recipes_box';
  static const String _shoppingBoxName = 'shopping_box';
  static const String _settingsBoxName = 'settings_box';

  static late Box _recipesBox;
  static late Box _shoppingBox;
  static late Box _settingsBox;

  /// Initialize Hive and open storage boxes
  static Future<void> init() async {
    await Hive.initFlutter();
    _recipesBox = await Hive.openBox(_recipesBoxName);
    _shoppingBox = await Hive.openBox(_shoppingBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }

  // --- RECIPES ---
  static List<Recipe> loadRecipes() {
    final rawData = _recipesBox.get('recipes_list');
    if (rawData == null) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(rawData as String);
      return jsonList.map((item) => Recipe.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveRecipes(List<Recipe> recipes) async {
    final jsonString = jsonEncode(recipes.map((r) => r.toJson()).toList());
    await _recipesBox.put('recipes_list', jsonString);
  }

  // --- SHOPPING LIST ---
  static List<ShoppingItem> loadShoppingList() {
    final rawData = _shoppingBox.get('shopping_list');
    if (rawData == null) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(rawData as String);
      return jsonList.map((item) => ShoppingItem.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveShoppingList(List<ShoppingItem> items) async {
    final jsonString = jsonEncode(items.map((i) => i.toJson()).toList());
    await _shoppingBox.put('shopping_list', jsonString);
  }

  // --- INGREDIENT CATEGORY MEMORY ---
  static Map<String, Category> loadIngredientMemory() {
    final rawData = _settingsBox.get('ingredient_memory');
    if (rawData == null) return {};
    try {
      final Map<String, dynamic> jsonMap = jsonDecode(rawData as String);
      return jsonMap.map((key, value) {
        final category = Category.values.firstWhere(
          (c) => c.name == value,
          orElse: () => Category.other,
        );
        return MapEntry(key, category);
      });
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveIngredientMemory(Map<String, Category> memory) async {
    final rawMap = memory.map((key, value) => MapEntry(key, value.name));
    await _settingsBox.put('ingredient_memory', jsonDecode(jsonEncode(rawMap)));
  }

  // --- THEME ---
  static bool loadIsDarkMode() {
    return _settingsBox.get('is_dark_mode', defaultValue: true) as bool;
  }

  static Future<void> saveIsDarkMode(bool isDark) async {
    await _settingsBox.put('is_dark_mode', isDark);
  }
}