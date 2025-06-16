import 'package:flutter/material.dart';
import 'homepage.dart';
import 'services/menu_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await MenuService.init();

  // Check if menu data exists in Hive
  final hasMenuData = await MenuService.hasMenuData();
  if (!hasMenuData) {
    print('First run: Loading data from JSON and encrypting...');
    // Only load from JSON if data doesn't exist in Hive
    await MenuService.loadAndStoreMenuData();
  } else {
    print('Using encrypted data from Hive...');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
