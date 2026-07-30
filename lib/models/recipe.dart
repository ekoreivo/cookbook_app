import 'package:flutter/material.dart';

/// Categories with custom display names and colors
enum Category {
  fruit('Fruits', Color.fromARGB(255, 104, 9, 128)),
  vegetable('Vegetables', Colors.green),
  dairy('Dairy & Eggs', Color.fromARGB(255, 135, 168, 175)),
  meat('Meat & Seafood', Colors.red),
  grain('Grain', Color.fromARGB(255, 187, 175, 4)),
  sauceSeasoning('Sauce & Seasoning', Colors.deepOrange),
  frozen('Frozen Foods', Color.fromARGB(255, 55, 159, 245)),
  beverages('Beverages', Color.fromARGB(255, 202, 54, 178)),
  household('Household', Color.fromARGB(255, 99, 76, 126)),
  other('Other', Colors.grey);

  final String displayName;
  final Color color;

  const Category(this.displayName, this.color);

  IconData get icon {
    switch (this) {
      case Category.fruit:
        return Icons.apple;
      case Category.vegetable:
        return Icons.eco;
      case Category.dairy:
        return Icons.egg_alt;
      case Category.meat:
        return Icons.outdoor_grill;
      case Category.grain:
        return Icons.ramen_dining;
      case Category.sauceSeasoning:
        return Icons.snowing;
      case Category.frozen:
        return Icons.ac_unit;
      case Category.beverages:
        return Icons.local_drink;
      case Category.household:
        return Icons.house;
      case Category.other:
        return Icons.shopping_bag;
    }
  }

  static Category fromString(String name) {
    return Category.values.firstWhere(
      (c) =>
          c.name.toLowerCase() == name.toLowerCase() ||
          c.displayName.toLowerCase() == name.toLowerCase(),
      orElse: () => Category.other,
    );
  }
}

class Ingredient {
  final String name;
  final double quantity;
  final String unit;
  final Category category;

  Ingredient({
    required this.name,
    required this.quantity,
    required this.unit,
    this.category = Category.other,
  });

  Ingredient copyWith({
    String? name,
    double? quantity,
    String? unit,
    Category? category,
  }) {
    return Ingredient(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'category': category.name,
      };

  factory Ingredient.fromJson(Map<String, dynamic> json) => Ingredient(
        name: json['name'] as String? ?? '',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
        unit: json['unit'] as String? ?? '',
        category: Category.fromString(json['category'] as String? ?? ''),
      );
}

class Recipe {
  final String id;
  final String title;
  final int prepTimeMinutes;
  final String instructions;
  final List<Ingredient> ingredients;

  Recipe({
    required this.id,
    required this.title,
    required this.prepTimeMinutes,
    required this.instructions,
    required this.ingredients,
  });

  Recipe copyWith({
    String? id,
    String? title,
    int? prepTimeMinutes,
    String? instructions,
    List<Ingredient>? ingredients,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      instructions: instructions ?? this.instructions,
      ingredients: ingredients ?? this.ingredients,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'prepTimeMinutes': prepTimeMinutes,
        'instructions': instructions,
        'ingredients': ingredients.map((i) => i.toJson()).toList(),
      };

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        prepTimeMinutes: json['prepTimeMinutes'] as int? ?? 0,
        instructions: json['instructions'] as String? ?? '',
        ingredients: (json['ingredients'] as List<dynamic>?)
                ?.map((i) => Ingredient.fromJson(Map<String, dynamic>.from(i as Map)))
                .toList() ??
            [],
      );
}

class ShoppingItem {
  final String id;
  final String name;
  final double quantity;
  final String unit;
  final Category category;
  final bool isChecked;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.category,
    this.isChecked = false,
  });

  ShoppingItem copyWith({
    String? id,
    String? name,
    double? quantity,
    String? unit,
    Category? category,
    bool? isChecked,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      isChecked: isChecked ?? this.isChecked,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'category': category.name,
        'isChecked': isChecked,
      };

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
        unit: json['unit'] as String? ?? 'item',
        category: Category.fromString(json['category'] as String? ?? ''),
        isChecked: json['isChecked'] as bool? ?? false,
      );
}