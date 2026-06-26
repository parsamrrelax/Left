import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Left/models/user_data.dart';
import 'package:Left/services/days.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:Left/UI/dot_pattern.dart';
import 'dart:convert';

class WidgetService {
  static const MethodChannel _channel = MethodChannel('com.mirarrapp.left/widget');

  // Fetch active widget IDs from Android
  static Future<List<int>> getActiveWidgetIds() async {
    try {
      final List<dynamic>? ids = await _channel.invokeMethod('getActiveWidgetIds');
      return ids?.cast<int>() ?? [];
    } catch (e) {
      debugPrint('Error getting active widget IDs: $e');
      return [];
    }
  }

  // Request the system to pin a widget (Android 8.0+)
  static Future<bool> requestPinWidget() async {
    try {
      final bool? success = await _channel.invokeMethod('requestPinWidget');
      return success ?? false;
    } catch (e) {
      debugPrint('Error requesting pin widget: $e');
      return false;
    }
  }

  // Notify the native side to reload a specific widget ID
  static Future<void> updateWidgetNative(int widgetId) async {
    try {
      await _channel.invokeMethod('updateWidget', {'widgetId': widgetId});
    } catch (e) {
      debugPrint('Error calling updateWidget native: $e');
    }
  }

  // Render a screen and update the home screen widget
  static Future<void> renderAndUpdateWidget({
    required ColorScheme colorScheme,
    required int widgetId,
    required String screenId,
    required UserData userData,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uniqueKey = 'widget_image_${widgetId}_$timestamp';

    // Render the Flutter widget off-screen to a unique PNG image
    final path = await HomeWidget.renderFlutterWidget(
      WidgetRenderView(
        screenId: screenId,
        userData: userData,
        colorScheme: colorScheme,
      ),
      key: uniqueKey,
      logicalSize: const Size(320, 320),
    );

    // Save the actual image path under a constant key for the native side
    await HomeWidget.saveWidgetData('widget_image_path_$widgetId', path);
    // Save the widget configuration in SharedPreferences
    await HomeWidget.saveWidgetData('widget_screen_$widgetId', screenId);

    // Notify Android to reload the widget with this ID
    await updateWidgetNative(widgetId);
  }

  // Sync Hive UserData to SharedPreferences for background isolate access
  static Future<void> saveWidgetData(UserData userData) async {
    await HomeWidget.saveWidgetData('useAmoledTheme', userData.useAmoledTheme ?? false);
    await HomeWidget.saveWidgetData('fontFamily', userData.fontFamily ?? 'System');
    await HomeWidget.saveWidgetData('birthday', userData.birthday?.toIso8601String());
    await HomeWidget.saveWidgetData('expectedLifespan', userData.expectedLifespan ?? 80);
    
    // Save important dates as a JSON string
    final datesJson = userData.importantDates.map((d) => {
      'title': d.title,
      'date': d.date.toIso8601String(),
    }).toList();
    await HomeWidget.saveWidgetData('importantDates', jsonEncode(datesJson));
  }

  // Load UserData from SharedPreferences (used in background isolate to avoid Hive file locking)
  static Future<UserData> loadWidgetUserData() async {
    final useAmoled = await HomeWidget.getWidgetData<bool>('useAmoledTheme') ?? false;
    final fontFamily = await HomeWidget.getWidgetData<String>('fontFamily') ?? 'System';
    final birthdayStr = await HomeWidget.getWidgetData<String>('birthday');
    final lifespan = await HomeWidget.getWidgetData<int>('expectedLifespan') ?? 80;
    final datesJsonStr = await HomeWidget.getWidgetData<String>('importantDates') ?? '[]';
    
    final birthday = birthdayStr != null ? DateTime.tryParse(birthdayStr) : null;
    
    List<ImportantDate> importantDates = [];
    try {
      final List<dynamic> datesList = jsonDecode(datesJsonStr);
      importantDates = datesList.map((item) {
        return ImportantDate(
          title: item['title'] as String,
          date: DateTime.parse(item['date'] as String),
        );
      }).toList();
    } catch (_) {}

    return UserData(
      birthday: birthday,
      expectedLifespan: lifespan,
      importantDates: importantDates,
      useAmoledTheme: useAmoled,
      fontFamily: fontFamily,
    );
  }

  // Update all active widgets to ensure they have the latest data and theme
  static Future<void> updateAllWidgets(BuildContext context, UserData userData) async {
    // Sync data to SharedPreferences first for background updates
    await saveWidgetData(userData);

    final colorScheme = Theme.of(context).colorScheme;
    final ids = await getActiveWidgetIds();
    for (final id in ids) {
      final screenId = await HomeWidget.getWidgetData<String>('widget_screen_$id') ?? 'year';
      await renderAndUpdateWidget(
        colorScheme: colorScheme,
        widgetId: id,
        screenId: screenId,
        userData: userData,
      );
    }
  }

  // Get the screen ID that launched the app, if any
  static Future<String?> getInitialScreenId() async {
    try {
      final String? screenId = await _channel.invokeMethod('getInitialScreenId');
      return screenId;
    } catch (e) {
      debugPrint('Error getting initial screen ID: $e');
      return null;
    }
  }

  // Register a listener for when a widget is clicked and the app is resumed
  static void setScreenSelectionListener(Function(String) onScreenSelected) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onScreenSelected') {
        final String? screenId = call.arguments as String?;
        if (screenId != null) {
          onScreenSelected(screenId);
        }
      }
    });
  }
}

class WidgetRenderView extends StatelessWidget {
  final String screenId;
  final UserData userData;
  final ColorScheme colorScheme;

  const WidgetRenderView({
    super.key,
    required this.screenId,
    required this.userData,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final fontFamily = userData.fontFamily ?? 'System';
    String? resolvedFontFamily;
    if (fontFamily != 'System') {
      try {
        resolvedFontFamily = GoogleFonts.getFont(fontFamily).fontFamily;
      } catch (_) {}
    }

    final textStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: colorScheme.onSurface.withOpacity(0.4),
      fontFamily: resolvedFontFamily,
      decoration: TextDecoration.none, // Ensure no yellow underline when rendering off-screen
    );

    Widget? dotPattern;
    String text = '';

    if (screenId == 'year') {
      final daysUntilNextYear = getDaysUntilNextYear();
      final daysPassed = dateDifference(now, DateTime(now.year, 1, 1));
      final days = isLeapYear(now.year) ? 366 : 365;
      final daysLeft = days - daysPassed;
      final percentLeft = (daysLeft / days) * 100;
      final currentYear = DateFormat('yyyy').format(now);

      dotPattern = DotPattern(
        days: days,
        startDay: daysPassed,
        isWidget: true,
      );
      text = '$currentYear: $daysUntilNextYear days / ${percentLeft.round()}% Left';
    } else if (screenId == 'month') {
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final dayOfMonth = now.day;
      final percentLeft = (daysInMonth - dayOfMonth) / daysInMonth * 100;
      final currentMonthName = DateFormat('MMMM').format(now);

      dotPattern = DotPattern(
        days: daysInMonth,
        startDay: dayOfMonth,
        isWidget: true,
      );
      text = 'Day $dayOfMonth of $currentMonthName / ${percentLeft.round()}% Left';
    } else if (screenId == 'birthday' && userData.birthday != null) {
      final nextBirthday = DateTime(
        now.year +
            (now.month > userData.birthday!.month ||
                    (now.month == userData.birthday!.month &&
                        now.day >= userData.birthday!.day)
                ? 1
                : 0),
        userData.birthday!.month,
        userData.birthday!.day,
      );
      final daysUntilBirthday = nextBirthday.difference(now).inDays;

      dotPattern = DotPattern(
        days: 365,
        startDay: 365 - daysUntilBirthday,
        isWidget: true,
      );
      text = '${userData.birthday!.day}/${userData.birthday!.month}: $daysUntilBirthday days Left';
    } else if (screenId == 'life_months') {
      final age = userData.birthday != null
          ? ((now.difference(userData.birthday!).inDays) / 365).floor()
          : 24;
      final lifespan = userData.expectedLifespan ?? 80;
      final currentAgeMonths = age * 12;
      final expectedLifespanMonths = lifespan * 12;
      final monthsLeft = expectedLifespanMonths - currentAgeMonths;

      dotPattern = DotPattern(
        days: expectedLifespanMonths,
        startDay: currentAgeMonths,
        isYearView: false,
        isMonthView: true,
        isWidget: true,
      );
      text = 'life: $monthsLeft months Left';
    } else if (screenId == 'life_years') {
      final age = userData.birthday != null
          ? ((now.difference(userData.birthday!).inDays) / 365).floor()
          : 24;
      final lifespan = userData.expectedLifespan ?? 80;
      final yearsLeft = lifespan - age;

      dotPattern = DotPattern(
        days: lifespan,
        startDay: age,
        isYearView: true,
        isWidget: true,
      );
      text = 'life: $yearsLeft years Left';
    } else if (screenId.startsWith('custom_')) {
      final title = screenId.substring(7);
      final importantDate = userData.importantDates.firstWhere(
        (d) => d.title == title,
        orElse: () => ImportantDate(title: title, date: now),
      );
      final nextOccurrence = DateTime(
        now.year +
            (now.month > importantDate.date.month ||
                    (now.month == importantDate.date.month &&
                        now.day >= importantDate.date.day)
                ? 1
                : 0),
        importantDate.date.month,
        importantDate.date.day,
      );
      final daysUntil = nextOccurrence.difference(now).inDays;

      dotPattern = DotPattern(
        days: 365,
        startDay: 365 - daysUntil,
        isWidget: true,
      );
      text = '${importantDate.title}: $daysUntil Left';
    }

    if (dotPattern == null) {
      return const SizedBox.shrink();
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Theme(
        data: ThemeData(
          colorScheme: colorScheme,
          useMaterial3: true,
          fontFamily: resolvedFontFamily,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            width: 320,
            height: 320,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: 320,
                        height: 240,
                        child: dotPattern,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  text,
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
