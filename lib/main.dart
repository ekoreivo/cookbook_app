import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cookbook_app/providers/app_state.dart';
import 'package:cookbook_app/screens/main_home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.initFlutter(); // Initialize Hive for Flutter
  
  // Open the required boxes
  await Hive.openBox(kRecipesBox);
  await Hive.openBox(kMemoryBox);

  runApp(
    const ProviderScope(
      child: MyApp(), // Replace with your main app widget name
    ),
  );
}

// ============================================================================
// STEP 3: MyApp Widget connected to themeModeProvider
// ============================================================================
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watches the themeModeProvider from app_state.dart
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Cookbook App',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: const Color.fromARGB(255, 0, 59, 136),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color.fromARGB(255, 0, 59, 136),
      ),
      home: const MainHomeScreen(), // Your main starting screen
    );
  }
}