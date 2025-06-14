import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/menu_card.dart';

class JsonService {
  static const String _boxName = 'menuData';

  // Initialize Hive box
  static Future<void> init() async {
    await Hive.openBox<MenuCard>(_boxName);
  }

  // Load JSON data and store in Hive
  static Future<void> loadAndStoreData(String jsonPath) async {
    try {
      // Read JSON file
      final String jsonString = await rootBundle.loadString(jsonPath);
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      // Get the box
      final box = Hive.box<MenuCard>(_boxName);
      await box.clear(); // Clear existing data

      // Process the JSON data and store in Hive
      // Note: You'll need to adjust this part based on your JSON structure
      if (jsonData.containsKey('menuItems')) {
        final List<dynamic> items = jsonData['menuItems'];
        for (var item in items) {
          final menuCard = MenuCard(
            title: item['title'] ?? '',
            time: item['time'] ?? '',
            food: item['food'] ?? '',
            beverages: item['beverages'] ?? '',
            imagePath: item['imagePath'] ?? '',
            isFavorite: item['isFavorite'] ?? false,
          );
          await box.add(menuCard);
        }
      }
    } catch (e) {
      print('Error loading JSON data: $e');
      rethrow;
    }
  }

  // Get all menu items from Hive
  static List<MenuCard> getAllMenuItems() {
    final box = Hive.box<MenuCard>(_boxName);
    return box.values.toList();
  }

  // Add new menu item
  static Future<void> addMenuItem(MenuCard menuCard) async {
    final box = Hive.box<MenuCard>(_boxName);
    await box.add(menuCard);
  }

  // Update existing menu item
  static Future<void> updateMenuItem(int index, MenuCard menuCard) async {
    final box = Hive.box<MenuCard>(_boxName);
    await box.putAt(index, menuCard);
  }

  // Delete menu item
  static Future<void> deleteMenuItem(int index) async {
    final box = Hive.box<MenuCard>(_boxName);
    await box.deleteAt(index);
  }
}
