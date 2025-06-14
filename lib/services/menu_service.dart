import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/menu_data.dart';

class MenuService {
  static const String _boxName = 'menuData';
  static const String _jsonPath = 'assets/data/menu_data.json';

  // Initialize Hive box
  static Future<void> init() async {
    await Hive.openBox<MenuData>(_boxName);
  }

  // Load JSON data and store in Hive
  static Future<void> loadAndStoreMenuData() async {
    try {
      // Read JSON file
      final String jsonString = await rootBundle.loadString(_jsonPath);
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      // Get the box
      final box = Hive.box<MenuData>(_boxName);
      await box.clear(); // Clear existing data

      // Process the JSON data and store in Hive
      if (jsonData.containsKey('menu')) {
        final Map<String, dynamic> menuData = jsonData['menu'];
        menuData.forEach((date, meals) {
          final menuData = MenuData.fromJson(date, meals);
          box.put(date, menuData);
        });
        print('Successfully loaded and stored menu data from JSON');
      }
    } catch (e) {
      print('Error loading menu data: $e');
      // Clear any existing data when JSON is not available
      final box = Hive.box<MenuData>(_boxName);
      await box.clear();
      print('No menu data available - JSON file not found');
    }
  }

  // Get menu data for a specific date
  static MenuData? getMenuDataForDate(String date) {
    final box = Hive.box<MenuData>(_boxName);
    return box.get(date);
  }

  // Get all dates
  static List<String> getAllDates() {
    final box = Hive.box<MenuData>(_boxName);
    return box.keys.map((key) => key.toString()).toList();
  }

  // Get meal data for a specific date and meal type
  static MealData? getMealData(String date, String mealType) {
    final menuData = getMenuDataForDate(date);
    return menuData?.meals[mealType];
  }

  // Update favorite status for a meal
  static Future<void> updateFavoriteStatus(
      String date, String mealType, bool isFavorite) async {
    final menuData = getMenuDataForDate(date);
    if (menuData != null) {
      final meal = menuData.meals[mealType];
      if (meal != null) {
        meal.isFavorite = isFavorite;
        final box = Hive.box<MenuData>(_boxName);
        await box.put(date, menuData);
      }
    }
  }

  // Get all favorite meals
  static List<MealData> getFavoriteMeals() {
    final box = Hive.box<MenuData>(_boxName);
    List<MealData> favorites = [];

    box.values.forEach((menuData) {
      menuData.meals.values.forEach((meal) {
        if (meal.isFavorite) {
          favorites.add(meal);
        }
      });
    });

    return favorites;
  }
}
