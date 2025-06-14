import 'package:hive/hive.dart';

part 'menu_data.g.dart';

@HiveType(typeId: 1)
class MenuData {
  @HiveField(0)
  final String date;

  @HiveField(1)
  final Map<String, MealData> meals;

  MenuData({
    required this.date,
    required this.meals,
  });

  factory MenuData.fromJson(String date, Map<String, dynamic> json) {
    Map<String, MealData> meals = {};
    json.forEach((key, value) {
      meals[key] = MealData.fromJson(value);
    });
    return MenuData(date: date, meals: meals);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> mealsJson = {};
    meals.forEach((key, value) {
      mealsJson[key] = value.toJson();
    });
    return mealsJson;
  }
}

@HiveType(typeId: 2)
class MealData {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final String time;

  @HiveField(2)
  final String food;

  @HiveField(3)
  final String beverages;

  @HiveField(4)
  final String imagePath;

  @HiveField(5)
  bool isFavorite;

  MealData({
    required this.title,
    required this.time,
    required this.food,
    required this.beverages,
    required this.imagePath,
    this.isFavorite = false,
  });

  factory MealData.fromJson(Map<String, dynamic> json) {
    return MealData(
      title: json['title'] as String,
      time: json['time'] as String,
      food: json['food'] as String,
      beverages: json['beverages'] as String,
      imagePath: json['imagePath'] as String,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'time': time,
      'food': food,
      'beverages': beverages,
      'imagePath': imagePath,
      'isFavorite': isFavorite,
    };
  }
}
