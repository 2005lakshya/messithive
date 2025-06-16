import 'package:flutter/material.dart';
import 'services/menu_service.dart';
import 'models/menu_card.dart';
import 'models/menu_data.dart';
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
    final currentDate = DateTime.now().toString().split(' ')[0];
    final savedCard = await MenuService.getMealData(currentDate, widget.title);
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

    final currentDate = DateTime.now().toString().split(' ')[0];
    final menuCard = MenuCard(
      title: widget.title,
      time: widget.time,
      food: widget.food,
      beverages: widget.beverages,
      imagePath: widget.imagePath,
      isFavorite: isFavorite,
    );

    if (isFavorite) {
      await MenuService.updateFavoriteStatus(
          currentDate, widget.title, isFavorite);
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
      await MenuService.updateFavoriteStatus(
          currentDate, widget.title, isFavorite);
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
    final allCards = await MenuService.getFavoriteMeals();
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
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? selectedMessType = 'Special Mess';
  String? selectedMessType2 = 'Special Mess';
  final List<String> messTypes = ['Special Mess', 'Veg Mess', 'Non-Veg Mess'];
  MenuData? _menuData;
  String currentDate =
      DateTime.now().toString().split(' ')[0]; // Default to today
  String selectedHostel = 'Mens Hostel'; // Default hostel
  String todayDate = DateTime.now().toString().split(' ')[0]; // Today's date
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.week;

  @override
  void initState() {
    super.initState();
    _loadMenuData();
  }

  Future<void> _loadMenuData() async {
    try {
      print('Loading menu data for date: $currentDate');

      final menuData = await MenuService.getMenuDataForDate(currentDate);
      if (menuData != null) {
        setState(() {
          _menuData = menuData;
        });
        print('Successfully loaded menu data: ${menuData.toString()}');
      } else {
        setState(() {
          _menuData = null;
        });
        print('No menu data found for date: $currentDate');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error loading menu data. Please restart the app.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error loading menu data: $e');
      setState(() {
        _menuData = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error loading menu data. Please restart the app.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      currentDate = selectedDay.toString().split(' ')[0];
    });
    _loadMenuData(); // Reload menu data for the selected date
  }

  // Get meal data for current date and meal type
  MealData? getMealData(String mealType) {
    if (_menuData == null) return null;

    try {
      // For currently serving section, always use today's date
      final dateToUse = mealType == getCurrentMeal() ? todayDate : currentDate;
      return _menuData!.meals[mealType.toLowerCase()];
    } catch (e) {
      print('Error getting meal data: $e');
      return null;
    }
  }

  // Get current meal based on time
  String? getCurrentMeal() {
    final now = TimeOfDay.now();
    if (now.hour >= 7 && now.hour < 9) return 'Breakfast';
    if (now.hour >= 12 && now.hour < 14) return 'Lunch';
    if (now.hour >= 16 && now.hour < 18) return 'Snacks';
    if (now.hour >= 19 && now.hour < 21) return 'Dinner';
    return null;
  }

  // Get time range for a meal
  String getTimeRange(String mealType) {
    switch (mealType) {
      case 'Breakfast':
        return '7:00 AM - 9:30 AM';
      case 'Lunch':
        return '12:30 PM - 2:30 PM';
      case 'Snacks':
        return '4:30 PM - 6:00 PM';
      case 'Dinner':
        return '7:30 PM - 9:00 PM';
      default:
        return '';
    }
  }

  // Get greeting based on time of day
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  Future<void> _checkSavedMenus() async {
    final allCards = await MenuService.getFavoriteMeals();
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
    final currentMealData =
        currentMeal != null ? getMealData(currentMeal) : null;

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
                            ],
                            onSelected: (String value) async {
                              if (value == 'reset') {
                                // Clear Hive storage
                                await MenuService.clear();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Storage cleared. Restart app to reload from JSON.'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } else if (value == 'view_menu_data') {
                                await _checkSavedMenus();
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
                              _buildHostelAvatar(),
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
                      if (currentMeal != null && currentMealData != null)
                        MealTimeCard(
                          title: currentMealData.title,
                          time: currentMealData.time,
                          food: currentMealData.food,
                          beverages: currentMealData.beverages,
                          imagePath: currentMealData.imagePath,
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

                      // Display selected date with calendar icon
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Menu for ${currentDate}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.calendar_today,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: () => _showCalendarDialog(context),
                            ),
                          ],
                        ),
                      ),

                      // Selected Date's Menu Cards
                      if (_menuData != null)
                        ..._menuData!.meals.entries.map((entry) {
                          final mealType = entry.key;
                          final mealData = entry.value;
                          return MealTimeCard(
                            title: mealData.title,
                            time: mealData.time,
                            food: mealData.food,
                            beverages: mealData.beverages,
                            imagePath: mealData.imagePath,
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
    DateTime selectedDay = DateTime.parse(currentDate);
    DateTime focusedDay = DateTime.parse(currentDate);

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
                focusedDay: focusedDay,
                selectedDayPredicate: (day) {
                  return isSameDay(selectedDay, day);
                },
                onDaySelected: (newSelectedDay, newFocusedDay) {
                  selectedDay = newSelectedDay;
                  focusedDay = newFocusedDay;
                  final formattedDate =
                      "${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}";

                  setState(() {
                    currentDate = formattedDate;
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });

                  _loadMenuData(); // Reload menu data for the selected date
                  Navigator.pop(context); // Close the dialog
                },
                calendarFormat: _calendarFormat,
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (newFocusedDay) {
                  focusedDay = newFocusedDay;
                },
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

  Widget _buildHostelAvatar() {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedHostel =
              selectedHostel == 'Mens Hostel' ? 'Ladies Hostel' : 'Mens Hostel';
        });
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.yellow,
            width: 2,
          ),
        ),
        child: Image.asset(
          selectedHostel == 'Mens Hostel'
              ? 'assets/mens_hostel.png'
              : 'assets/ladies_hostel.png',
          width: 40,
          height: 40,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
