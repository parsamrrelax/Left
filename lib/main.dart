import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Left/homepage.dart';
import 'package:Left/models/user_data.dart';
import 'package:Left/screens/setup_screen.dart';
import 'package:home_widget/home_widget.dart';
import 'package:Left/services/widget_service.dart';

// Background callback executed in a headless isolate when native Android updates the widget
@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  debugPrint('Left BackgroundCallback triggered with URI: $uri');
  WidgetsFlutterBinding.ensureInitialized();
  if (uri?.host == 'updateWidget') {
    final widgetIdString = uri?.queryParameters['widgetId'];
    final widgetId = int.tryParse(widgetIdString ?? '');
    debugPrint('Left BackgroundCallback: parsed widgetId: $widgetId');
    if (widgetId != null) {
      try {
        final userData = await WidgetService.loadWidgetUserData();
        debugPrint('Left BackgroundCallback: Loaded UserData.');
        final screenId = await HomeWidget.getWidgetData<String>('widget_screen_$widgetId') ?? 'year';
        debugPrint('Left BackgroundCallback: screenId: $screenId');
        final useAmoledTheme = userData.useAmoledTheme ?? false;

        // In the background, construct a matching dark/AMOLED theme as there is no active UI context
        final colorScheme = ColorScheme.dark(
          surface: useAmoledTheme ? Colors.black : const Color(0xFF121212),
          primary: Colors.white,
          onSurface: Colors.white,
        );

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final uniqueKey = 'widget_image_${widgetId}_$timestamp';
        debugPrint('Left BackgroundCallback: Rendering widget off-screen to $uniqueKey...');

        // Render the widget image off-screen to a unique filename
        final path = await HomeWidget.renderFlutterWidget(
          WidgetRenderView(
            screenId: screenId,
            userData: userData,
            colorScheme: colorScheme,
          ),
          key: uniqueKey,
          logicalSize: const Size(320, 320),
        );
        debugPrint('Left BackgroundCallback: Rendered path: $path');

        if (path != null) {
          // Save the actual image path under a constant key for the native side
          await HomeWidget.saveWidgetData('widget_image_path_$widgetId', path);
          debugPrint('Left BackgroundCallback: Saved path to widget_image_path_$widgetId');
        }

        // Notify the native widget provider to reload
        debugPrint('Left BackgroundCallback: Invoking HomeWidget.updateWidget...');
        await HomeWidget.updateWidget(
          name: 'LeftWidgetProvider',
          androidName: 'LeftWidgetProvider',
        );
        debugPrint('Left BackgroundCallback: Completed successfully.');
      } catch (e, stackTrace) {
        debugPrint('Left BackgroundCallback ERROR: $e');
        debugPrint('Left BackgroundCallback StackTrace: $stackTrace');
      }
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(UserDataAdapter());
  Hive.registerAdapter(ImportantDateAdapter());

  final box = await Hive.openBox<UserData>('userData');
  final hasCompletedSetup = box.get('user') != null;

  // Register the background update callback
  HomeWidget.registerInteractivityCallback(backgroundCallback);

  runApp(MainApp(hasCompletedSetup: hasCompletedSetup));
}

class MainApp extends StatelessWidget {
  final bool hasCompletedSetup;

  const MainApp({
    super.key,
    required this.hasCompletedSetup,
  });

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    return ValueListenableBuilder<Box<UserData>>(
      valueListenable: Hive.box<UserData>('userData').listenable(),
      builder: (context, box, _) {
        final userData = box.get('user');
        final useDynamicTheme = userData?.useDynamicTheme ?? false;
        final useAmoledTheme = userData?.useAmoledTheme ?? false;
        final fontFamily = userData?.fontFamily ?? 'System';

        return DynamicColorBuilder(
          builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
            ColorScheme colorScheme;
            if (useDynamicTheme && darkDynamic != null) {
              if (useAmoledTheme) {
                colorScheme = darkDynamic.copyWith(
                  surface: Colors.black,
                );
              } else {
                colorScheme = darkDynamic;
              }
            } else {
              colorScheme = const ColorScheme.dark(
                surface: Colors.black,
                primary: Colors.white,
              );
            }

            String? resolvedFontFamily;
            if (fontFamily != 'System') {
              try {
                resolvedFontFamily = GoogleFonts.getFont(fontFamily).fontFamily;
              } catch (_) {
                resolvedFontFamily = null;
              }
            }

            return MaterialApp(
              debugShowCheckedModeBanner: false,
              home: hasCompletedSetup ? const HomePage() : const SetupScreen(),
              theme: ThemeData(
                colorScheme: colorScheme,
                useMaterial3: true,
                fontFamily: resolvedFontFamily,
              ),
            );
          },
        );
      },
    );
  }
}
