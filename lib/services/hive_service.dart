import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/menu_card.dart';
import '../models/menu_data.dart';
import 'package:flutter/services.dart';

class HiveService {
  static const String _boxName = 'encryptedBox';
  static const String _keyBoxName = 'keyBox';
  static const String _menuBoxName = 'menuBox';
  static Box? _encryptedBox;
  static Box? _keyBox;
  static Box<MenuCard>? _menuBox;
  static List<int>? _encryptionKey;

  static Future<void> init() async {
    final stopwatch = Stopwatch()..start();

    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(MenuCardAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(MenuDataAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(MealDataAdapter());
    }

    // Open encrypted box
    _encryptedBox = await Hive.openBox('encryptedBox');

    // Open menu box
    _menuBox = await Hive.openBox<MenuCard>('menuBox');

    stopwatch.stop();
    print('Hive initialization time: ${stopwatch.elapsedMilliseconds}ms');

    // Print storage location
    final appDir = await getApplicationDocumentsDirectory();
    print('Hive Storage Location: ${appDir.path}');

    // Open the key box first
    _keyBox = await Hive.openBox(_keyBoxName);

    // Try to get existing key
    _encryptionKey = _keyBox!.get('encryptionKey');

    // Generate new key if none exists
    if (_encryptionKey == null) {
      _encryptionKey = Hive.generateSecureKey();
      await _keyBox!.put('encryptionKey', _encryptionKey);
    }
  }

  // Menu Card specific methods
  static Future<void> saveMenuCard(MenuCard menuCard) async {
    if (_menuBox == null) {
      print('Error: Menu box not initialized');
      return;
    }

    final stopwatch = Stopwatch()..start();
    try {
      await _menuBox!.put(menuCard.title, menuCard);
      stopwatch.stop();
      print(
          'Encryption time for menu card "${menuCard.title}": ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      print('Error encrypting menu card "${menuCard.title}": $e');
    }
  }

  static MenuCard? getMenuCard(String title) {
    if (_menuBox == null) {
      print('Error: Menu box not initialized');
      return null;
    }

    final stopwatch = Stopwatch()..start();
    try {
      final card = _menuBox!.get(title);
      stopwatch.stop();
      print(
          'Decryption time for menu card "$title": ${stopwatch.elapsedMilliseconds}ms');
      return card;
    } catch (e) {
      print('Error decrypting menu card "$title": $e');
      return null;
    }
  }

  static bool isMenuCardSaved(String title) {
    if (_menuBox == null) {
      throw Exception('Hive box not initialized');
    }
    return _menuBox!.containsKey(title);
  }

  static Future<void> deleteMenuCard(String title) async {
    if (_menuBox == null) {
      print('Error: Menu box not initialized');
      return;
    }

    final stopwatch = Stopwatch()..start();
    try {
      await _menuBox!.delete(title);
      stopwatch.stop();
      print(
          'Deletion time for menu card "$title": ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      print('Error deleting menu card "$title": $e');
    }
  }

  static List<MenuCard> getAllMenuCards() {
    if (_menuBox == null) {
      print('Error: Menu box not initialized');
      return [];
    }

    final stopwatch = Stopwatch()..start();
    try {
      final cards = _menuBox!.values.toList();
      stopwatch.stop();
      print(
          'Decryption time for all menu cards: ${stopwatch.elapsedMilliseconds}ms');
      return cards;
    } catch (e) {
      print('Error decrypting all menu cards: $e');
      return [];
    }
  }

  // Generic methods for other data
  static Future<void> put(String key, dynamic value) async {
    if (_encryptedBox == null) {
      print('Error: Encrypted box not initialized');
      return;
    }

    final stopwatch = Stopwatch()..start();
    try {
      await _encryptedBox!.put(key, value);
      stopwatch.stop();
      print(
          'Encryption time for key "$key": ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      print('Error encrypting data for key "$key": $e');
    }
  }

  static Future<dynamic> get(String key) async {
    if (_encryptedBox == null) {
      print('Error: Encrypted box not initialized');
      return null;
    }

    final stopwatch = Stopwatch()..start();
    try {
      final value = _encryptedBox!.get(key);
      stopwatch.stop();
      print(
          'Decryption time for key "$key": ${stopwatch.elapsedMilliseconds}ms');
      return value;
    } catch (e) {
      print('Error decrypting data for key "$key": $e');
      return null;
    }
  }

  static Future<void> delete(String key) async {
    if (_encryptedBox == null) {
      throw Exception('Hive box not initialized');
    }
    await _encryptedBox!.delete(key);
  }

  static Future<void> clear() async {
    final stopwatch = Stopwatch()..start();
    try {
      await _encryptedBox!.clear();
      if (_menuBox != null) {
        await _menuBox!.clear();
      }
      stopwatch.stop();
      print('Clear storage time: ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      print('Error clearing storage: $e');
    }
  }

  static Future<String> getStorageLocation() async {
    final appDir = await getApplicationDocumentsDirectory();
    return appDir.path;
  }

  static bool hasKey(String key) {
    if (_encryptedBox == null) {
      print('Error: Encrypted box not initialized');
      return false;
    }
    return _encryptedBox!.containsKey(key);
  }

  // Method to check storage contents
  static void checkStorage() {
    print('\n=== Hive Storage Contents ===');
    print('Encrypted Box Keys:');
    _encryptedBox?.keys.forEach((key) {
      print('- $key');
    });
    print('\nMenu Box Contents:');
    _menuBox?.values.forEach((card) {
      print('- ${card.title} (Favorite: ${card.isFavorite})');
    });
    print('===========================\n');
  }

  static Future<void> saveMonthlyMenuData(
      Map<String, dynamic> monthlyData) async {
    if (_encryptedBox == null) {
      print('Error: Encrypted box not initialized');
      return;
    }

    final stopwatch = Stopwatch()..start();
    try {
      // Save each day's menu data
      for (var entry in monthlyData.entries) {
        final date = entry.key;
        final menuData = entry.value;
        await _encryptedBox!.put('menu_$date', menuData);
      }
      stopwatch.stop();
      print(
          'Monthly menu data encryption time: ${stopwatch.elapsedMilliseconds}ms');
      print(
          'Average time per day: ${stopwatch.elapsedMilliseconds / monthlyData.length}ms');
    } catch (e) {
      print('Error encrypting monthly menu data: $e');
    }
  }

  static Future<Map<String, dynamic>> getMonthlyMenuData(
      List<String> dates) async {
    if (_encryptedBox == null) {
      print('Error: Encrypted box not initialized');
      return {};
    }

    final stopwatch = Stopwatch()..start();
    final monthlyData = <String, dynamic>{};

    try {
      for (var date in dates) {
        final menuData = _encryptedBox!.get('menu_$date');
        if (menuData != null) {
          monthlyData[date] = menuData;
        }
      }
      stopwatch.stop();
      print(
          'Monthly menu data decryption time: ${stopwatch.elapsedMilliseconds}ms');
      print(
          'Average time per day: ${stopwatch.elapsedMilliseconds / dates.length}ms');
      return monthlyData;
    } catch (e) {
      print('Error decrypting monthly menu data: $e');
      return {};
    }
  }

  static Future<void> clearMonthlyMenuData(List<String> dates) async {
    if (_encryptedBox == null) {
      print('Error: Encrypted box not initialized');
      return;
    }

    final stopwatch = Stopwatch()..start();
    try {
      for (var date in dates) {
        await _encryptedBox!.delete('menu_$date');
      }
      stopwatch.stop();
      print(
          'Monthly menu data deletion time: ${stopwatch.elapsedMilliseconds}ms');
      print(
          'Average time per day: ${stopwatch.elapsedMilliseconds / dates.length}ms');
    } catch (e) {
      print('Error deleting monthly menu data: $e');
    }
  }

  // Helper method to generate dates for a month
  static List<String> generateMonthDates(DateTime month) {
    final dates = <String>[];
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      dates.add(
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}');
    }

    return dates;
  }

  // Method to test monthly data operations
  static Future<void> testMonthlyOperations() async {
    final month = DateTime.now();
    final dates = generateMonthDates(month);

    // Generate sample monthly data
    final monthlyData = <String, dynamic>{};
    for (var date in dates) {
      monthlyData[date] = {
        'breakfast': {'food': 'Sample Breakfast', 'beverage': 'Tea'},
        'lunch': {'food': 'Sample Lunch', 'beverage': 'Water'},
        'snacks': {'food': 'Sample Snacks', 'beverage': 'Juice'},
        'dinner': {'food': 'Sample Dinner', 'beverage': 'Water'},
      };
    }

    print('\n=== Testing Monthly Operations ===');
    print('Number of days: ${dates.length}');

    // Test encryption
    print('\nTesting encryption...');
    await saveMonthlyMenuData(monthlyData);

    // Test decryption
    print('\nTesting decryption...');
    final decryptedData = await getMonthlyMenuData(dates);
    print('Decrypted ${decryptedData.length} days of data');

    // Test deletion
    print('\nTesting deletion...');
    await clearMonthlyMenuData(dates);

    print('\n=== Monthly Operations Complete ===\n');
  }

  // Method to test data fetching and decryption performance
  static Future<void> testDataFetchPerformance() async {
    print('\n=== Testing Data Fetch Performance ===');

    // First, ensure we have proper menu data
    print('\nVerifying Menu Data...');
    final storedData = await get('menu_data');
    if (storedData == null ||
        storedData is Map && storedData.containsKey('test')) {
      print('Loading menu data from JSON...');
      try {
        final String jsonString =
            await rootBundle.loadString('assets/data/menu_data.json');
        final Map<String, dynamic> data = json.decode(jsonString);
        await put('menu_data', data['menu']);
        print('Menu data loaded from JSON and stored in Hive');
        print('Available dates: ${data['menu'].keys.toList()}');
      } catch (e) {
        print('Error loading menu data: $e');
      }
    } else {
      print('Menu data already in Hive');
      print('Available dates: ${storedData.keys.toList()}');
    }

    // Test 1: Single menu card fetch
    print('\nTest 1: Single Menu Card Fetch');
    final stopwatch1 = Stopwatch()..start();
    final testCard = getMenuCard('Breakfast');
    stopwatch1.stop();
    print('Data source: ${testCard != null ? 'Hive' : 'Not found in Hive'}');
    print(
        'Time to fetch single menu card: ${stopwatch1.elapsedMilliseconds}ms');

    // Test 2: Fetch all menu cards
    print('\nTest 2: Fetch All Menu Cards');
    final stopwatch2 = Stopwatch()..start();
    final allCards = getAllMenuCards();
    stopwatch2.stop();
    print('Data source: ${allCards.isNotEmpty ? 'Hive' : 'Not found in Hive'}');
    print('Time to fetch all menu cards: ${stopwatch2.elapsedMilliseconds}ms');
    print('Number of cards fetched: ${allCards.length}');
    print(
        'Average time per card: ${stopwatch2.elapsedMilliseconds / (allCards.length > 0 ? allCards.length : 1)}ms');

    // Test 3: Fetch menu data for a specific date
    print('\nTest 3: Fetch Menu Data for Specific Date');
    final stopwatch3 = Stopwatch()..start();
    final menuData = await get('menu_data');
    stopwatch3.stop();
    print('Data source: ${menuData != null ? 'Hive' : 'Not found in Hive'}');
    print('Time to fetch menu data: ${stopwatch3.elapsedMilliseconds}ms');
    if (menuData != null) {
      print('Menu data structure:');
      print('- Keys: ${menuData.keys.toList()}');
      if (menuData is Map && menuData.isNotEmpty) {
        final firstDate = menuData.keys.first;
        print('- Sample data for $firstDate:');
        print(menuData[firstDate]);
      }
    }

    // Test 4: Fetch and decrypt monthly data
    print('\nTest 4: Fetch Monthly Data');
    final currentMonth = DateTime.now();
    final dates = generateMonthDates(currentMonth);
    final stopwatch4 = Stopwatch()..start();
    final monthlyData = await getMonthlyMenuData(dates);
    stopwatch4.stop();
    print(
        'Data source: ${monthlyData.isNotEmpty ? 'Hive' : 'Not found in Hive'}');
    print('Time to fetch monthly data: ${stopwatch4.elapsedMilliseconds}ms');
    print('Number of days fetched: ${dates.length}');
    print(
        'Average time per day: ${stopwatch4.elapsedMilliseconds / dates.length}ms');

    // Test 5: Complete data fetch cycle
    print('\nTest 5: Complete Data Fetch Cycle');
    final stopwatch5 = Stopwatch()..start();
    try {
      final storedData = await get('menu_data');
      if (storedData == null) {
        print('Data not found in Hive, loading from JSON...');
        final String jsonString =
            await rootBundle.loadString('assets/data/menu_data.json');
        final Map<String, dynamic> data = json.decode(jsonString);
        await put('menu_data', data['menu']);
        print('Data loaded from JSON and stored in Hive');
        print('Available dates: ${data['menu'].keys.toList()}');
      } else {
        print('Data loaded from Hive');
        print('Available dates: ${storedData.keys.toList()}');
      }
    } catch (e) {
      print('Error in complete fetch cycle: $e');
    }
    stopwatch5.stop();
    print('Time for complete fetch cycle: ${stopwatch5.elapsedMilliseconds}ms');

    print('\n=== Performance Test Complete ===\n');
  }
}
