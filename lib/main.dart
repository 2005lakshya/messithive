import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'homepage.dart';
import 'services/hive_service.dart';
import 'services/menu_service.dart';
import 'models/menu_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Register Hive adapters
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(MenuDataAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(MealDataAdapter());
  }

  // Initialize services
  await HiveService.init();
  await MenuService.init();

  // Load menu data
  await MenuService.loadAndStoreMenuData();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const MyHomePage(title: 'Messit'),
      debugShowCheckedModeBanner: false,
    );
  }
}
