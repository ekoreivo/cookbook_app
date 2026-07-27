import 'package:flutter/material.dart';
import 'package:cookbook_app/screens/recipe_list_screen.dart';
import 'package:cookbook_app/screens/shopping_list_screen.dart';
import 'package:cookbook_app/screens/settings_screen.dart';
// If you have a memory screen, uncomment the import below:
// import 'package:cookbook_app/screens/memory_screen.dart';

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State {
  int _selectedIndex = 0;

  // These are the screens the menu will switch between.
  // Make sure the order matches the destinations below!
  final List _screens = const [
    RecipeListScreen(),
    ShoppingListScreen(),
    SettingsScreen(),
    // MemoryScreen(), // Uncomment if you have this screen
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Recipes',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Shopping',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
          // Add another NavigationDestination here if you have a 4th screen
        ],
      ),
    );
  }
}