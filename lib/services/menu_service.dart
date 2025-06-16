import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/menu_data.dart';
import 'hive_service.dart';

class MenuService {
  static const String _jsonPath = 'assets/data/menu_data.json';

  // Initialize Hive
  static Future<void> init() async {
    await HiveService.init();
  }

  // Load JSON data and store in Hive (only called on first run)
  static Future<void> loadAndStoreMenuData() async {
    try {
      print('\n=== Loading Menu Data from JSON and Encrypting ===');
      // Read JSON file
      final String jsonString = await rootBundle.loadString(_jsonPath);
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      print('JSON data loaded successfully');

      // Process the JSON data and store in Hive
      if (jsonData.containsKey('menu')) {
        final Map<String, dynamic> menuData = jsonData['menu'];
        print('Found menu data for ${menuData.length} dates');

        // Store each day's menu data in Hive
        for (var entry in menuData.entries) {
          final date = entry.key;
          final meals = entry.value;
          print('\nEncrypting and storing menu data for date: $date');
          print('Meals: ${meals.keys.join(', ')}');

          try {
            // Store in encrypted Hive box
            await HiveService.put('menu_$date', meals);
            print('Successfully stored data for $date');
          } catch (e) {
            print('Error storing data for $date: $e');
            // Continue with next date even if one fails
            continue;
          }
        }

        try {
          // Store the list of all dates
          await HiveService.put('menu_data', menuData.keys.toList());
          print('Successfully stored dates list');
        } catch (e) {
          print('Error storing dates list: $e');
        }

        print('\n=== Menu Data Encrypted and Stored Successfully ===\n');
      } else {
        print('No menu data found in JSON');
      }
    } catch (e, stackTrace) {
      print('Error loading menu data: $e');
      print('Stack trace: $stackTrace');
      print('No menu data available - JSON file not found or invalid');
      // Clear any partial data
      try {
        await HiveService.clear();
      } catch (e) {
        print('Error clearing Hive: $e');
      }
    }
  }

  // Get menu data for a specific date (decrypts from Hive)
  static Future<MenuData?> getMenuDataForDate(String date) async {
    try {
      print('Getting menu data for date: $date');
      final storedData = await HiveService.get('menu_$date');

      if (storedData != null) {
        print('Found data in Hive: $storedData');
        try {
          return MenuData.fromJson(date, storedData);
        } catch (e) {
          print('Error parsing menu data: $e');
          return null;
        }
      } else {
        print('No data found in Hive for date: $date');
        return null;
      }
    } catch (e, stackTrace) {
      print('Error retrieving menu data: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  // Get all dates (decrypts from Hive)
  static Future<List<String>> getAllDates() async {
    try {
      final dates = await HiveService.get('menu_data') as List<dynamic>?;
      return dates?.map((date) => date.toString()).toList() ?? [];
    } catch (e) {
      print('Error retrieving dates: $e');
      return [];
    }
  }

  // Get meal data for a specific date and meal type (decrypts from Hive)
  static Future<MealData?> getMealData(String date, String mealType) async {
    try {
      final menuData = await getMenuDataForDate(date);
      if (menuData != null) {
        return menuData.meals[mealType.toLowerCase()];
      }
      return null;
    } catch (e) {
      print('Error retrieving meal data: $e');
      return null;
    }
  }

  // Update favorite status for a meal (updates encrypted data)
  static Future<void> updateFavoriteStatus(
      String date, String mealType, bool isFavorite) async {
    try {
      final menuData = await getMenuDataForDate(date);
      if (menuData != null) {
        final meal = menuData.meals[mealType.toLowerCase()];
        if (meal != null) {
          meal.isFavorite = isFavorite;
          await HiveService.put('menu_$date', menuData.toJson());
        }
      }
    } catch (e) {
      print('Error updating favorite status: $e');
    }
  }

  // Get all favorite meals (decrypts from Hive)
  static Future<List<MealData>> getFavoriteMeals() async {
    List<MealData> favorites = [];
    try {
      final dates = await getAllDates();
      for (var date in dates) {
        final menuData = await getMenuDataForDate(date);
        if (menuData != null) {
          menuData.meals.values.forEach((meal) {
            if (meal.isFavorite) {
              favorites.add(meal);
            }
          });
        }
      }
      return favorites;
    } catch (e) {
      print('Error retrieving favorite meals: $e');
      return [];
    }
  }

  // Check if menu data exists in Hive
  static Future<bool> hasMenuData() async {
    try {
      final dates = await getAllDates();
      return dates.isNotEmpty;
    } catch (e) {
      print('Error checking menu data: $e');
      return false;
    }
  }

  // Clear all menu data
  static Future<void> clear() async {
    try {
      await HiveService.clear();
      print('Cleared all menu data');
    } catch (e) {
      print('Error clearing menu data: $e');
    }
  }
}
