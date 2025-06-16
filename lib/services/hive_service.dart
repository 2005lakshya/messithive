import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/menu_card.dart';
import '../models/menu_data.dart';
import 'package:flutter/services.dart';

class HiveService {
  static const String _boxName = 'encryptedBox';
  static const String _menuBoxName = 'menuBox';
  static const String _keyFileName = 'hive_key.bin';

  static Box? _encryptedBox;
  static Box<MenuCard>? _menuBox;
  static List<int>? _encryptionKey;
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;

    final stopwatch = Stopwatch()..start();

    try {
      await Hive.initFlutter();
      print('Hive initialized');

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
      print('Adapters registered');

      // Load or generate encryption key from file
      final appDir = await getApplicationDocumentsDirectory();
      final keyFile = File('${appDir.path}/$_keyFileName');

      if (await keyFile.exists()) {
        _encryptionKey = await keyFile.readAsBytes();
        print('Loaded existing encryption key');
      } else {
        _encryptionKey = Hive.generateSecureKey();
        await keyFile.writeAsBytes(_encryptionKey!);
        print('Generated new encryption key');
      }

      // Close existing boxes if they're open
      if (Hive.isBoxOpen(_boxName)) {
        await Hive.box(_boxName).close();
      }
      if (Hive.isBoxOpen(_menuBoxName)) {
        await Hive.box(_menuBoxName).close();
      }

      // Open boxes with encryption
      _encryptedBox = await Hive.openBox(
        _boxName,
        encryptionCipher: HiveAesCipher(_encryptionKey!),
      );
      print('Opened encrypted box: $_boxName');

      _menuBox = await Hive.openBox<MenuCard>(
        _menuBoxName,
        encryptionCipher: HiveAesCipher(_encryptionKey!),
      );
      print('Opened encrypted box: $_menuBoxName');

      _isInitialized = true;
      stopwatch.stop();
      print('Hive initialization time: ${stopwatch.elapsedMilliseconds}ms');
    } catch (e, stackTrace) {
      print('Error initializing Hive: $e');
      print('Stack trace: $stackTrace');
      // Reset initialization state
      _isInitialized = false;
      _encryptedBox = null;
      _menuBox = null;
      rethrow;
    }
  }

  static Future<void> put(String key, dynamic value) async {
    if (!_isInitialized) await init();
    if (_encryptedBox == null) {
      print('Error: Encrypted box is null');
      return;
    }

    try {
      final jsonString = json.encode(value);
      await _encryptedBox!.put(key, jsonString);
      print('Encrypted and stored data for key: $key');
    } catch (e, stackTrace) {
      print('Error saving "$key": $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<dynamic> get(String key) async {
    if (!_isInitialized) await init();
    if (_encryptedBox == null) {
      print('Error: Encrypted box is null');
      return null;
    }

    try {
      final encryptedValue = _encryptedBox!.get(key);
      if (encryptedValue == null) {
        print('No data found for key: $key');
        return null;
      }
      final decryptedValue = json.decode(encryptedValue as String);
      print('Decrypted data for key: $key');
      return decryptedValue;
    } catch (e, stackTrace) {
      print('Error loading "$key": $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  static Future<void> delete(String key) async {
    if (!_isInitialized) await init();
    if (_encryptedBox == null) return;
    await _encryptedBox!.delete(key);
    print('Deleted encrypted data for key: $key');
  }

  static Future<void> clear() async {
    if (!_isInitialized) await init();
    try {
      await _encryptedBox?.clear();
      await _menuBox?.clear();
      print('Cleared all encrypted data');
    } catch (e) {
      print('Error clearing Hive: $e');
    }
  }

  static Future<String> getStorageLocation() async {
    final appDir = await getApplicationDocumentsDirectory();
    return appDir.path;
  }

  static bool hasKey(String key) {
    if (!_isInitialized) return false;
    if (_encryptedBox == null) return false;
    return _encryptedBox!.containsKey(key);
  }

  static void checkStorage() {
    if (!_isInitialized) return;
    print('\n=== Hive Storage Check ===');
    print('Encrypted Box Keys:');
    _encryptedBox?.keys.forEach((key) => print('- $key'));
    print('Menu Box Entries:');
    _menuBox?.values.forEach((card) => print('- ${card.title}'));
    print('===========================');
  }

  // Menu Card specific methods
  static Future<void> saveMenuCard(MenuCard menuCard) async {
    if (!_isInitialized) await init();
    if (_menuBox == null) return;

    try {
      await _menuBox!.put(menuCard.title, menuCard);
      print('Encrypted and stored menu card: ${menuCard.title}');
    } catch (e) {
      print('Error saving "${menuCard.title}": $e');
    }
  }

  static MenuCard? getMenuCard(String title) {
    if (!_isInitialized) return null;
    if (_menuBox == null) return null;

    try {
      final card = _menuBox!.get(title);
      if (card != null) {
        print('Decrypted menu card: $title');
      }
      return card;
    } catch (e) {
      print('Error getting "$title": $e');
      return null;
    }
  }

  static bool isMenuCardSaved(String title) {
    if (!_isInitialized) return false;
    if (_menuBox == null) return false;
    return _menuBox!.containsKey(title);
  }

  static Future<void> deleteMenuCard(String title) async {
    if (!_isInitialized) await init();
    if (_menuBox == null) return;

    try {
      await _menuBox!.delete(title);
      print('Deleted encrypted menu card: $title');
    } catch (e) {
      print('Error deleting "$title": $e');
    }
  }

  static List<MenuCard> getAllMenuCards() {
    if (!_isInitialized) return [];
    if (_menuBox == null) return [];

    try {
      final cards = _menuBox!.values.toList();
      print('Decrypted ${cards.length} menu cards');
      return cards;
    } catch (e) {
      print('Error fetching cards: $e');
      return [];
    }
  }

  static Future<void> saveMonthlyMenuData(
      Map<String, dynamic> monthlyData) async {
    if (_encryptedBox == null) return;
    final stopwatch = Stopwatch()..start();
    try {
      for (var entry in monthlyData.entries) {
        await _encryptedBox!.put('menu_${entry.key}', entry.value);
      }
      stopwatch.stop();
      print('Saved monthly menu in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      print('Error saving monthly menu: $e');
    }
  }

  static Future<Map<String, dynamic>> getMonthlyMenuData(
      List<String> dates) async {
    if (_encryptedBox == null) return {};
    final stopwatch = Stopwatch()..start();
    final monthlyData = <String, dynamic>{};
    try {
      for (var date in dates) {
        final data = _encryptedBox!.get('menu_$date');
        if (data != null) {
          monthlyData[date] = data;
        }
      }
      stopwatch.stop();
      print('Loaded monthly menu in ${stopwatch.elapsedMilliseconds}ms');
      return monthlyData;
    } catch (e) {
      print('Error loading monthly menu: $e');
      return {};
    }
  }

  static Future<void> clearMonthlyMenuData(List<String> dates) async {
    if (_encryptedBox == null) return;
    final stopwatch = Stopwatch()..start();
    try {
      for (var date in dates) {
        await _encryptedBox!.delete('menu_$date');
      }
      stopwatch.stop();
      print('Deleted monthly menu in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      print('Error deleting monthly menu: $e');
    }
  }

  static List<String> generateMonthDates(DateTime month) {
    final dates = <String>[];
    final days = DateTime(month.year, month.month + 1, 0).day;
    for (var day = 1; day <= days; day++) {
      final date = DateTime(month.year, month.month, day);
      dates.add(
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}');
    }
    return dates;
  }

  static Future<void> testMonthlyOperations() async {
    final month = DateTime.now();
    final dates = generateMonthDates(month);
    final testData = {
      for (var date in dates)
        date: {
          'breakfast': {'food': 'Eggs', 'drink': 'Tea'},
          'lunch': {'food': 'Rice', 'drink': 'Water'},
          'dinner': {'food': 'Soup', 'drink': 'Juice'},
        }
    };

    print('\n--- Monthly Menu Test ---');
    await saveMonthlyMenuData(testData);
    final result = await getMonthlyMenuData(dates);
    print('Fetched: ${result.length} days');
    await clearMonthlyMenuData(dates);
  }
}
