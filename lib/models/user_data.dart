import 'package:hive/hive.dart';

part 'user_data.g.dart';

@HiveType(typeId: 0)
class UserData extends HiveObject {
  @HiveField(0)
  DateTime? birthday;

  @HiveField(1)
  int? expectedLifespan;

  @HiveField(2)
  List<ImportantDate> importantDates;

  @HiveField(3)
  List<String>? hiddenScreens;

  @HiveField(4)
  bool? useDynamicTheme;

  UserData({
    this.birthday,
    this.expectedLifespan,
    this.importantDates = const [],
    List<String>? hiddenScreens,
    this.useDynamicTheme = false,
  }) : hiddenScreens = hiddenScreens ?? [];
}

@HiveType(typeId: 1)
class ImportantDate extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  DateTime date;

  ImportantDate({
    required this.title,
    required this.date,
  });
}
