import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:Left/models/user_data.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Box<UserData> userDataBox;
  UserData? userData;

  @override
  void initState() {
    super.initState();
    userDataBox = Hive.box<UserData>('userData');
    userData = userDataBox.get('user');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDynamic = userData?.useDynamicTheme ?? false;

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
              }
            },
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
