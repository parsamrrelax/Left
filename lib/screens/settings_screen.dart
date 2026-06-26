import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Left/models/user_data.dart';
import 'package:Left/services/widget_service.dart';
import 'package:home_widget/home_widget.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Box<UserData> userDataBox;
  UserData? userData;
  List<int> _activeWidgetIds = [];
  Map<int, String> _widgetScreens = {};
  bool _loadingWidgets = true;

  final List<String> _fonts = [
    'System',
    'Inter',
    'Poppins',
    'JetBrains Mono',
    'Lora',
  ];

  @override
  void initState() {
    super.initState();
    userDataBox = Hive.box<UserData>('userData');
    userData = userDataBox.get('user');
    _loadWidgetsConfig();
  }

  Future<void> _loadWidgetsConfig() async {
    final ids = await WidgetService.getActiveWidgetIds();
    final Map<int, String> screens = {};
    for (final id in ids) {
      final screenId = await HomeWidget.getWidgetData<String>('widget_screen_$id') ?? 'year';
      screens[id] = screenId;
    }
    if (mounted) {
      setState(() {
        _activeWidgetIds = ids;
        _widgetScreens = screens;
        _loadingWidgets = false;
      });
    }
  }

  TextStyle _getPreviewStyle(String fontName) {
    if (fontName == 'System') {
      return const TextStyle();
    }
    try {
      return GoogleFonts.getFont(fontName);
    } catch (_) {
      return const TextStyle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDynamic = userData?.useDynamicTheme ?? false;
    final isAmoled = userData?.useAmoledTheme ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          // Dynamic Theme Preview Card
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme Preview',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildColorCircle('Primary', theme.colorScheme.primary, theme.colorScheme.onPrimary),
                      _buildColorCircle('Surface', theme.colorScheme.surface, theme.colorScheme.onSurface, border: true),
                      _buildColorCircle('Secondary', theme.colorScheme.secondary, theme.colorScheme.onSecondary),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Appearance',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Material You Dynamic Theme'),
            subtitle: const Text('Sync app colors with your system wallpaper'),
            value: isDynamic,
            onChanged: (value) async {
              if (userData != null) {
                setState(() {
                  userData!.useDynamicTheme = value;
                });
                await userDataBox.put('user', userData!);
                if (mounted) {
                  await WidgetService.updateAllWidgets(context, userData!);
                }
              }
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('AMOLED Black Background'),
            subtitle: const Text('Make the background pitch black while keeping dynamic accents'),
            value: isAmoled,
            onChanged: isDynamic
                ? (value) async {
                    if (userData != null) {
                      setState(() {
                        userData!.useAmoledTheme = value;
                      });
                      await userDataBox.put('user', userData!);
                      if (mounted) {
                        await WidgetService.updateAllWidgets(context, userData!);
                      }
                    }
                  }
                : null,
          ),
          const SizedBox(height: 24),
          Text(
            'Typography',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ..._fonts.map((font) {
            final isSelected = (userData?.fontFamily ?? 'System') == font;
            return Card(
              elevation: 0,
              color: isSelected
                  ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                  : theme.colorScheme.surfaceContainerLowest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withOpacity(0.12),
                  width: 1.5,
                ),
              ),
              child: ListTile(
                title: Text(
                  font,
                  style: _getPreviewStyle(font).copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  '123 days / 54% Left',
                  style: _getPreviewStyle(font).copyWith(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: isSelected
                    ? Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.primary,
                      )
                    : null,
                onTap: () async {
                  if (userData != null) {
                    setState(() {
                      userData!.fontFamily = font;
                    });
                    await userDataBox.put('user', userData!);
                    if (mounted) {
                      await WidgetService.updateAllWidgets(context, userData!);
                    }
                  }
                },
              ),
            );
          }),
          const SizedBox(height: 24),
          Text(
            'Home Screen Widgets',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.12),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Display any screen as a live widget on your homescreen, styled with your app theme.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final success = await WidgetService.requestPinWidget();
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Widget pinning requested')),
                        );
                        Future.delayed(const Duration(seconds: 2), () {
                          _loadWidgetsConfig();
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Pinning not supported or cancelled')),
                        );
                      }
                    },
                    icon: const Icon(Icons.add_to_home_screen),
                    label: const Text('Add Widget to Home Screen'),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_loadingWidgets)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_activeWidgetIds.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No active widgets found. Add one from your homescreen or use the button above to configure them here.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._activeWidgetIds.asMap().entries.map((entry) {
                      final index = entry.key;
                      final id = entry.value;
                      final currentScreen = _widgetScreens[id] ?? 'year';

                      final List<DropdownMenuItem<String>> dropdownItems = [
                        const DropdownMenuItem(value: 'year', child: Text('Year View')),
                        const DropdownMenuItem(value: 'month', child: Text('Month View')),
                        if (userData?.birthday != null)
                          const DropdownMenuItem(value: 'birthday', child: Text('Birthday View')),
                        const DropdownMenuItem(value: 'life_months', child: Text('Life View (Months)')),
                        const DropdownMenuItem(value: 'life_years', child: Text('Life View (Years)')),
                        ...(userData?.importantDates ?? []).map((date) {
                          return DropdownMenuItem(
                            value: 'custom_${date.title}',
                            child: Text(date.title),
                          );
                        }),
                      ];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.outline.withOpacity(0.08),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Widget #${index + 1}',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'ID: $id',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: dropdownItems.any((item) => item.value == currentScreen)
                                    ? currentScreen
                                    : 'year',
                                decoration: InputDecoration(
                                  labelText: 'Show Screen',
                                  labelStyle: TextStyle(color: theme.colorScheme.primary),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: theme.colorScheme.primary),
                                  ),
                                ),
                                items: dropdownItems,
                                onChanged: (val) async {
                                  if (val != null && userData != null) {
                                    setState(() {
                                      _widgetScreens[id] = val;
                                    });
                                    await WidgetService.renderAndUpdateWidget(
                                      colorScheme: Theme.of(context).colorScheme,
                                      widgetId: id,
                                      screenId: val,
                                      userData: userData!,
                                    );
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Widget updated'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorCircle(String label, Color color, Color textColor, {bool border = false}) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: border ? Border.all(color: Colors.grey.withOpacity(0.5)) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.palette,
              color: textColor,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
