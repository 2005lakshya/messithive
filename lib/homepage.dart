import 'package:flutter/material.dart';
import 'services/hive_service.dart';
import 'models/menu_card.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';

class MealTimeCard extends StatefulWidget {
  final String title;
  final String time;
  final String food;
  final String beverages;
  final String imagePath;
  final double imageWidth;
  final double imageHeight;
  final double bottomOffset;

  const MealTimeCard({
    super.key,
    required this.title,
    required this.time,
    required this.food,
    required this.beverages,
    required this.imagePath,
    this.imageWidth = 150,
    this.imageHeight = 150,
    this.bottomOffset = 0,
  });

  @override
  State<MealTimeCard> createState() => _MealTimeCardState();
}

class _MealTimeCardState extends State<MealTimeCard> {
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    final savedCard = HiveService.getMenuCard(widget.title);
    if (savedCard != null) {
      setState(() {
        isFavorite = savedCard.isFavorite;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    setState(() {
      isFavorite = !isFavorite;
    });

    final menuCard = MenuCard(
      title: widget.title,
      time: widget.time,
      food: widget.food,
      beverages: widget.beverages,
      imagePath: widget.imagePath,
      isFavorite: isFavorite,
    );

    if (isFavorite) {
      await HiveService.saveMenuCard(menuCard);
      // Show saved message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.title} saved to favorites'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      await HiveService.deleteMenuCard(widget.title);
      // Show deleted message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.title} removed from favorites'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    // Print debug information
    print('Current saved menus:');
    final allCards = HiveService.getAllMenuCards();
    for (var card in allCards) {
      print(
          '- ${card.title}: ${card.isFavorite ? 'Favorite' : 'Not Favorite'}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 15, left: 10, right: 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.only(
              left: 15,
              top: 15,
              bottom: 15,
              right: 100,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.time,
                  style: const TextStyle(color: Colors.white70, fontSize: 17),
                ),
                const SizedBox(height: 5),
                Text(
                  'Food : ${widget.food}',
                  style: const TextStyle(color: Colors.white, fontSize: 17),
                ),
                Text(
                  'Beverages : ${widget.beverages}',
                  style: const TextStyle(color: Colors.white, fontSize: 17),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: widget.bottomOffset,
            right: 0,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(45),
                    bottomLeft: Radius.circular(45),
                  ),
                  child: Image.asset(
                    widget.imagePath,
                    width: widget.imageWidth,
                    height: widget.imageHeight,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading image: $error');
                      return Container(
                        width: widget.imageWidth,
                        height: widget.imageHeight,
                        color: Colors.grey[300],
                        child: const Icon(Icons.error, color: Colors.red),
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: widget.title == 'Dinner' ? 30 : 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: _toggleFavorite,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.yellow,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.black,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? selectedMessType = 'Special Mess';
  String? selectedMessType2 = 'Special Mess';
  final List<String> messTypes = ['Special Mess', 'Veg Mess', 'Non-Veg Mess'];
  Map<String, dynamic>? menuData;
  String currentDate = '2025-06-13'; // Default date

  @override
  void initState() {
    super.initState();
    _loadMenuData();
  }

  Future<void> _loadMenuData() async {
    try {
      // First try to get from Hive
      final storedData = await HiveService.get('menu_data');
      if (storedData != null) {
        setState(() {
          menuData = Map<String, dynamic>.from(storedData);
        });
        print('Loaded menu data from Hive storage');
        print('Current date: $currentDate');
        print('Available dates: ${menuData!.keys.toList()}');

        // Verify we have data for the current date
        if (!menuData!.containsKey(currentDate)) {
          print('No menu data for current date, loading from JSON...');
          await _loadFromJson();
        }
        return;
      }

      // If not in Hive, load from JSON
      await _loadFromJson();
    } catch (e) {
      print('Error in _loadMenuData: $e');
      setState(() {
        menuData = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Error loading menu data. Please check storage and try again.'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _loadFromJson() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/menu_data.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      setState(() {
        menuData = data['menu'];
      });
      // Store in Hive for future use
      await HiveService.put('menu_data', data['menu']);
      print('Loaded menu data from JSON and stored in Hive');
      print('Current date: $currentDate');
      print('Available dates: ${menuData!.keys.toList()}');
    } catch (e) {
      print('Error loading JSON file: $e');
      setState(() {
        menuData = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('No mess menu available. Please add menu_data.json file.'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Define meal timings
  final Map<String, Map<String, dynamic>> mealTimings = {
    'Breakfast': {
      'start': const TimeOfDay(hour: 7, minute: 30),
      'end': const TimeOfDay(hour: 9, minute: 30),
      'food': 'Paneer Puffs',
      'beverages': 'Milk, Tea, Coffee',
      'image': 'assets/breakfast.png',
    },
    'Lunch': {
      'start': const TimeOfDay(hour: 12, minute: 30),
      'end': const TimeOfDay(hour: 14, minute: 30),
      'food': 'Paneer Puffs',
      'beverages': 'Milk, Tea, Coffee',
      'image': 'assets/lunch.png',
    },
    'Snacks': {
      'start': const TimeOfDay(hour: 16, minute: 30),
      'end': const TimeOfDay(hour: 18, minute: 00),
      'food': 'Paneer Puffs',
      'beverages': 'Milk, Tea, Coffee',
      'image': 'assets/snacks.png',
    },
    'Dinner': {
      'start': const TimeOfDay(hour: 19, minute: 30),
      'end': const TimeOfDay(hour: 21, minute: 0),
      'food': 'Paneer Puffs',
      'beverages': 'Milk, Tea, Coffee',
      'image': 'assets/dinner.png',
    },
  };

  String? getCurrentMeal() {
    final now = TimeOfDay.now();

    for (var entry in mealTimings.entries) {
      final start = entry.value['start'] as TimeOfDay;
      final end = entry.value['end'] as TimeOfDay;

      if (_isTimeBetween(now, start, end)) {
        return entry.key;
      }
    }
    return null;
  }

  bool _isTimeBetween(TimeOfDay time, TimeOfDay start, TimeOfDay end) {
    final now = time.hour * 60 + time.minute;
    final startTime = start.hour * 60 + start.minute;
    final endTime = end.hour * 60 + end.minute;

    return now >= startTime && now <= endTime;
  }

  String getTimeRange(String meal) {
    final timing = mealTimings[meal];
    if (timing == null) return '';

    final start = timing['start'] as TimeOfDay;
    final end = timing['end'] as TimeOfDay;

    return '${_formatTimeOfDay(start)} to ${_formatTimeOfDay(end)}';
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  void _checkSavedMenus() {
    final allCards = HiveService.getAllMenuCards();
    if (allCards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No saved menus found'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Saved Menus'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: allCards
                  .map((card) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                            '${card.title} - ${card.food} (Favorite: ${card.isFavorite})'),
                      ))
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMeal = getCurrentMeal();

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/messitbg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 50,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: Menu + Avatars + Test Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Menu icon with dropdown
                          PopupMenuButton<String>(
                            offset: const Offset(0, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _bar(20),
                                const SizedBox(height: 4),
                                _bar(40),
                                const SizedBox(height: 4),
                                Padding(
                                  padding: const EdgeInsets.only(left: 20),
                                  child: _bar(20),
                                ),
                              ],
                            ),
                            color: Colors.black.withOpacity(0.8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            itemBuilder: (BuildContext context) =>
                                <PopupMenuEntry<String>>[
                              PopupMenuItem<String>(
                                value: 'reset',
                                child: Row(
                                  children: const [
                                    Icon(
                                      Icons.restaurant,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Reset Storage',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'favorite',
                                child: Row(
                                  children: const [
                                    Icon(
                                      Icons.favorite,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Favorite',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'storage',
                                child: Row(
                                  children: const [
                                    Icon(
                                      Icons.storage,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Show Storage Location',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'check_storage',
                                child: Row(
                                  children: const [
                                    Icon(
                                      Icons.folder_open,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Check Storage Contents',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'view_menu_data',
                                child: Row(
                                  children: const [
                                    Icon(
                                      Icons.menu_book,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'View Stored Menu Data',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'test_monthly',
                                child: Row(
                                  children: [
                                    const Icon(Icons.timer, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    const Text('Test Monthly Operations'),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'test_performance',
                                child: Row(
                                  children: [
                                    const Icon(Icons.speed,
                                        color: Colors.green),
                                    const SizedBox(width: 8),
                                    const Text('Test Data Fetch Performance'),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (String value) async {
                              if (value == 'reset') {
                                // Clear Hive storage
                                await HiveService.clear();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Storage cleared. Restart app to reload from JSON.'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } else if (value == 'test_performance') {
                                // Show loading dialog
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );

                                // Run performance test
                                await HiveService.testDataFetchPerformance();

                                // Close loading dialog
                                if (mounted) {
                                  Navigator.pop(context);

                                  // Show results dialog
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text(
                                          'Performance Test Results'),
                                      content: SingleChildScrollView(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: const [
                                            Text(
                                              'Check the console for detailed performance metrics.\n\n'
                                              'The test measures:\n'
                                              '1. Single menu card fetch time\n'
                                              '2. All menu cards fetch time\n'
                                              '3. Specific date menu fetch time\n'
                                              '4. Monthly data fetch time\n'
                                              '5. Complete fetch cycle time\n\n'
                                              'Open the debug console to see the results.',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Close'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              } else if (value == 'favorite') {
                                // Handle favorite option
                              } else if (value == 'storage') {
                                final appDir =
                                    await getApplicationDocumentsDirectory();
                                if (mounted) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title:
                                          const Text('Hive Storage Location'),
                                      content: SingleChildScrollView(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                                'Your Hive database is stored at:'),
                                            const SizedBox(height: 8),
                                            SelectableText(
                                              appDir.path,
                                              style: const TextStyle(
                                                color: Colors.blue,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Close'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              } else if (value == 'check_storage') {
                                final location =
                                    await HiveService.getStorageLocation();
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Storage Location'),
                                    content: Text(location),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                                HiveService.checkStorage();
                              } else if (value == 'view_menu_data') {
                                _checkSavedMenus();
                              } else if (value == 'test_monthly') {
                                await HiveService.testMonthlyOperations();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Monthly operations test completed. Check console for timing details.'),
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                          // Test Button (for checking saved menus)
                          IconButton(
                            onPressed: _checkSavedMenus,
                            icon: const Icon(
                              Icons.favorite,
                              color: Colors.white,
                            ),
                            tooltip: 'Check Saved Menus',
                          ),
                          // Avatars
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.yellow,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.yellow,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Texts
                      Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Center(
                          child: Text(
                            currentMeal != null
                                ? "Good ${_getGreeting()}!"
                                : "Mess is Closed!",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Center(
                          child: Text(
                            currentMeal != null
                                ? "It's ${currentMeal} Time"
                                : "Come back later",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      // First Mess Type Dropdown
                      _buildMessTypeDropdown(
                        selectedMessType,
                        (value) => setState(() => selectedMessType = value),
                        "Currently Serving in ",
                      ),

                      // Current Meal Card
                      if (currentMeal != null)
                        MealTimeCard(
                          title: currentMeal,
                          time: getTimeRange(currentMeal),
                          food: mealTimings[currentMeal]!['food'] as String,
                          beverages:
                              mealTimings[currentMeal]!['beverages'] as String,
                          imagePath:
                              mealTimings[currentMeal]!['image'] as String,
                          imageWidth: currentMeal == 'Lunch' ? 120 : 150,
                          imageHeight: currentMeal == 'Lunch' ? 120 : 150,
                          bottomOffset: currentMeal == 'Dinner' ? -20 : 0,
                        ),

                      // Second Mess Type Dropdown
                      _buildMessTypeDropdown(
                        selectedMessType2,
                        (value) => setState(() => selectedMessType2 = value),
                        "Today's Menu for ",
                      ),

                      // Display selected date
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Menu for ${currentDate}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ),

                      // Selected Date's Menu Cards
                      if (menuData != null &&
                          menuData!.containsKey(currentDate))
                        ...menuData![currentDate].entries.map((entry) {
                          final mealType = entry.key;
                          final mealData = entry.value;
                          return MealTimeCard(
                            title: mealData['title'],
                            time: mealData['time'],
                            food: mealData['food'],
                            beverages: mealData['beverages'],
                            imagePath: mealData['imagePath'],
                            imageWidth: mealType == 'lunch' ? 120 : 150,
                            imageHeight: mealType == 'lunch' ? 120 : 150,
                            bottomOffset: mealType == 'dinner' ? -20 : 0,
                          );
                        }).toList()
                      else
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              'No menu available for selected date',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = TimeOfDay.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    if (hour < 21) return 'Evening';
    return 'Night';
  }

  Widget _buildMessTypeDropdown(
    String? selectedValue,
    Function(String?) onChanged,
    String prefixText,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              prefixText,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            PopupMenuButton<String>(
              initialValue: selectedValue,
              onSelected: onChanged,
              child: Row(
                children: [
                  Text(
                    selectedValue ?? 'Special Mess',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white,
                      decorationThickness: 2,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 30,
                  ),
                ],
              ),
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                _buildPopupMenuItem(
                  'Special Mess',
                  Colors.orange,
                  selectedValue,
                ),
                _buildPopupMenuItem(
                  'Non Veg Mess',
                  Colors.red,
                  selectedValue,
                ),
                _buildPopupMenuItem(
                  'Veg Mess',
                  Colors.green,
                  selectedValue,
                ),
              ],
              color: Colors.black.withOpacity(0.8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                  size: 18,
                ),
                onPressed: () {
                  _showCalendarDialog(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCalendarDialog(BuildContext context) {
    DateTime _selectedDay = DateTime.now();
    DateTime _focusedDay = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2024, 1, 1),
                lastDay: DateTime.utc(2025, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    currentDate =
                        "${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}";
                  });
                  print('Selected date: $currentDate');
                  Navigator.pop(context);
                  _loadMenuData(); // Reload menu data for selected date
                },
                calendarStyle: CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: Colors.yellow,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.yellow.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  outsideDaysVisible: false,
                  defaultTextStyle: const TextStyle(color: Colors.white),
                  weekendTextStyle: const TextStyle(color: Colors.red),
                  holidayTextStyle: const TextStyle(color: Colors.white),
                  outsideTextStyle: const TextStyle(color: Colors.white70),
                  disabledTextStyle: const TextStyle(color: Colors.white38),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  leftChevronIcon:
                      const Icon(Icons.chevron_left, color: Colors.white),
                  rightChevronIcon:
                      const Icon(Icons.chevron_right, color: Colors.white),
                ),
                calendarBuilders: CalendarBuilders(
                  dowBuilder: (context, day) {
                    if (day.weekday == DateTime.sunday) {
                      return Center(
                        child: Text(
                          'S',
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
    String value,
    Color color,
    String? selectedValue,
  ) {
    return PopupMenuItem<String>(
      value: value,
      padding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        color: selectedValue == value ? color : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(value, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _bar(double width) {
    return Container(
      width: width,
      height: 3,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
