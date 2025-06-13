import 'package:hive/hive.dart';

part 'menu_card.g.dart';

@HiveType(typeId: 0)
class MenuCard extends HiveObject {
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
  final bool isFavorite;

  MenuCard({
    required this.title,
    required this.time,
    required this.food,
    required this.beverages,
    required this.imagePath,
    this.isFavorite = false,
  });

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'time': time,
      'food': food,
      'beverages': beverages,
      'imagePath': imagePath,
      'isFavorite': isFavorite,
    };
  }

  // Create from Map
  factory MenuCard.fromMap(Map<String, dynamic> map) {
    return MenuCard(
      title: map['title'] as String,
      time: map['time'] as String,
      food: map['food'] as String,
      beverages: map['beverages'] as String,
      imagePath: map['imagePath'] as String,
      isFavorite: map['isFavorite'] as bool,
    );
  }
}
