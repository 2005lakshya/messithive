import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/menu_card.dart';

class HiveService {
  static const String _boxName = 'encryptedBox';
  static const String _keyBoxName = 'keyBox';
  static const String _menuBoxName = 'menuBox';
  static Box? _encryptedBox;
  static Box? _keyBox;
  static Box<MenuCard>? _menuBox;
  static List<int>? _encryptionKey;

  static Future<void> init() async {
    await Hive.initFlutter();

    // Print storage location
    final appDir = await getApplicationDocumentsDirectory();
    print('Hive Storage Location: ${appDir.path}');

    // Register the MenuCard adapter
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(MenuCardAdapter());
    }

    // Open the key box first
    _keyBox = await Hive.openBox(_keyBoxName);

    // Try to get existing key
    _encryptionKey = _keyBox!.get('encryptionKey');

    // Generate new key if none exists
    if (_encryptionKey == null) {
      _encryptionKey = Hive.generateSecureKey();
      await _keyBox!.put('encryptionKey', _encryptionKey);
    }

    // Open encrypted box
    _encryptedBox = await Hive.openBox(
      _boxName,
      encryptionCipher: HiveAesCipher(_encryptionKey!),
    );

    // Open menu box
    _menuBox = await Hive.openBox<MenuCard>(_menuBoxName);
  }

  // Menu Card specific methods
  static Future<void> saveMenuCard(MenuCard menuCard) async {
    if (_menuBox == null) {
      throw Exception('Hive box not initialized');
    }
    await _menuBox!.put(menuCard.title, menuCard);
  }

  static MenuCard? getMenuCard(String title) {
    if (_menuBox == null) {
      throw Exception('Hive box not initialized');
    }
    return _menuBox!.get(title);
  }

  static bool isMenuCardSaved(String title) {
    if (_menuBox == null) {
      throw Exception('Hive box not initialized');
    }
    return _menuBox!.containsKey(title);
  }

  static Future<void> deleteMenuCard(String title) async {
    if (_menuBox == null) {
      throw Exception('Hive box not initialized');
    }
    await _menuBox!.delete(title);
  }

  static List<MenuCard> getAllMenuCards() {
    if (_menuBox == null) {
      throw Exception('Hive box not initialized');
    }
    return _menuBox!.values.toList();
  }

  // Generic methods for other data
  static Future<void> put(String key, dynamic value) async {
    if (_encryptedBox == null) {
      throw Exception('Hive box not initialized');
    }
    await _encryptedBox!.put(key, value);
  }

  static dynamic get(String key) {
    if (_encryptedBox == null) {
      throw Exception('Hive box not initialized');
    }
    return _encryptedBox!.get(key);
  }

  static Future<void> delete(String key) async {
    if (_encryptedBox == null) {
      throw Exception('Hive box not initialized');
    }
    await _encryptedBox!.delete(key);
  }

  static Future<void> clear() async {
    if (_encryptedBox == null) {
      throw Exception('Hive box not initialized');
    }
    await _encryptedBox!.clear();
  }

  static bool hasKey(String key) {
    if (_encryptedBox == null) {
      throw Exception('Hive box not initialized');
    }
    return _encryptedBox!.containsKey(key);
  }
}
